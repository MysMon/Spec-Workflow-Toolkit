#!/usr/bin/env python3
"""
Secret Leak Prevention Hook for Claude Code
Scans file content before writing to prevent accidental secret exposure.

Exit codes:
- 0: Allow execution
- 2: Block execution (potential secret detected)
"""

import sys
import json
import re
from pathlib import Path

# Secret patterns to detect
SECRET_PATTERNS = [
    # API Keys (generic patterns)
    (r"(?i)(api[_-]?key|apikey)\s*[=:]\s*['\"]?[a-zA-Z0-9_\-]{20,}['\"]?", "API key detected"),
    (r"(?i)(secret[_-]?key|secretkey)\s*[=:]\s*['\"]?[a-zA-Z0-9_\-]{20,}['\"]?", "Secret key detected"),

    # AWS
    (r"AKIA[0-9A-Z]{16}", "AWS Access Key ID detected"),
    (r"(?i)aws[_-]?secret[_-]?access[_-]?key\s*[=:]\s*['\"]?[a-zA-Z0-9/+=]{40}['\"]?", "AWS Secret Access Key detected"),

    # GitHub
    (r"ghp_[a-zA-Z0-9]{36}", "GitHub Personal Access Token detected"),
    (r"gho_[a-zA-Z0-9]{36}", "GitHub OAuth Token detected"),
    (r"ghu_[a-zA-Z0-9]{36}", "GitHub User Token detected"),
    (r"ghs_[a-zA-Z0-9]{36}", "GitHub Server Token detected"),

    # Stripe
    (r"sk_live_[a-zA-Z0-9]{24,}", "Stripe Live Secret Key detected"),
    (r"rk_live_[a-zA-Z0-9]{24,}", "Stripe Live Restricted Key detected"),

    # Database connection strings
    (r"(?i)(postgres|mysql|mongodb)://[^:]+:[^@]+@", "Database connection string with credentials detected"),

    # Private keys
    (r"-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----", "Private key detected"),
    (r"-----BEGIN PGP PRIVATE KEY BLOCK-----", "PGP private key detected"),

    # JWT secrets
    (r"(?i)(jwt[_-]?secret|jwt[_-]?key)\s*[=:]\s*['\"]?[a-zA-Z0-9_\-]{16,}['\"]?", "JWT secret detected"),

    # Generic tokens
    (r"(?i)(auth[_-]?token|access[_-]?token|bearer[_-]?token)\s*[=:]\s*['\"]?[a-zA-Z0-9_\-]{20,}['\"]?", "Auth token detected"),

    # Slack
    (r"xox[baprs]-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*", "Slack token detected"),

    # Google
    (r"AIza[0-9A-Za-z_-]{35}", "Google API Key detected"),

    # Anthropic
    (r"sk-ant-[a-zA-Z0-9_-]{40,}", "Anthropic API Key detected"),

    # OpenAI
    (r"sk-[a-zA-Z0-9]{48}", "OpenAI API Key detected"),
]

# Files that are allowed to contain secret-like patterns (placeholders)
ALLOWLIST_PATTERNS = [
    r"\.example$",
    r"\.template$",
    r"\.sample$",
    r"README",
    r"CLAUDE\.md$",
    r"docs/",
]

def is_allowlisted(file_path: str) -> bool:
    """Check if file is allowlisted for secret patterns."""
    for pattern in ALLOWLIST_PATTERNS:
        if re.search(pattern, file_path, re.IGNORECASE):
            return True
    return False

def check_content(content: str, file_path: str) -> tuple[bool, str]:
    """Check content for secret patterns."""
    if is_allowlisted(file_path):
        return True, "File is allowlisted"

    # Skip if content looks like placeholder
    placeholder_indicators = ["<YOUR_", "<API_KEY>", "${", "YOUR_API_KEY", "xxx", "PLACEHOLDER"]
    for indicator in placeholder_indicators:
        if indicator in content:
            # Check if the pattern is just documentation/placeholder
            continue

    for pattern, reason in SECRET_PATTERNS:
        match = re.search(pattern, content)
        if match:
            matched_text = match.group(0)
            # Skip obvious placeholders
            if any(p in matched_text.upper() for p in ["YOUR", "EXAMPLE", "PLACEHOLDER", "XXX", "TEST"]):
                continue
            return False, f"{reason}: {matched_text[:30]}..."

    return True, ""

def main():
    try:
        # Read hook input from stdin
        input_data = json.load(sys.stdin)

        tool_input = input_data.get("tool_input", {})

        # Get file path and content based on tool type
        file_path = tool_input.get("file_path", tool_input.get("path", ""))
        content = tool_input.get("content", tool_input.get("new_string", ""))

        if not content:
            print(json.dumps({"status": "passed", "message": "No content to check"}))
            sys.exit(0)

        # Check for secrets
        allowed, reason = check_content(content, file_path)

        if not allowed:
            result = {
                "status": "blocked",
                "reason": reason,
                "file": file_path,
                "suggestion": "Use environment variables or a secrets manager instead of hardcoding secrets"
            }
            print(json.dumps(result), file=sys.stderr)
            sys.exit(2)

        print(json.dumps({"status": "passed", "file": file_path}))
        sys.exit(0)

    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Failed to parse input: {e}"}), file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": f"Hook error: {e}"}), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
