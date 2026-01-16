#!/usr/bin/env python3
"""
Safety Check Hook - PreToolUse for Bash commands
Blocks dangerous shell commands that could harm the system.
Stack-agnostic: works with any project type.
"""

import sys
import os
import re
import json

# Read command from stdin (Claude Code passes tool input)
input_data = sys.stdin.read().strip()

try:
    data = json.loads(input_data)
    command = data.get("command", "")
except json.JSONDecodeError:
    command = input_data

# Dangerous command patterns (stack-agnostic)
DANGEROUS_PATTERNS = [
    # Destructive file operations
    r"rm\s+-rf\s+/",
    r"rm\s+-rf\s+\*",
    r"rm\s+-rf\s+~",
    r"rm\s+-rf\s+\$HOME",
    r"rmdir\s+/",

    # Privilege escalation
    r"sudo\s+",
    r"su\s+-",
    r"chmod\s+777",
    r"chmod\s+-R\s+777",
    r"chown\s+-R\s+root",

    # Dangerous downloads
    r"curl\s+.*\|\s*sh",
    r"curl\s+.*\|\s*bash",
    r"wget\s+.*\|\s*sh",
    r"wget\s+.*\|\s*bash",
    r"curl\s+.*>\s*/",
    r"wget\s+.*-O\s*/",

    # System modification
    r"mkfs\.",
    r"dd\s+if=.*of=/dev/",
    r">\s*/dev/sd",
    r"echo\s+.*>\s*/etc/",

    # Fork bombs and resource exhaustion
    r":\(\)\s*\{\s*:\|:\s*&\s*\}",
    r"while\s+true.*fork",

    # History manipulation (hiding tracks)
    r"history\s+-c",
    r"unset\s+HISTFILE",
    r"export\s+HISTSIZE=0",

    # Network attacks
    r"nc\s+-l.*\|.*sh",
    r"ncat.*-e\s+/bin",

    # Dangerous environment changes
    r"export\s+PATH=",
    r"export\s+LD_PRELOAD",
    r"export\s+LD_LIBRARY_PATH=/",
]

# Check command against patterns
def is_dangerous(cmd: str) -> tuple[bool, str]:
    cmd_lower = cmd.lower()
    for pattern in DANGEROUS_PATTERNS:
        if re.search(pattern, cmd_lower, re.IGNORECASE):
            return True, pattern
    return False, ""

# Main check
dangerous, matched_pattern = is_dangerous(command)

if dangerous:
    print(json.dumps({
        "decision": "block",
        "reason": f"Blocked dangerous command matching pattern: {matched_pattern}"
    }))
    sys.exit(1)
else:
    print(json.dumps({
        "decision": "allow"
    }))
    sys.exit(0)
