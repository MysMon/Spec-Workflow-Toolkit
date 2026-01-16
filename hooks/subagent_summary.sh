#!/bin/bash
# SubagentStop Hook: Log subagent completion and summarize
# This hook runs when a subagent completes its work

# Get agent info from environment (if available)
AGENT_NAME="${CLAUDE_AGENT_NAME:-unknown}"
AGENT_ID="${CLAUDE_AGENT_ID:-unknown}"

# Create logs directory if it doesn't exist
LOG_DIR="${CLAUDE_PLUGIN_ROOT:-.}/logs"
mkdir -p "$LOG_DIR"

# Log completion timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="$LOG_DIR/subagent_activity.log"

# Append to activity log
echo "[$TIMESTAMP] Subagent completed: $AGENT_NAME (ID: $AGENT_ID)" >> "$LOG_FILE"

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
