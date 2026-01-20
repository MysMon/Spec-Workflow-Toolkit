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

# Determine progress file location (workspace-isolated or legacy)
PROGRESS_FILE=""
WORKSPACE_ID=""

if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)
    WORKSPACE_PROGRESS=$(get_progress_file "$WORKSPACE_ID")

    if [ -f "$WORKSPACE_PROGRESS" ]; then
        PROGRESS_FILE="$WORKSPACE_PROGRESS"
    fi
fi

# Fall back to legacy locations if workspace file not found
if [ -z "$PROGRESS_FILE" ]; then
    if [ -f ".claude/claude-progress.json" ]; then
        PROGRESS_FILE=".claude/claude-progress.json"
    elif [ -f "claude-progress.json" ]; then
        PROGRESS_FILE="claude-progress.json"
    fi
fi

# If progress file exists, add compaction timestamp
if [ -n "$PROGRESS_FILE" ] && command -v python3 &> /dev/null; then
    python3 << PYEOF
import json
import sys
from datetime import datetime

try:
    with open("$PROGRESS_FILE", "r") as f:
        data = json.load(f)

    # Add compaction event to history
    if "compactionHistory" not in data:
        data["compactionHistory"] = []

    data["compactionHistory"].append({
        "timestamp": datetime.now().isoformat(),
        "trigger": "$TRIGGER",
        "customInstructions": "$CUSTOM" if "$CUSTOM" else None,
        "workspaceId": "$WORKSPACE_ID" if "$WORKSPACE_ID" else None
    })

    # Keep only last 10 compaction events
    data["compactionHistory"] = data["compactionHistory"][-10:]

    # Update last compaction timestamp
    data["lastCompaction"] = datetime.now().isoformat()

    with open("$PROGRESS_FILE", "w") as f:
        json.dump(data, f, indent=2)

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
