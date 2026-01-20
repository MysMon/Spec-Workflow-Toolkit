#!/bin/bash
# PostToolUse Hook: Audit logging for tool usage tracking
# This hook logs tool invocations for debugging, compliance, and session analysis
#
# Based on:
# - https://www.anthropic.com/engineering/claude-code-best-practices
# - https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
#
# PostToolUse hooks receive JSON on stdin with:
# - tool_name: Name of the tool that was executed
# - tool_input: Parameters passed to the tool
# - tool_response: Result from the tool (may be truncated)
# - session_id: Current session identifier
#
# Output: Optional JSON to modify session state

set -euo pipefail

# Source workspace utilities for path resolution
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# Determine log directory
LOG_DIR=""
WORKSPACE_ID=""

if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id 2>/dev/null || echo "")
fi

if [ -n "$WORKSPACE_ID" ]; then
    LOG_DIR=".claude/workspaces/$WORKSPACE_ID/logs"
else
    LOG_DIR=".claude/logs"
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Log file with date rotation
LOG_FILE="$LOG_DIR/tool-audit-$(date +%Y-%m-%d).jsonl"

# Read input from stdin
INPUT=$(cat)

# Skip logging if input is empty
if [ -z "$INPUT" ]; then
    exit 0
fi

# Extract tool information using Python for reliable JSON parsing
# Use environment variable to safely pass input
if command -v python3 &> /dev/null; then
    AUDIT_INPUT="$INPUT" python3 -c "
import json
import os
import sys
from datetime import datetime

def truncate_input(data, max_len=200):
    '''Truncate input for logging without exposing sensitive data'''
    if isinstance(data, dict):
        result = {}
        for k, v in data.items():
            # Skip potentially sensitive fields
            if k.lower() in ('password', 'secret', 'token', 'key', 'credential', 'api_key'):
                result[k] = '[REDACTED]'
            elif isinstance(v, str) and len(v) > max_len:
                result[k] = v[:max_len] + '...[truncated]'
            else:
                result[k] = v
        return result
    return data

try:
    input_data = os.environ.get('AUDIT_INPUT', '')
    if not input_data:
        sys.exit(0)

    data = json.loads(input_data)

    tool_name = data.get('tool_name', 'unknown')
    tool_input = data.get('tool_input', {})
    session_id = data.get('session_id', 'unknown')

    # Create audit entry (exclude tool_response to save space)
    audit_entry = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'session_id': session_id,
        'tool_name': tool_name,
        'tool_input_summary': truncate_input(tool_input)
    }

    print(json.dumps(audit_entry))

except json.JSONDecodeError:
    # Invalid JSON input - skip logging, don't fail
    sys.exit(0)
except Exception as e:
    # Any other error - skip logging, don't fail
    sys.exit(0)
" 2>/dev/null >> "$LOG_FILE" || true
fi

# Always exit successfully - audit logging should never block tool execution
exit 0
