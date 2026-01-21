#!/usr/bin/env python3
"""
Verify References Hook - SubagentStop event handler
Validates file:line references in subagent output to catch hallucinated code locations.

Based on Claude Code hooks specification.

Input: JSON metadata from stdin containing transcript_path to JSONL file
Output:
  - If >30% references are invalid: exit 2 with warning message (blocking error)
  - Otherwise: exit 0 with JSON containing verification summary

Reference patterns matched:
  - file.ts:123
  - path/to/file.py:45
  - src/components/Button.tsx:100
  - /absolute/path/file.js:200
"""

import sys
import re
import json
import os
from typing import List, Dict, Tuple, Optional

# =============================================================================
# CONFIGURATION
# =============================================================================

# Threshold for invalid references (percentage)
INVALID_THRESHOLD = 30

# Maximum file size for transcript processing (100MB)
MAX_TRANSCRIPT_SIZE = 100 * 1024 * 1024

# Maximum references to check (performance limit)
MAX_REFERENCES_TO_CHECK = 500

# Reference pattern - matches file:line patterns
# Captures: filename (with optional path), line number
REFERENCE_PATTERN = re.compile(
    r'(?:^|[\s\(\[\{`\'"])' +                    # Start of string or delimiter
    r'(' +                                        # Start capture group
    r'(?:[a-zA-Z0-9_\-./]+/)?' +                 # Optional path prefix
    r'[a-zA-Z0-9_\-]+' +                         # Filename base
    r'\.[a-zA-Z0-9]+' +                          # File extension
    r')' +                                        # End filename capture
    r':(\d+)' +                                   # Colon and line number
    r'(?:$|[\s\)\]\}`\'",:])',                   # End of string or delimiter
    re.MULTILINE
)

# =============================================================================
# PATH VALIDATION
# =============================================================================

def validate_transcript_path(path: str) -> Tuple[bool, str, str]:
    """
    Validate transcript_path for security.

    Returns: (is_valid, error_message, resolved_path)
    """
    if not path:
        return False, "Empty path", ""

    expanded = os.path.expanduser(path)

    try:
        resolved = os.path.realpath(expanded)
    except (OSError, ValueError) as e:
        return False, f"Path resolution failed: {e}", ""

    # Check for path traversal
    if '..' in path:
        return False, "Path traversal detected", ""

    # Check for expected Claude directory patterns
    valid_patterns = ['/.claude/', '/claude-code/', '/tmp/claude']
    path_lower = resolved.lower()

    if not any(pattern in path_lower for pattern in valid_patterns):
        return False, "Path not in expected Claude directory", ""

    return True, "", resolved

# =============================================================================
# TRANSCRIPT PARSING
# =============================================================================

def extract_assistant_content(resolved_path: str, max_size: int) -> Tuple[str, bool]:
    """
    Extract assistant message content from JSONL transcript.

    Returns: (content, was_skipped_due_to_size)
    """
    content_parts = []

    try:
        # Check file size
        try:
            file_size = os.path.getsize(resolved_path)
            if file_size > max_size:
                return '', True
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
# REFERENCE EXTRACTION AND VALIDATION
# =============================================================================

def extract_references(text: str) -> List[Dict[str, any]]:
    """
    Extract file:line references from text.

    Returns list of dicts with 'file' and 'line' keys.
    """
    references = []
    seen = set()

    matches = REFERENCE_PATTERN.findall(text)

    for filepath, line_str in matches:
        if len(references) >= MAX_REFERENCES_TO_CHECK:
            break

        # Skip obvious non-file patterns
        if filepath.startswith('http://') or filepath.startswith('https://'):
            continue
        if filepath.startswith('node_modules/'):
            continue
        if '::' in filepath:  # C++ scope resolution
            continue

        try:
            line_num = int(line_str)
        except ValueError:
            continue

        # Deduplicate
        key = (filepath, line_num)
        if key in seen:
            continue
        seen.add(key)

        references.append({
            'file': filepath,
            'line': line_num
        })

    return references


def resolve_file_path(reference_path: str) -> Optional[str]:
    """
    Resolve a reference path to an actual file on disk.
    Tries multiple strategies to find the file.

    Returns: resolved absolute path or None if not found
    """
    # Strategy 1: Absolute path
    if os.path.isabs(reference_path):
        if os.path.isfile(reference_path):
            return reference_path
        return None

    # Strategy 2: Relative to current working directory
    cwd = os.getcwd()
    cwd_path = os.path.join(cwd, reference_path)
    if os.path.isfile(cwd_path):
        return os.path.abspath(cwd_path)

    # Strategy 3: Search common project roots
    project_roots = [
        cwd,
        os.path.join(cwd, 'src'),
        os.path.join(cwd, 'lib'),
        os.path.join(cwd, 'app'),
    ]

    for root in project_roots:
        candidate = os.path.join(root, reference_path)
        if os.path.isfile(candidate):
            return os.path.abspath(candidate)

    return None


def get_file_line_count(filepath: str) -> int:
    """
    Get the number of lines in a file.

    Returns: line count or -1 on error
    """
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            return sum(1 for _ in f)
    except (IOError, OSError):
        return -1


def validate_reference(ref: Dict[str, any]) -> Dict[str, any]:
    """
    Validate a single file:line reference.

    Returns: dict with validation result
    """
    filepath = ref['file']
    line_num = ref['line']

    result = {
        'file': filepath,
        'line': line_num,
        'valid': False,
        'reason': None
    }

    # Resolve the file path
    resolved = resolve_file_path(filepath)

    if resolved is None:
        result['reason'] = 'file_not_found'
        return result

    # Check line count
    total_lines = get_file_line_count(resolved)

    if total_lines < 0:
        result['reason'] = 'file_read_error'
        return result

    if line_num > total_lines:
        result['reason'] = f'line_exceeds_file_length (file has {total_lines} lines)'
        return result

    if line_num < 1:
        result['reason'] = 'invalid_line_number'
        return result

    result['valid'] = True
    result['resolved_path'] = resolved
    return result

# =============================================================================
# MAIN
# =============================================================================

def main():
    # Read hook input from stdin
    try:
        input_data = sys.stdin.read().strip()
    except Exception as e:
        sys.stderr.write(f"verify_references: Failed to read stdin: {e}\n")
        print(json.dumps({"continue": True}))
        sys.exit(0)

    if not input_data:
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Parse hook metadata
    try:
        metadata = json.loads(input_data)
    except json.JSONDecodeError:
        sys.stderr.write("verify_references: Invalid JSON input\n")
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Check for stop_hook_active to prevent infinite loops
    if metadata.get('stop_hook_active', False):
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Get transcript path
    transcript_path = metadata.get('transcript_path', '')
    if not transcript_path:
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Validate transcript path
    is_valid, error_msg, resolved_path = validate_transcript_path(transcript_path)
    if not is_valid:
        sys.stderr.write(f"verify_references: Invalid path - {error_msg}\n")
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Extract content from transcript
    content, was_size_skipped = extract_assistant_content(resolved_path, MAX_TRANSCRIPT_SIZE)
    if was_size_skipped:
        print(json.dumps({
            "continue": True,
            "systemMessage": "verify_references: Transcript too large, skipping validation"
        }))
        sys.exit(0)

    if not content:
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Extract references from content
    references = extract_references(content)

    if not references:
        # No references found, nothing to validate
        print(json.dumps({"continue": True}))
        sys.exit(0)

    # Validate each reference
    results = []
    for ref in references:
        result = validate_reference(ref)
        results.append(result)

    # Calculate statistics
    total = len(results)
    valid_count = sum(1 for r in results if r['valid'])
    invalid_count = total - valid_count
    invalid_percentage = (invalid_count / total * 100) if total > 0 else 0

    # Build summary of invalid references
    invalid_refs = [r for r in results if not r['valid']]

    # Check threshold
    if invalid_percentage > INVALID_THRESHOLD:
        # Build detailed error message
        error_details = []
        for ref in invalid_refs[:10]:  # Show first 10 invalid refs
            error_details.append(f"  - {ref['file']}:{ref['line']} ({ref['reason']})")

        remaining = len(invalid_refs) - 10
        if remaining > 0:
            error_details.append(f"  ... and {remaining} more")

        error_message = (
            f"Reference verification failed: {invalid_percentage:.1f}% of file:line references are invalid "
            f"({invalid_count}/{total}).\n"
            f"Invalid references:\n" + "\n".join(error_details) + "\n"
            f"Please verify code locations before referencing them."
        )

        sys.stderr.write(f"verify_references: {error_message}\n")

        # Exit 2 = blocking error
        print(json.dumps({
            "continue": False,
            "systemMessage": error_message
        }))
        sys.exit(2)

    # Success - output summary
    if invalid_count > 0:
        summary = (
            f"Reference verification: {valid_count}/{total} references valid "
            f"({invalid_count} invalid, {invalid_percentage:.1f}% - below {INVALID_THRESHOLD}% threshold)"
        )
    else:
        summary = f"Reference verification: All {total} file:line references validated successfully"

    print(json.dumps({
        "continue": True,
        "systemMessage": summary
    }))
    sys.exit(0)


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        sys.stderr.write(f"verify_references FATAL: {e}\n")
        print(json.dumps({"continue": True}))
        sys.exit(0)
