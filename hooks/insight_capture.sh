#!/bin/bash
# Insight Capture Hook: Extract and store insights from subagent output
# Runs on SubagentStop to capture marked insights
#
# Insight Markers (case-insensitive):
#   INSIGHT: <text>      - General learning or discovery
#   LEARNED: <text>      - Something learned from experience
#   DECISION: <text>     - Important decision made
#   PATTERN: <text>      - Reusable pattern discovered
#   ANTIPATTERN: <text>  - Pattern to avoid
#
# Only content with explicit markers is captured to avoid noise.

set -euo pipefail

# Source workspace utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
else
    echo '{"continue": true}'
    exit 0
fi

# Read hook input (contains subagent output)
INPUT=$(cat)

# Early exit if no input
if [ -z "$INPUT" ]; then
    echo '{"continue": true}'
    exit 0
fi

# Get workspace-specific paths
WORKSPACE_ID=$(get_workspace_id)
INSIGHTS_DIR=".claude/workspaces/$WORKSPACE_ID/insights"
PENDING_FILE="$INSIGHTS_DIR/pending.json"

# Ensure directory exists
mkdir -p "$INSIGHTS_DIR"

# Initialize pending.json if it doesn't exist
if [ ! -f "$PENDING_FILE" ]; then
    cat > "$PENDING_FILE" << EOF
{
  "workspaceId": "$WORKSPACE_ID",
  "created": "$(date -Iseconds)",
  "insights": []
}
EOF
fi

# Extract insights using Python (handles regex and JSON safely)
# Uses environment variables to pass data safely
WORKSPACE_ID_VAR="$WORKSPACE_ID" \
PENDING_FILE_VAR="$PENDING_FILE" \
AGENT_NAME_VAR="${CLAUDE_AGENT_NAME:-unknown}" \
python3 << 'PYEOF'
import json
import sys
import re
import os
from datetime import datetime

# Get data from environment (safe from injection)
input_data = sys.stdin.read()
pending_file = os.environ.get('PENDING_FILE_VAR', '')
workspace_id = os.environ.get('WORKSPACE_ID_VAR', '')
agent_name = os.environ.get('AGENT_NAME_VAR', 'unknown')

if not pending_file or not input_data:
    print(json.dumps({"continue": True}))
    sys.exit(0)

# Insight marker patterns (case-insensitive)
# Only explicit markers are captured to avoid noise
patterns = {
    'insight': r'(?:^|\n)\s*INSIGHT:\s*(.+?)(?=\n|$)',
    'learned': r'(?:^|\n)\s*LEARNED:\s*(.+?)(?=\n|$)',
    'decision': r'(?:^|\n)\s*DECISION:\s*(.+?)(?=\n|$)',
    'pattern': r'(?:^|\n)\s*PATTERN:\s*(.+?)(?=\n|$)',
    'antipattern': r'(?:^|\n)\s*ANTIPATTERN:\s*(.+?)(?=\n|$)',
}

new_insights = []
timestamp = datetime.now().isoformat()

for category, pattern in patterns.items():
    matches = re.findall(pattern, input_data, re.IGNORECASE | re.MULTILINE)
    for match in matches:
        content = match.strip()
        if content and len(content) > 10:  # Skip very short matches
            new_insights.append({
                "id": f"INS-{datetime.now().strftime('%Y%m%d%H%M%S%f')[:17]}",
                "timestamp": timestamp,
                "category": category,
                "content": content,
                "source": agent_name,
                "status": "pending"
            })

# Only update file if we found insights
if new_insights:
    try:
        with open(pending_file, 'r') as f:
            data = json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        data = {
            "workspaceId": workspace_id,
            "created": timestamp,
            "insights": []
        }

    # Add new insights
    data['insights'].extend(new_insights)
    data['lastUpdated'] = timestamp

    # Write back
    with open(pending_file, 'w') as f:
        json.dump(data, f, indent=2)

    # Output notification (shown in conversation)
    count = len(new_insights)
    print(json.dumps({
        "continue": True,
        "systemMessage": f"Captured {count} insight(s). Run /review-insights to evaluate."
    }))
else:
    print(json.dumps({"continue": True}))

PYEOF << "$INPUT"

exit 0
