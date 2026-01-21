#!/bin/bash
# Insight Capture Hook: Extract and store insights from subagent output
# Runs on SubagentStop to capture marked insights
#
# Folder-based architecture (no file locking needed)
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
# Architecture:
#   Each insight is stored as a separate file in pending/ directory.
#   This eliminates the need for file locking and makes operations atomic.
#
#   .claude/workspaces/{id}/insights/
#   ├── pending/          # New insights awaiting review
#   │   ├── INS-xxx.json
#   │   └── INS-yyy.json
#   ├── applied/          # Applied to CLAUDE.md or rules
#   ├── rejected/         # Rejected by user
#   └── archive/          # Old insights for reference
#
# Benefits:
#   - No file locking required (each file is unique)
#   - Atomic writes (single file creation)
#   - Partial failure resilience (one corrupt file doesn't affect others)
#   - Easy cleanup (just delete files)
#   - Concurrent capture and review without conflicts
#
# Insight Markers (case-insensitive):
#   INSIGHT: <text>      - General learning or discovery
#   LEARNED: <text>      - Something learned from experience
#   DECISION: <text>     - Important decision made
#   PATTERN: <text>      - Reusable pattern discovered
#   ANTIPATTERN: <text>  - Pattern to avoid

set -euo pipefail

# Configuration
readonly MAX_INSIGHT_LENGTH=10000
readonly MAX_TRANSCRIPT_SIZE=$((100 * 1024 * 1024))  # 100MB
readonly MAX_INSIGHTS_PER_CAPTURE=100  # Rate limit: max insights per capture

# Source workspace utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
else
    echo "insight_capture: workspace_utils.sh not found, skipping" >&2
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
INSIGHTS_BASE=".claude/workspaces/$WORKSPACE_ID/insights"
PENDING_DIR="$INSIGHTS_BASE/pending"

# Ensure directories exist
mkdir -p "$PENDING_DIR"
mkdir -p "$INSIGHTS_BASE/applied"
mkdir -p "$INSIGHTS_BASE/rejected"
mkdir -p "$INSIGHTS_BASE/archive"

# Main processing via Python
WORKSPACE_ID_VAR="$WORKSPACE_ID" \
PENDING_DIR_VAR="$PENDING_DIR" \
AGENT_NAME_VAR="${CLAUDE_AGENT_NAME:-unknown}" \
HOOK_INPUT_VAR="$INPUT" \
MAX_INSIGHT_LENGTH_VAR="$MAX_INSIGHT_LENGTH" \
MAX_TRANSCRIPT_SIZE_VAR="$MAX_TRANSCRIPT_SIZE" \
MAX_INSIGHTS_PER_CAPTURE_VAR="$MAX_INSIGHTS_PER_CAPTURE" \
python3 << 'PYEOF'
"""
Insight Capture Engine - Folder-Based Architecture

Key Design Principles:
- Each insight is a separate file (no locking needed)
- File creation is inherently atomic
- Parallel capture and review without conflicts
- Simpler, more robust implementation
"""

import json
import sys
import re
import os
import uuid
import hashlib
from datetime import datetime
from typing import List, Dict, Optional, Tuple, Any

# =============================================================================
# CONFIGURATION
# =============================================================================

class Config:
    def __init__(self):
        self.workspace_id = os.environ.get('WORKSPACE_ID_VAR', '')
        self.pending_dir = os.environ.get('PENDING_DIR_VAR', '')
        self.agent_name = os.environ.get('AGENT_NAME_VAR', 'unknown')
        self.hook_input = os.environ.get('HOOK_INPUT_VAR', '')
        self.max_insight_length = int(os.environ.get('MAX_INSIGHT_LENGTH_VAR', '10000'))
        self.max_transcript_size = int(os.environ.get('MAX_TRANSCRIPT_SIZE_VAR', str(100 * 1024 * 1024)))
        self.max_insights_per_capture = int(os.environ.get('MAX_INSIGHTS_PER_CAPTURE_VAR', '100'))
        self.markers = ['INSIGHT', 'LEARNED', 'DECISION', 'PATTERN', 'ANTIPATTERN']
        self.min_content_length = 11

# =============================================================================
# PATH VALIDATION
# =============================================================================

def validate_transcript_path(path: str) -> Tuple[bool, str, str]:
    """
    Validate transcript_path for security.

    Returns: (is_valid, error_message, resolved_path)
    The resolved_path should be used for reading to prevent TOCTOU attacks.
    """
    if not path:
        return False, "Empty path", ""

    expanded = os.path.expanduser(path)

    try:
        resolved = os.path.realpath(expanded)
    except (OSError, ValueError) as e:
        return False, f"Path resolution failed: {e}", ""

    # Check for path traversal in original input
    if '..' in path:
        return False, "Path traversal detected", ""

    # Check for expected Claude directory patterns
    # SECURITY: Always reject paths not matching valid patterns, regardless of existence
    valid_patterns = ['/.claude/', '/claude-code/', '/tmp/claude']
    path_lower = resolved.lower()

    if not any(pattern in path_lower for pattern in valid_patterns):
        return False, "Path not in expected Claude directory", ""

    # Return the resolved path to prevent TOCTOU between validation and read
    return True, "", resolved

# =============================================================================
# JSONL PARSING
# =============================================================================

def extract_assistant_content(resolved_path: str, max_size: int) -> Tuple[str, bool]:
    """
    Extract assistant message content from JSONL transcript.

    Args:
        resolved_path: The already-resolved absolute path (from validate_transcript_path)
        max_size: Maximum file size to process

    Returns:
        Tuple of (content, was_skipped_due_to_size)
    """
    content_parts = []

    try:
        # Check file size - use resolved path directly (already validated)
        try:
            file_size = os.path.getsize(resolved_path)
            if file_size > max_size:
                size_mb = file_size / (1024 * 1024)
                max_mb = max_size / (1024 * 1024)
                sys.stderr.write(
                    f"insight_capture: Transcript too large ({size_mb:.1f}MB > {max_mb:.1f}MB limit), skipping\n"
                )
                return '', True  # Return flag indicating size skip
        except OSError:
            pass

        with open(resolved_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue

                try:
                    entry = json.loads(line)
                    if entry.get('role') != 'assistant':
                        continue

                    content = entry.get('content', '')
                    if isinstance(content, str):
                        if content:
                            content_parts.append(content)
                    elif isinstance(content, list):
                        for block in content:
                            if isinstance(block, dict) and block.get('type') == 'text':
                                text = block.get('text', '')
                                if text:
                                    content_parts.append(text)
                            elif isinstance(block, str):
                                content_parts.append(block)
                except json.JSONDecodeError:
                    continue

    except (FileNotFoundError, PermissionError, IOError):
        pass

    return '\n'.join(content_parts), False

# =============================================================================
# INSIGHT EXTRACTION (STATE MACHINE)
# =============================================================================

def extract_insights(text: str, agent_name: str, config: Config) -> List[Dict[str, Any]]:
    """Extract insights using state machine approach with code block filtering."""
    if not text:
        return []

    # Pre-process: Remove code blocks and inline code
    text_filtered = re.sub(r'```[\s\S]*?```', '\n', text)
    text_filtered = re.sub(r'`[^`\n]+`', '', text_filtered)

    # Build marker regex
    marker_re = re.compile(
        r'^[ \t]*(' + '|'.join(config.markers) + r'):[ \t]*(.*)$',
        re.IGNORECASE
    )

    insights = []
    seen_hashes = set()
    timestamp = datetime.now().isoformat()

    current_marker = None
    current_content_lines = []
    rate_limit_reached = False

    for line in text_filtered.split('\n'):
        # Rate limit: stop processing if max insights reached
        if len(insights) >= config.max_insights_per_capture:
            if not rate_limit_reached:
                sys.stderr.write(
                    f"insight_capture: Rate limit reached ({config.max_insights_per_capture} insights)\n"
                )
                rate_limit_reached = True
            break

        match = marker_re.match(line)

        if match:
            # Save previous insight
            if current_marker and current_content_lines:
                insight = create_insight(
                    current_marker, current_content_lines, timestamp,
                    agent_name, config, seen_hashes
                )
                if insight:
                    insights.append(insight)

            # Start new insight
            current_marker = match.group(1).upper()
            initial = match.group(2).strip()
            current_content_lines = [initial] if initial else []

        elif current_marker:
            stripped = line.strip()
            if stripped:
                current_content_lines.append(stripped)

    # Don't forget last insight (if within rate limit)
    if current_marker and current_content_lines and len(insights) < config.max_insights_per_capture:
        insight = create_insight(
            current_marker, current_content_lines, timestamp,
            agent_name, config, seen_hashes
        )
        if insight:
            insights.append(insight)

    return insights


def create_insight(
    marker: str,
    content_lines: List[str],
    timestamp: str,
    agent_name: str,
    config: Config,
    seen_hashes: set
) -> Optional[Dict[str, Any]]:
    """Create insight object with validation and deduplication."""
    content = ' '.join(content_lines)
    content = re.sub(r'\\\s*', ' ', content)
    content = re.sub(r'\s+', ' ', content).strip()

    if len(content) < config.min_content_length:
        return None

    if len(content) > config.max_insight_length:
        content = content[:config.max_insight_length] + '... [truncated]'

    # Deduplication
    content_hash = hashlib.sha256(content.lower().encode()).hexdigest()[:16]
    if content_hash in seen_hashes:
        return None
    seen_hashes.add(content_hash)

    # Generate unique ID
    insight_id = f"INS-{datetime.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:8]}"

    return {
        "id": insight_id,
        "timestamp": timestamp,
        "category": marker.lower(),
        "content": content,
        "source": agent_name,
        "status": "pending",
        "contentHash": content_hash,
        "workspaceId": config.workspace_id
    }

# =============================================================================
# FILE OPERATIONS (NO LOCKING NEEDED!)
# =============================================================================

def save_insights_to_files(insights: List[Dict], pending_dir: str) -> int:
    """
    Save each insight as a separate file.

    No locking needed because:
    1. Each file has a unique name (UUID-based)
    2. File creation with O_EXCL is atomic
    3. We write to temp file then rename (atomic on POSIX)
    """
    saved_count = 0

    for insight in insights:
        insight_id = insight['id']
        file_path = os.path.join(pending_dir, f"{insight_id}.json")

        try:
            # Atomic write: temp file in same directory, then rename
            temp_path = file_path + '.tmp'

            with open(temp_path, 'w', encoding='utf-8') as f:
                json.dump(insight, f, indent=2, ensure_ascii=False)
                f.flush()
                os.fsync(f.fileno())

            os.replace(temp_path, file_path)
            saved_count += 1

        except Exception as e:
            sys.stderr.write(f"insight_capture: Failed to save {insight_id}: {e}\n")
            # Clean up temp file if it exists
            try:
                if os.path.exists(temp_path):
                    os.unlink(temp_path)
            except Exception:
                pass

    return saved_count

# =============================================================================
# MAIN
# =============================================================================

def main():
    config = Config()

    if not config.hook_input or not config.pending_dir:
        print(json.dumps({"continue": True}))
        return

    # Parse hook input
    try:
        metadata = json.loads(config.hook_input)
    except json.JSONDecodeError:
        print(json.dumps({"continue": True}))
        return

    # Infinite loop prevention
    if metadata.get('stop_hook_active', False):
        print(json.dumps({"continue": True}))
        return

    # Get and validate transcript path
    transcript_path = metadata.get('transcript_path', '')
    if not transcript_path:
        print(json.dumps({"continue": True}))
        return

    is_valid, error_msg, resolved_path = validate_transcript_path(transcript_path)
    if not is_valid:
        sys.stderr.write(f"insight_capture: Invalid path - {error_msg}\n")
        print(json.dumps({"continue": True}))
        return

    # Extract content using the resolved path (prevents TOCTOU attacks)
    content, was_size_skipped = extract_assistant_content(resolved_path, config.max_transcript_size)
    if was_size_skipped:
        # Notify user that transcript was too large
        max_mb = config.max_transcript_size / (1024 * 1024)
        print(json.dumps({
            "continue": True,
            "systemMessage": f"Transcript too large (>{max_mb:.0f}MB) - insights not captured. Consider splitting into smaller sessions."
        }))
        return
    if not content:
        print(json.dumps({"continue": True}))
        return

    # Extract insights
    insights = extract_insights(content, config.agent_name, config)

    # Save each insight as separate file (NO LOCKING!)
    count = save_insights_to_files(insights, config.pending_dir)

    # Output result
    if count > 0:
        print(json.dumps({
            "continue": True,
            "systemMessage": f"📝 Captured {count} insight(s). Run /review-insights to evaluate."
        }))
    else:
        print(json.dumps({"continue": True}))


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        sys.stderr.write(f"insight_capture FATAL: {e}\n")
        print(json.dumps({"continue": True}))
PYEOF

exit 0
