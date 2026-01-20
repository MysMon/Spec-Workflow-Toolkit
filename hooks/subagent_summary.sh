#!/bin/bash
# SubagentStop Hook: Log subagent completion and summarize
# This hook runs when a subagent completes its work
# Logs are now isolated per workspace to support multi-project development

# Source workspace utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# Read hook input (may contain agent info)
INPUT=$(cat)

# Get agent info from environment or input
AGENT_NAME="${CLAUDE_AGENT_NAME:-unknown}"
AGENT_ID="${CLAUDE_AGENT_ID:-unknown}"
AGENT_STATUS="${CLAUDE_AGENT_STATUS:-completed}"

# Try to extract additional info from JSON input if available
if command -v python3 &> /dev/null && [ -n "$INPUT" ]; then
    EXTRACTED=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    name = d.get('agent_name', '')
    aid = d.get('agent_id', '')
    status = d.get('status', '')
    duration = d.get('duration_ms', '')
    print(f'{name}|{aid}|{status}|{duration}')
except:
    print('|||')
" 2>/dev/null)

    IFS='|' read -r EXT_NAME EXT_ID EXT_STATUS EXT_DURATION <<< "$EXTRACTED"
    [ -n "$EXT_NAME" ] && AGENT_NAME="$EXT_NAME"
    [ -n "$EXT_ID" ] && AGENT_ID="$EXT_ID"
    [ -n "$EXT_STATUS" ] && AGENT_STATUS="$EXT_STATUS"
    AGENT_DURATION="${EXT_DURATION:-}"
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
LOG_ENTRY="[$TIMESTAMP] Agent: $AGENT_NAME | Status: $AGENT_STATUS | ID: $AGENT_ID"
[ -n "$AGENT_DURATION" ] && LOG_ENTRY="$LOG_ENTRY | Duration: ${AGENT_DURATION}ms"
[ -n "$WORKSPACE_ID" ] && LOG_ENTRY="$LOG_ENTRY | Workspace: $WORKSPACE_ID"

# Append to activity log
echo "$LOG_ENTRY" >> "$LOG_FILE"

# Also log to session-specific file if available
if command -v get_session_log &> /dev/null; then
    SESSION_LOG=$(get_session_log "$WORKSPACE_ID")
    echo "$LOG_ENTRY" >> "$SESSION_LOG"
fi

# Output summary (this will be shown in the conversation)
cat << EOF
---
**Subagent Complete:** \`$AGENT_NAME\` (Status: $AGENT_STATUS)

Review the output above and decide:
- Accept and continue with next phase
- Request clarification or changes
- Delegate follow-up to another agent
---
EOF
