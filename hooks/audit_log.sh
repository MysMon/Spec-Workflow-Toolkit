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

# Configuration for log rotation
MAX_LOG_SIZE_BYTES=$((10 * 1024 * 1024))  # 10MB max per log file
MAX_LOG_FILES=7  # Keep 7 days of logs

# --- Log Rotation ---
# Rotate log file if it exceeds size limit
rotate_log_if_needed() {
    local log_file="$1"
    local max_size="$2"

    if [ ! -f "$log_file" ]; then
        return 0
    fi

    # Get file size (cross-platform, POSIX-compatible)
    local current_size
    case "$OSTYPE" in
        darwin*)
            current_size=$(stat -f%z "$log_file" 2>/dev/null || echo 0)
            ;;
        *)
            current_size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
            ;;
    esac

    if [ "$current_size" -gt "$max_size" ]; then
        local timestamp
        timestamp=$(date '+%H%M%S')
        local rotated_file="${log_file}.${timestamp}"

        # Rotate current log
        mv "$log_file" "$rotated_file" 2>/dev/null || return 1

        # Compress rotated file if gzip is available
        if command -v gzip &> /dev/null; then
            gzip "$rotated_file" 2>/dev/null &
        fi
    fi
}

# Clean up old audit logs (older than MAX_LOG_FILES days)
cleanup_old_logs() {
    local log_dir="$1"
    if [ -d "$log_dir" ]; then
        find "$log_dir" -name "tool-audit-*.jsonl*" -mtime +$MAX_LOG_FILES -delete 2>/dev/null || true
    fi
}

# Rotate if needed before writing
rotate_log_if_needed "$LOG_FILE" "$MAX_LOG_SIZE_BYTES"

# Periodic cleanup (only run occasionally to avoid overhead)
CLEANUP_MARKER="$LOG_DIR/.last_audit_cleanup"
if [ ! -f "$CLEANUP_MARKER" ] || [ "$(find "$CLEANUP_MARKER" -mtime +1 2>/dev/null)" ]; then
    cleanup_old_logs "$LOG_DIR"
    touch "$CLEANUP_MARKER" 2>/dev/null || true
fi

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

import re

# Patterns for secrets that might appear in command arguments
SECRET_PATTERNS = [
    # Provider API keys with prefixes
    (r'sk-ant-[a-zA-Z0-9_-]{20,}', '[ANTHROPIC_KEY_REDACTED]'),
    (r'sk-[a-zA-Z0-9]{20,}', '[OPENAI_KEY_REDACTED]'),
    (r'AKIA[0-9A-Z]{16}', '[AWS_ACCESS_KEY_REDACTED]'),
    (r'ghp_[a-zA-Z0-9]{36,}', '[GITHUB_TOKEN_REDACTED]'),
    (r'gho_[a-zA-Z0-9]{36,}', '[GITHUB_OAUTH_REDACTED]'),
    (r'glpat-[a-zA-Z0-9_-]{20,}', '[GITLAB_TOKEN_REDACTED]'),
    (r'xox[baprs]-[a-zA-Z0-9-]{10,}', '[SLACK_TOKEN_REDACTED]'),
    # Bearer/Authorization tokens
    (r'Bearer\s+[a-zA-Z0-9._-]{20,}', 'Bearer [TOKEN_REDACTED]'),
    (r'Authorization:\s*[^\s]{20,}', 'Authorization: [REDACTED]'),
    # Generic patterns for passwords/secrets in arguments
    (r'(-[pP]|--password[=\s])[^\s]{8,}', r'\g<1>[PASSWORD_REDACTED]'),
    (r'(ANTHROPIC_API_KEY|OPENAI_API_KEY|AWS_SECRET_ACCESS_KEY|GITHUB_TOKEN)=[^\s]{10,}', r'\g<1>=[REDACTED]'),
    # Database connection strings with passwords
    (r'(postgres|mysql|mongodb)://[^:]+:[^@]{8,}@', r'\g<1>://[USER]:[PASSWORD_REDACTED]@'),
    # Generic high-entropy strings that look like secrets (64+ hex chars)
    (r'["\'][a-fA-F0-9]{64,}["\']', '"[POSSIBLE_SECRET_REDACTED]"'),
]

def redact_secrets_in_string(text):
    '''Redact known secret patterns from a string'''
    if not isinstance(text, str):
        return text
    result = text
    for pattern, replacement in SECRET_PATTERNS:
        result = re.sub(pattern, replacement, result)
    return result

def truncate_input(data, max_len=200):
    '''Truncate input for logging without exposing sensitive data'''
    if isinstance(data, dict):
        result = {}
        for k, v in data.items():
            # Skip potentially sensitive fields by name
            if k.lower() in ('password', 'secret', 'token', 'key', 'credential', 'api_key'):
                result[k] = '[REDACTED]'
            elif isinstance(v, str):
                # First redact secrets in string content
                redacted = redact_secrets_in_string(v)
                # Then truncate if needed
                if len(redacted) > max_len:
                    result[k] = redacted[:max_len] + '...[truncated]'
                else:
                    result[k] = redacted
            else:
                result[k] = v
        return result
    elif isinstance(data, str):
        return redact_secrets_in_string(data)
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
