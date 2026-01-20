#!/bin/bash
# SubagentStop Hook: Log subagent completion and summarize
# This hook runs when a subagent completes its work
# Logs are now isolated per workspace to support multi-project development

# Source workspace utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# Get agent info from environment (if available)
AGENT_NAME="${CLAUDE_AGENT_NAME:-unknown}"
AGENT_ID="${CLAUDE_AGENT_ID:-unknown}"

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

# Append to activity log with workspace context
if [ -n "$WORKSPACE_ID" ]; then
    echo "[$TIMESTAMP] [workspace:$WORKSPACE_ID] Subagent completed: $AGENT_NAME (ID: $AGENT_ID)" >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] Subagent completed: $AGENT_NAME (ID: $AGENT_ID)" >> "$LOG_FILE"
fi

# Also log to session-specific file if available
if command -v get_session_log &> /dev/null; then
    SESSION_LOG=$(get_session_log "$WORKSPACE_ID")
    echo "[$TIMESTAMP] Subagent completed: $AGENT_NAME (ID: $AGENT_ID)" >> "$SESSION_LOG"
fi

# Output summary (this will be shown in the conversation)
cat << EOF
---
**Subagent Complete:** \`$AGENT_NAME\`

Review the output above and decide:
- Accept and continue with next phase
- Request clarification or changes
- Delegate follow-up to another agent
---
EOF
