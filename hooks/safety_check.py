#!/usr/bin/env python3
"""
Safety Check Hook - PreToolUse for Bash and MCP command execution tools
Blocks dangerous shell commands or transforms them to safer alternatives.
Stack-agnostic: works with any project type.

Based on Claude Code hooks specification:
https://code.claude.com/docs/en/hooks

Features:
- JSON decision control (exit 0 + hookSpecificOutput) for blocking
- Input modification (updatedInput) for transforming commands to safer versions
- Supports v2.0.10+ input modification capability
- MCP tool support: Validates commands from MCP servers (mcp__*__exec, mcp__*__shell, etc.)

Uses two strategies:
1. BLOCK: Completely dangerous commands that cannot be made safe
2. TRANSFORM: Commands that can be made safer with modifications
"""

import sys
import re
import json

# Read tool input from stdin (Claude Code passes JSON)
input_data = sys.stdin.read().strip()

def extract_command_from_input(tool_name: str, tool_input: dict) -> str:
    """
    Extract command string from tool input, handling both Bash and MCP tools.
    MCP tools may use different field names for the command.
    """
    # Standard Bash tool
    if tool_name == "Bash":
        return tool_input.get("command", "")

    # MCP tools - try common field names for command execution
    # Different MCP servers use different field names
    command_fields = [
        "command",      # Most common
        "cmd",          # Short form
        "script",       # For script execution
        "shell_command",
        "bash_command",
        "exec",
        "run",
        "code",         # Some servers use this
        "input",        # Terminal tools may use this
    ]

    for field in command_fields:
        if field in tool_input and isinstance(tool_input[field], str):
            return tool_input[field]

    # Some MCP tools pass command as first positional argument in an array
    if "args" in tool_input and isinstance(tool_input["args"], list) and len(tool_input["args"]) > 0:
        return str(tool_input["args"][0])

    return ""

try:
    data = json.loads(input_data)
    tool_name = data.get("tool_name", "Bash")
    tool_input = data.get("tool_input", {})
    command = extract_command_from_input(tool_name, tool_input)
    is_mcp_tool = tool_name.startswith("mcp__")
except json.JSONDecodeError:
    # Fail-safe: deny on parse error (do not process raw input)
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "Safety check failed: Invalid JSON input format"
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# Environment variable secret patterns - detect secret leakage via export
# These are checked BEFORE dangerous patterns to provide more specific error messages
#
# Design decisions:
# - Only block when a literal value (not $VAR reference) is being assigned
# - Require minimum 20 chars for value to reduce false positives on test/dummy values
# - Allow leading whitespace but anchor to line context
# - Provider-specific patterns are more strict (any value blocked)
ENV_SECRET_PATTERNS = [
    # Provider-specific secrets - block regardless of value length (high confidence)
    # These providers' API keys are always sensitive
    (r"export\s+(?:ANTHROPIC|OPENAI)_(?:API_KEY|SECRET)[A-Z_]*\s*=\s*['\"]?(?!\$)[a-zA-Z0-9_-]{10,}", "Provider API key (Anthropic/OpenAI)"),
    (r"export\s+AWS_(?:SECRET_ACCESS_KEY|SESSION_TOKEN)\s*=\s*['\"]?(?!\$)[a-zA-Z0-9_/+-]{20,}", "AWS secret credential"),
    (r"export\s+(?:GITHUB|GITLAB)_(?:TOKEN|PAT|SECRET)[A-Z_]*\s*=\s*['\"]?(?!\$)[a-zA-Z0-9_-]{20,}", "GitHub/GitLab token"),

    # Generic secret patterns - require longer value (20+ chars) to reduce false positives
    # The (?!\$) negative lookahead excludes variable references like $OTHER_VAR
    (r"export\s+[A-Z_]*(?:API_KEY|APIKEY|API_SECRET)[A-Z_]*\s*=\s*['\"]?(?!\$)[a-zA-Z0-9_-]{20,}['\"]?", "API key in environment variable"),
    (r"export\s+[A-Z_]*(?:SECRET_KEY|PRIVATE_KEY|ACCESS_KEY)[A-Z_]*\s*=\s*['\"]?(?!\$)[a-zA-Z0-9_/+-]{20,}['\"]?", "Secret/private key in environment variable"),
    (r"export\s+[A-Z_]*(?:PASSWORD|PASSWD)[A-Z_]*\s*=\s*['\"]?(?!\$)[^\s'\"]{12,}['\"]?", "Password in environment variable"),
]

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
    r">\s*/dev/(sd|hd|nvme|vd)[a-z0-9]*",
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
    # Block PATH hijacking (setting PATH to start with non-standard or tmp directories)
    r"export\s+PATH=['\"]?(/tmp|/var/tmp|\./|\.\./).*",
    r"export\s+PATH=['\"]?[^$/]",  # PATH not starting with / or $
    r"export\s+LD_PRELOAD",
    r"export\s+LD_LIBRARY_PATH=/",
    r"export\s+HISTCONTROL=ignorespace",  # Hide commands from history

    # Script injection patterns (write then execute)
    r"echo\s+.*>\s*\S+\.sh\s*&&\s*(bash|sh|source)",
    r"cat\s+.*>\s*\S+\.sh\s*&&\s*(bash|sh|source)",
    r"printf\s+.*>\s*\S+\.sh\s*&&\s*(bash|sh|source)",

    # Process substitution abuse
    r"bash\s+<\(",
    r"sh\s+<\(",

    # Hex/octal encoded command execution
    r"\$'\\x[0-9a-fA-F]",
    r"echo\s+-e\s+.*\\\\x.*\|\s*(sh|bash)",
    r"printf\s+.*\\\\x.*\|\s*(sh|bash)",

    # Python/Perl/Ruby one-liner execution with dangerous modules
    r"python[3]?\s+-c\s+.*__import__.*subprocess",
    r"perl\s+-e\s+.*system\s*\(",
    r"ruby\s+-e\s+.*system\s*\(",

    # Dangerous xargs patterns
    r"xargs\s+.*rm\s",
    r"xargs\s+.*-I.*sh\s+-c",

    # Tar extraction to root or sensitive directories
    r"tar\s+.*-[xz].*-C\s+/[^a-zA-Z]",

    # Download and execute in one line (additional patterns)
    r"(wget|curl)\s+.*-O\s+-\s*\|\s*(sh|bash)",
    r"(wget|curl)\s+.*--output-document=-\s*\|\s*(sh|bash)",
]

# Transformable patterns - commands that can be made safer via modification
# Format: (pattern, transform_function_name, description)
TRANSFORMABLE_PATTERNS = [
    # rm commands that aren't targeting root - add -i (interactive) flag
    (r"^rm\s+(?!-rf\s+/)(?!-rf\s+\*)(?!-rf\s+~)(.+)$", "add_interactive_flag", "Add interactive confirmation"),
    # Long-running commands without timeout - add timeout wrapper
    (r"^(npm\s+install|yarn\s+install|pip\s+install)", "add_timeout", "Add 5 minute timeout"),
    # git push without -v - add verbose flag for better debugging
    (r"^git\s+push\s+(?!.*-v)(.*)$", "add_verbose_git", "Add verbose flag"),
]

def add_interactive_flag(cmd: str) -> str:
    """Add -i flag to rm commands for interactive confirmation."""
    # Insert -i after rm
    return re.sub(r"^rm\s+", "rm -i ", cmd)

def add_timeout(cmd: str) -> str:
    """Wrap command with timeout for long-running operations."""
    return f"timeout 300 {cmd}"

def add_verbose_git(cmd: str) -> str:
    """Add verbose flag to git push for better debugging output."""
    return re.sub(r"^git\s+push\s+", "git push -v ", cmd)

# Check for environment variable secrets (more specific, checked first)
def check_env_secrets(cmd: str) -> tuple[bool, str]:
    """
    Check if command exports secrets via environment variables.
    Returns: (is_secret_export, description)
    """
    for pattern, description in ENV_SECRET_PATTERNS:
        if re.search(pattern, cmd, re.IGNORECASE | re.MULTILINE):
            return True, description
    return False, ""

# Check command against patterns
def is_dangerous(cmd: str) -> tuple[bool, str]:
    cmd_lower = cmd.lower()
    for pattern in DANGEROUS_PATTERNS:
        if re.search(pattern, cmd_lower, re.IGNORECASE):
            return True, pattern
    return False, ""

def check_transformable(cmd: str) -> tuple[bool, str, str]:
    """
    Check if command can be transformed to a safer version.
    Returns: (is_transformable, transformed_command, description)
    """
    for pattern, transform_name, description in TRANSFORMABLE_PATTERNS:
        if re.search(pattern, cmd, re.IGNORECASE):
            transform_func = globals().get(transform_name)
            if transform_func:
                transformed = transform_func(cmd)
                if transformed != cmd:  # Only return if actually transformed
                    return True, transformed, description
    return False, cmd, ""

# Main check - first check env secrets, then dangerous, then transformable
# Check for environment variable secret exports first (more specific message)
is_env_secret, secret_desc = check_env_secrets(command)

if is_env_secret:
    # Block secret exports with specific guidance
    tool_type = f"MCP tool ({tool_name})" if is_mcp_tool else "Bash"
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"Blocked {tool_type} command: {secret_desc}. Use .env files or a secrets manager instead of exporting secrets directly in shell commands."
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# Check dangerous patterns
dangerous, matched_pattern = is_dangerous(command)

if dangerous:
    # Use JSON decision control to properly block the command
    # Based on: https://code.claude.com/docs/en/hooks
    tool_type = f"MCP tool ({tool_name})" if is_mcp_tool else "Bash"
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"Blocked dangerous {tool_type} command matching pattern: {matched_pattern}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)  # Exit 0 with JSON decision control

# Check if command can be transformed to a safer version
# Note: Transformations only apply to Bash tool (we know its schema)
# MCP tools have varying schemas, so we only block dangerous commands
transformable, transformed_cmd, transform_desc = check_transformable(command)

if transformable and not is_mcp_tool:
    # Use input modification to transform command (v2.0.10+ feature)
    # Include permissionDecisionReason for audit trail and transparency
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": f"Transformed for safety: {transform_desc}. Original: {command[:50]}{'...' if len(command) > 50 else ''}",
            "updatedInput": {
                "command": transformed_cmd
            }
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# Allow the command to proceed unchanged - explicit allow for audit consistency
output = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow"
    }
}
print(json.dumps(output))
sys.exit(0)
