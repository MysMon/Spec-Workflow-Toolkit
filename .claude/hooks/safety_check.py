#!/usr/bin/env python3
"""
Safety Check Hook for Claude Code
Validates Bash commands before execution to prevent dangerous operations.

Exit codes:
- 0: Allow execution
- 2: Block execution (with reason in stderr)
"""

import sys
import json
import re

# Dangerous command patterns to block
DENY_PATTERNS = [
    # System destruction
    (r"rm\s+(-[a-zA-Z]*r[a-zA-Z]*\s+|--recursive\s+).*(/|\*)", "Recursive deletion of root or wildcard"),
    (r"rm\s+-[a-zA-Z]*f[a-zA-Z]*\s+/", "Force deletion in root directory"),

    # Privilege escalation
    (r"\bsudo\b", "Sudo commands require explicit approval"),
    (r"\bsu\s+-", "User switching is not allowed"),

    # System control
    (r"\bshutdown\b", "System shutdown is not allowed"),
    (r"\breboot\b", "System reboot is not allowed"),
    (r"\bhalt\b", "System halt is not allowed"),
    (r"\bpoweroff\b", "System poweroff is not allowed"),

    # Dangerous operations
    (r":\(\)\{\s*:\|:&\s*\};:", "Fork bomb detected"),
    (r"\bmkfs\b", "Filesystem formatting is not allowed"),
    (r"\bdd\s+if=.*/dev/", "Raw device operations are not allowed"),
    (r"\bfdisk\b", "Disk partitioning is not allowed"),

    # Unsafe permissions
    (r"chmod\s+(-R\s+)?777", "Unsafe permission 777 is not allowed"),
    (r"chmod\s+(-R\s+)?[0-7]*7[0-7]*7\s+/", "World-writable permissions on root"),

    # System file modification
    (r">\s*/etc/", "Writing to /etc is not allowed"),
    (r">>\s*/etc/", "Appending to /etc is not allowed"),
    (r"\bsed\s+-i.*\s+/etc/", "In-place editing of /etc files is not allowed"),

    # Network dangers
    (r"curl.*\|\s*(ba)?sh", "Piping curl to shell is dangerous"),
    (r"wget.*\|\s*(ba)?sh", "Piping wget to shell is dangerous"),

    # Database destruction
    (r"DROP\s+DATABASE", "DROP DATABASE requires explicit approval"),
    (r"DROP\s+TABLE\s+\*", "Dropping all tables is not allowed"),
    (r"TRUNCATE\s+TABLE", "TRUNCATE requires explicit approval"),

    # Git dangers
    (r"git\s+push\s+.*--force\s+.*\b(main|master)\b", "Force push to main/master is dangerous"),
    (r"git\s+reset\s+--hard\s+HEAD~", "Hard reset is dangerous"),
]

def check_command(command: str) -> tuple[bool, str]:
    """Check if command matches any deny pattern."""
    for pattern, reason in DENY_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return False, reason
    return True, ""

def main():
    try:
        # Read hook input from stdin
        input_data = json.load(sys.stdin)

        # Extract command from tool input
        tool_input = input_data.get("tool_input", {})
        command = tool_input.get("command", "")

        if not command:
            # No command to check
            print(json.dumps({"status": "passed", "message": "No command to validate"}))
            sys.exit(0)

        # Check against deny patterns
        allowed, reason = check_command(command)

        if not allowed:
            # Block execution
            result = {
                "status": "blocked",
                "reason": reason,
                "command": command[:100]  # Truncate for safety
            }
            print(json.dumps(result), file=sys.stderr)
            sys.exit(2)

        # Allow execution
        print(json.dumps({"status": "passed", "command": command[:50]}))
        sys.exit(0)

    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Failed to parse input: {e}"}), file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": f"Hook error: {e}"}), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
