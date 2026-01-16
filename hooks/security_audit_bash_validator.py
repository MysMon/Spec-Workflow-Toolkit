#!/usr/bin/env python3
"""
PreToolUse hook for security-auditor agent.
Validates that Bash commands are read-only audit commands only.

Based on official Claude Code subagent documentation:
https://code.claude.com/docs/en/sub-agents

Exit codes:
- 0: Success, allow the command
- 1: Error, log and continue
- 2: Block the command, return error to Claude
"""

import json
import sys
import re


# Allowed read-only audit commands
ALLOWED_PATTERNS = [
    # Dependency audits
    r'^npm\s+audit',
    r'^yarn\s+audit',
    r'^pip-audit',
    r'^safety\s+check',
    r'^govulncheck',
    r'^cargo\s+audit',
    r'^bundle\s+audit',
    r'^mvn\s+dependency-check',

    # Package listing (read-only)
    r'^npm\s+list',
    r'^pip\s+list',
    r'^pip\s+show',
    r'^go\s+list',
    r'^cargo\s+tree',
    r'^bundle\s+list',

    # Git history (read-only)
    r'^git\s+log',
    r'^git\s+blame',
    r'^git\s+show',
    r'^git\s+diff',
    r'^git\s+status',
    r'^git\s+branch',
    r'^git\s+tag',

    # File inspection (read-only)
    r'^file\s+',
    r'^cat\s+',
    r'^head\s+',
    r'^tail\s+',
    r'^less\s+',
    r'^wc\s+',
    r'^ls\s+',
    r'^find\s+',
    r'^grep\s+',
    r'^rg\s+',  # ripgrep

    # Environment inspection
    r'^env$',
    r'^printenv',
    r'^echo\s+\$',  # Only echo of environment variables
]

# Explicitly blocked dangerous patterns
BLOCKED_PATTERNS = [
    # File modification
    r'\brm\s+',
    r'\bmv\s+',
    r'\bcp\s+',
    r'\bchmod\s+',
    r'\bchown\s+',
    r'\bmkdir\s+',
    r'\brmdir\s+',
    r'\btouch\s+',

    # Package modification
    r'\bnpm\s+install',
    r'\bnpm\s+uninstall',
    r'\bnpm\s+update',
    r'\bpip\s+install',
    r'\bpip\s+uninstall',
    r'\bgo\s+get',
    r'\bgo\s+install',
    r'\bcargo\s+install',
    r'\bbundle\s+install',

    # Network requests
    r'\bcurl\s+',
    r'\bwget\s+',
    r'\bfetch\s+',

    # System commands
    r'\bsudo\s+',
    r'\bsu\s+',
    r'\bsystemctl\s+',
    r'\bservice\s+',

    # Dangerous redirects
    r'>\s*[^&]',  # Output redirect (but not 2>&1)
    r'>>\s*',     # Append redirect

    # Process manipulation
    r'\bkill\s+',
    r'\bpkill\s+',
]


def validate_command(command: str) -> tuple[bool, str]:
    """
    Validate if a command is allowed for security audit.

    Returns:
        (allowed, reason)
    """
    command = command.strip()

    # Check for blocked patterns first
    for pattern in BLOCKED_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return False, f"Blocked pattern detected: {pattern}"

    # Check if command matches any allowed pattern
    for pattern in ALLOWED_PATTERNS:
        if re.match(pattern, command, re.IGNORECASE):
            return True, f"Allowed: matches {pattern}"

    # Default: block unknown commands
    return False, "Command not in allowed list for security audit mode"


def main():
    try:
        # Read input from stdin (JSON format)
        input_data = sys.stdin.read()
        data = json.loads(input_data)

        # Extract the command from tool_input
        tool_input = data.get('tool_input', {})
        command = tool_input.get('command', '')

        if not command:
            # No command to validate
            sys.exit(0)

        allowed, reason = validate_command(command)

        if allowed:
            # Command is allowed
            sys.exit(0)
        else:
            # Command is blocked
            print(f"Security Audit Mode: {reason}", file=sys.stderr)
            print(f"Command blocked: {command[:100]}...", file=sys.stderr)
            print("", file=sys.stderr)
            print("Allowed commands for security audit:", file=sys.stderr)
            print("- Dependency audits: npm audit, pip-audit, cargo audit, etc.", file=sys.stderr)
            print("- Git history: git log, git blame, git show", file=sys.stderr)
            print("- File inspection: cat, head, tail, file, ls, find, grep", file=sys.stderr)
            print("- Package listing: npm list, pip list, go list", file=sys.stderr)
            sys.exit(2)

    except json.JSONDecodeError:
        print("Error: Invalid JSON input", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
