#!/usr/bin/env python3
"""
Safety Check Hook - PreToolUse for Bash commands
Blocks dangerous shell commands that could harm the system.
Stack-agnostic: works with any project type.

Based on Claude Code hooks specification:
https://code.claude.com/docs/en/hooks

Uses JSON decision control (exit 0 + hookSpecificOutput) for proper blocking.
"""

import sys
import re
import json

# Read tool input from stdin (Claude Code passes JSON)
input_data = sys.stdin.read().strip()

try:
    data = json.loads(input_data)
    tool_input = data.get("tool_input", {})
    command = tool_input.get("command", "")
except json.JSONDecodeError:
    # Fallback for direct command input
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

    # Dangerous downloads and remote execution
    r"curl\s+.*\|\s*sh",
    r"curl\s+.*\|\s*bash",
    r"wget\s+.*\|\s*sh",
    r"wget\s+.*\|\s*bash",
    r"curl\s+.*>\s*/",
    r"wget\s+.*-O\s*/",

    # Arbitrary code execution
    r"\beval\s+",
    r"source\s+/dev/",
    r"source\s+<\(",
    r"\.\s+<\(",
    r"base64\s+.*-d.*\|\s*(sh|bash)",

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

    # Network attacks and reverse shells
    r"nc\s+-l.*\|.*sh",
    r"ncat.*-e\s+/bin",
    r"bash\s+-i\s+.*>/dev/tcp/",
    r"python.*socket.*connect.*exec",
    r"perl.*socket.*exec",
    r"php\s+-r.*fsockopen",

    # Crontab manipulation
    r"crontab\s+-r",
    r"echo\s+.*>>\s*/var/spool/cron",
    r"echo\s+.*>>\s*/etc/cron",

    # SSH key manipulation
    r">\s*~/.ssh/authorized_keys",
    r">>\s*~/.ssh/authorized_keys",
    r"echo\s+.*>.*\.ssh/authorized_keys",

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
    # Use JSON decision control to properly block the command
    # Based on: https://code.claude.com/docs/en/hooks
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"Blocked dangerous command matching pattern: {matched_pattern}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)  # Exit 0 with JSON decision control
else:
    # Allow the command to proceed
    sys.exit(0)
