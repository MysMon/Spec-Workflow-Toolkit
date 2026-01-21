#!/bin/bash
# Insight Capture Hook: Extract and store insights from subagent output
# Runs on SubagentStop to capture marked insights
#
# SubagentStop hook input format (from Claude Code):
#   {
#     "session_id": "...",
#     "transcript_path": "~/.claude/projects/.../xxx.jsonl",
#     "permission_mode": "default",
#     "hook_event_name": "SubagentStop",
#     "stop_hook_active": true/false
#   }
#
# The actual subagent output is in the JSONL file at transcript_path.
#
# Insight Markers (case-insensitive):
#   INSIGHT: <text>      - General learning or discovery
#   LEARNED: <text>      - Something learned from experience
#   DECISION: <text>     - Important decision made
#   PATTERN: <text>      - Reusable pattern discovered
#   ANTIPATTERN: <text>  - Pattern to avoid
#
# Multiline support: Use backslash continuation or indent continuation lines.
#   INSIGHT: This is a multiline insight \
#   that continues on the next line.
#
#   PATTERN: First line
#     Continuation with indent (2+ spaces)
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

# Read hook input (JSON metadata, NOT subagent output)
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

# Initialize pending.json if it doesn't exist (using Python for safe JSON creation)
if [ ! -f "$PENDING_FILE" ]; then
    WORKSPACE_ID_VAR="$WORKSPACE_ID" \
    PENDING_FILE_VAR="$PENDING_FILE" \
    python3 << 'PYINIT'
import json
import os
from datetime import datetime

pending_file = os.environ.get('PENDING_FILE_VAR', '')
workspace_id = os.environ.get('WORKSPACE_ID_VAR', '')

if pending_file:
    data = {
        "workspaceId": workspace_id,
        "created": datetime.now().isoformat(),
        "insights": []
    }
    with open(pending_file, 'w') as f:
        json.dump(data, f, indent=2)
PYINIT
fi

# Extract insights using Python
# Pass metadata JSON via environment variable for safety
WORKSPACE_ID_VAR="$WORKSPACE_ID" \
PENDING_FILE_VAR="$PENDING_FILE" \
AGENT_NAME_VAR="${CLAUDE_AGENT_NAME:-unknown}" \
HOOK_INPUT_VAR="$INPUT" \
python3 << 'PYEOF'
import json
import sys
import re
import os
import fcntl
import tempfile
import uuid
from datetime import datetime

def extract_insights_from_text(text, agent_name):
    """Extract insights from text using marker patterns."""
    # Multiline pattern: marker followed by content until next marker or end
    # Supports:
    #   1. Single line: INSIGHT: text here
    #   2. Backslash continuation: INSIGHT: text \
    #                              more text
    #   3. Indent continuation: INSIGHT: text
    #                             continued with 2+ spaces

    markers = ['INSIGHT', 'LEARNED', 'DECISION', 'PATTERN', 'ANTIPATTERN']
    marker_pattern = '|'.join(markers)

    # Pattern to match marker and its content (including multiline)
    # Captures: marker name and content (until next marker or end)
    pattern = rf'(?:^|\n)\s*({marker_pattern}):\s*(.+?)(?=\n\s*(?:{marker_pattern}):|$)'

    insights = []
    timestamp = datetime.now().isoformat()

    matches = re.findall(pattern, text, re.IGNORECASE | re.DOTALL)

    for marker, content in matches:
        # Clean up content: normalize whitespace, handle continuations
        # Remove backslash continuations
        content = re.sub(r'\\\n\s*', ' ', content)
        # Normalize internal whitespace (preserve single newlines for readability)
        content = re.sub(r'[ \t]+', ' ', content)
        content = content.strip()

        # Skip very short or empty content
        if not content or len(content) <= 10:
            continue

        # Generate unique ID using UUID to prevent collisions
        insight_id = f"INS-{datetime.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:8]}"

        insights.append({
            "id": insight_id,
            "timestamp": timestamp,
            "category": marker.lower(),
            "content": content,
            "source": agent_name,
            "status": "pending"
        })

    return insights

def extract_assistant_content_from_jsonl(transcript_path):
    """Extract assistant message content from JSONL transcript file."""
    content_parts = []

    try:
        expanded_path = os.path.expanduser(transcript_path)
        with open(expanded_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                    # Look for assistant messages in various formats
                    role = entry.get('role', '')
                    if role == 'assistant':
                        content = entry.get('content', '')
                        if isinstance(content, str):
                            content_parts.append(content)
                        elif isinstance(content, list):
                            # Handle content blocks (text, tool_use, etc.)
                            for block in content:
                                if isinstance(block, dict):
                                    if block.get('type') == 'text':
                                        content_parts.append(block.get('text', ''))
                                elif isinstance(block, str):
                                    content_parts.append(block)
                except json.JSONDecodeError:
                    continue
    except (FileNotFoundError, PermissionError, IOError):
        pass

    return '\n'.join(content_parts)

def update_pending_file_atomic(pending_file, new_insights, workspace_id):
    """Update pending.json with file locking and atomic write."""
    if not new_insights:
        return 0

    # Open file for locking (create if not exists)
    lock_file = pending_file + '.lock'

    try:
        # Create lock file and acquire exclusive lock
        with open(lock_file, 'w') as lf:
            fcntl.flock(lf.fileno(), fcntl.LOCK_EX)

            try:
                # Read existing data
                try:
                    with open(pending_file, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                except (json.JSONDecodeError, FileNotFoundError):
                    data = {
                        "workspaceId": workspace_id,
                        "created": datetime.now().isoformat(),
                        "insights": []
                    }

                # Add new insights
                data['insights'].extend(new_insights)
                data['lastUpdated'] = datetime.now().isoformat()

                # Atomic write: write to temp file, then rename
                dir_name = os.path.dirname(pending_file)
                fd, temp_path = tempfile.mkstemp(dir=dir_name, suffix='.tmp')
                try:
                    with os.fdopen(fd, 'w', encoding='utf-8') as tf:
                        json.dump(data, tf, indent=2, ensure_ascii=False)
                    os.rename(temp_path, pending_file)
                except:
                    # Clean up temp file on error
                    if os.path.exists(temp_path):
                        os.unlink(temp_path)
                    raise

                return len(new_insights)
            finally:
                # Lock is released when file is closed
                pass
    except Exception as e:
        # Log error but don't fail the hook
        sys.stderr.write(f"Warning: Failed to update insights: {e}\n")
        return 0

# Main execution
try:
    # Get environment variables
    hook_input = os.environ.get('HOOK_INPUT_VAR', '')
    pending_file = os.environ.get('PENDING_FILE_VAR', '')
    workspace_id = os.environ.get('WORKSPACE_ID_VAR', '')
    agent_name = os.environ.get('AGENT_NAME_VAR', 'unknown')

    if not hook_input or not pending_file:
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Parse hook input (metadata JSON)
    try:
        metadata = json.loads(hook_input)
    except json.JSONDecodeError:
        # Not valid JSON, nothing to process
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Check for infinite loop prevention
    if metadata.get('stop_hook_active', False):
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Get transcript path from metadata
    transcript_path = metadata.get('transcript_path', '')
    if not transcript_path:
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Extract assistant content from JSONL transcript
    assistant_content = extract_assistant_content_from_jsonl(transcript_path)

    if not assistant_content:
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Extract insights from content
    new_insights = extract_insights_from_text(assistant_content, agent_name)

    # Update pending file with locking and atomic write
    count = update_pending_file_atomic(pending_file, new_insights, workspace_id)

    # Output result
    if count > 0:
        print(json.dumps({
            "continue": True,
            "systemMessage": f"Captured {count} insight(s). Run /review-insights to evaluate."
        }))
    else:
        print(json.dumps({"continue": True}))

except Exception as e:
    # Don't fail the hook on errors, just log and continue
    sys.stderr.write(f"insight_capture.sh warning: {e}\n")
    print(json.dumps({"continue": True}))
PYEOF

exit 0
