#!/bin/bash
# SubagentStop Hook: Log subagent completion and summarize
# This hook runs when a subagent completes its work
# Logs are now isolated per workspace to support multi-project development
#
# SubagentStop hook input format (from Claude Code):
#   {
#     "session_id": "...",
#     "transcript_path": "~/.claude/projects/.../xxx.jsonl",
#     "permission_mode": "default",
#     "hook_event_name": "SubagentStop",
#     "stop_hook_active": true/false
#   }

# Source workspace utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# Read hook input (JSON metadata)
INPUT=$(cat)

# Get agent info from environment variables (set by Claude Code)
AGENT_NAME="${CLAUDE_AGENT_NAME:-unknown}"
AGENT_ID="${CLAUDE_AGENT_ID:-}"
AGENT_STATUS="completed"
SESSION_ID=""
TRANSCRIPT_PATH=""

# Parse metadata JSON to get session info
if command -v python3 &> /dev/null && [ -n "$INPUT" ]; then
    HOOK_INPUT_VAR="$INPUT" \
    PARSED=$(python3 << 'PYEOF'
import json
import os
import sys

hook_input = os.environ.get('HOOK_INPUT_VAR', '')
if not hook_input:
    print('|||')
    sys.exit(0)

try:
    metadata = json.loads(hook_input)
    session_id = metadata.get('session_id', '')
    transcript_path = metadata.get('transcript_path', '')
    stop_hook_active = 'true' if metadata.get('stop_hook_active', False) else 'false'
    print(f'{session_id}|{transcript_path}|{stop_hook_active}')
except json.JSONDecodeError:
    print('|||')
except Exception:
    print('|||')
PYEOF
)

    IFS='|' read -r SESSION_ID TRANSCRIPT_PATH STOP_HOOK_ACTIVE <<< "$PARSED"
fi

# Determine log directory (workspace-isolated or fallback)
LOG_DIR=""
LOG_FILE=""

if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)
    LOG_DIR=$(get_logs_dir "$WORKSPACE_ID")
    LOG_FILE=$(get_subagent_log "$WORKSPACE_ID")

    # Ensure workspace directory structure exists
    ensure_workspace_exists "$WORKSPACE_ID"
else
    # Fallback to plugin-level logs (legacy behavior)
    LOG_DIR="${CLAUDE_PLUGIN_ROOT:-.}/logs"
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/subagent_activity.log"
fi

# Log completion timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Build detailed log entry
LOG_ENTRY="[$TIMESTAMP] Agent: $AGENT_NAME | Status: $AGENT_STATUS"
[ -n "$AGENT_ID" ] && LOG_ENTRY="$LOG_ENTRY | ID: $AGENT_ID"
[ -n "$SESSION_ID" ] && LOG_ENTRY="$LOG_ENTRY | Session: $SESSION_ID"
[ -n "$WORKSPACE_ID" ] && LOG_ENTRY="$LOG_ENTRY | Workspace: $WORKSPACE_ID"

# Append to activity log
echo "$LOG_ENTRY" >> "$LOG_FILE"

# Also log to session-specific file if available
if command -v get_session_log &> /dev/null; then
    SESSION_LOG=$(get_session_log "$WORKSPACE_ID")
    echo "$LOG_ENTRY" >> "$SESSION_LOG"
fi

# Output summary via JSON systemMessage (stdout is not shown to users for SubagentStop)
# Build summary message
SUMMARY="---
**Subagent Complete:** \`$AGENT_NAME\` (Status: $AGENT_STATUS)

Review the output above and decide:
- Accept and continue with next phase
- Request clarification or changes
- Delegate follow-up to another agent
---"

# Output as JSON with systemMessage (will be shown to user)
python3 -c "import json; print(json.dumps({'systemMessage': '''$SUMMARY'''}))" 2>/dev/null || \
    echo '{"systemMessage": "Subagent completed: '"$AGENT_NAME"'"}'

exit 0
