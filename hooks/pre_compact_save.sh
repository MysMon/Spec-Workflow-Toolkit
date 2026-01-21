#!/bin/bash
# PreCompact Hook: Save critical context before compaction
# This hook ensures progress state is preserved before context is compacted
# Now supports workspace-isolated progress files
# Based on:
# - https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
# - https://code.claude.com/docs/en/hooks

# Source workspace utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# Read hook input
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('trigger','unknown'))" 2>/dev/null || echo "unknown")
CUSTOM=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('custom_instructions',''))" 2>/dev/null || echo "")

# Determine progress file location (workspace-isolated)
PROGRESS_FILE=""
WORKSPACE_ID=""

if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)

    # Defense-in-depth: Validate workspace ID before use
    if command -v validate_workspace_id &> /dev/null; then
        if ! validate_workspace_id "$WORKSPACE_ID"; then
            echo "Warning: Invalid workspace ID, skipping progress save" >&2
            exit 0
        fi
    fi

    WORKSPACE_PROGRESS=$(get_progress_file "$WORKSPACE_ID")

    if [ -f "$WORKSPACE_PROGRESS" ]; then
        PROGRESS_FILE="$WORKSPACE_PROGRESS"
    fi
fi

# If progress file exists, create backup and add compaction timestamp
# Use environment variables to safely pass data to Python
if [ -n "$PROGRESS_FILE" ] && command -v python3 &> /dev/null; then
    # Create backup of progress file before compaction
    BACKUP_DIR="$(dirname "$PROGRESS_FILE")/backups"
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    BACKUP_FILE="$BACKUP_DIR/progress-$(date '+%Y%m%d_%H%M%S').json"
    cp "$PROGRESS_FILE" "$BACKUP_FILE" 2>/dev/null

    # Keep only last 5 backups
    ls -t "$BACKUP_DIR"/progress-*.json 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null

    PROGRESS_FILE_PATH="$PROGRESS_FILE" \
    COMPACT_TRIGGER="$TRIGGER" \
    COMPACT_CUSTOM="$CUSTOM" \
    COMPACT_WORKSPACE_ID="$WORKSPACE_ID" \
    python3 << 'PYEOF'
import json
import os
import sys
import fcntl
import tempfile
import signal
from datetime import datetime

# Lock acquisition timeout (seconds)
LOCK_TIMEOUT = 5

class LockTimeoutError(Exception):
    """Raised when lock acquisition times out."""
    pass

def lock_timeout_handler(signum, frame):
    raise LockTimeoutError("Lock acquisition timed out")

try:
    progress_file = os.environ.get('PROGRESS_FILE_PATH', '')
    trigger = os.environ.get('COMPACT_TRIGGER', 'unknown')
    custom = os.environ.get('COMPACT_CUSTOM', '')
    workspace_id = os.environ.get('COMPACT_WORKSPACE_ID', '')

    if not progress_file:
        sys.exit(0)

    # Use file locking for safe concurrent access with timeout
    lock_file = progress_file + '.lock'
    with open(lock_file, 'w') as lf:
        # Set up timeout for lock acquisition
        old_handler = signal.signal(signal.SIGALRM, lock_timeout_handler)
        signal.alarm(LOCK_TIMEOUT)
        try:
            fcntl.flock(lf.fileno(), fcntl.LOCK_EX)
            signal.alarm(0)  # Cancel alarm on successful lock
        except LockTimeoutError:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, old_handler)
            print(f"Warning: Could not acquire lock within {LOCK_TIMEOUT}s, skipping progress update", file=sys.stderr)
            sys.exit(0)
        finally:
            signal.signal(signal.SIGALRM, old_handler)

        try:
            with open(progress_file, "r", encoding='utf-8') as f:
                data = json.load(f)

            # Add compaction event to history with more context
            if "compactionHistory" not in data:
                data["compactionHistory"] = []

            # Capture current state snapshot before compaction
            current_task = data.get("currentTask", "unknown")
            resumption_ctx = data.get("resumptionContext", {})

            data["compactionHistory"].append({
                "timestamp": datetime.now().isoformat(),
                "trigger": trigger,
                "customInstructions": custom if custom else None,
                "workspaceId": workspace_id if workspace_id else None,
                "stateSnapshot": {
                    "currentTask": current_task,
                    "position": resumption_ctx.get("position", "unknown"),
                    "nextAction": resumption_ctx.get("nextAction", "unknown")
                }
            })

            # Keep only last 10 compaction events
            data["compactionHistory"] = data["compactionHistory"][-10:]

            # Update last compaction timestamp
            data["lastCompaction"] = datetime.now().isoformat()

            # Add compaction warning to resumption context
            if "resumptionContext" not in data:
                data["resumptionContext"] = {}
            data["resumptionContext"]["lastCompactionWarning"] = (
                "Context was compacted. Subagent results and intermediate findings may have been lost. "
                "Re-read key files and re-run critical analyses if needed."
            )

            # Atomic write: write to temp file, fsync, then replace
            dir_name = os.path.dirname(progress_file)
            fd, temp_path = tempfile.mkstemp(dir=dir_name, suffix='.tmp')
            try:
                with os.fdopen(fd, 'w', encoding='utf-8') as tf:
                    json.dump(data, tf, indent=2, ensure_ascii=False)
                    tf.flush()
                    os.fsync(tf.fileno())  # Ensure data hits disk before rename
                os.replace(temp_path, progress_file)  # More portable than os.rename
            except Exception:
                if os.path.exists(temp_path):
                    os.unlink(temp_path)
                raise
        finally:
            pass  # Lock released when lf closes

except Exception as e:
    # Don't block compaction on errors
    print(f"Warning: Could not update progress file: {e}", file=sys.stderr)
PYEOF
fi

# Output context for Claude (added to compaction summary)
cat << EOF
## Pre-Compaction State Saved

**Trigger**: $TRIGGER
**Workspace ID**: ${WORKSPACE_ID:-"(not set)"}
**Progress File**: ${PROGRESS_FILE:-"(none detected)"}

Remember after compaction:
- Read progress files to restore context
- Workspace: \`.claude/workspaces/${WORKSPACE_ID}/\`
- Check \`feature-list.json\` for current task
- Continue from documented position
EOF

exit 0
