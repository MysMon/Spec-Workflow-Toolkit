#!/usr/bin/env python3
"""
Secret Leak Prevention Hook - PreToolUse for Write/Edit
Detects secrets and sensitive data before they're written to files.
Stack-agnostic: works with any project type.

Based on Claude Code hooks specification:
https://code.claude.com/docs/en/hooks

Uses JSON decision control (exit 0 + hookSpecificOutput) for proper blocking.
"""

import sys
import os
import re
import json

# Read tool input from stdin (Claude Code passes JSON)
input_data = sys.stdin.read().strip()

try:
    data = json.loads(input_data)
    tool_input = data.get("tool_input", {})
    # Handle both Write (content) and Edit (new_string) tools
    content = tool_input.get("content", "") or tool_input.get("new_string", "")
    file_path = tool_input.get("file_path", "")
except json.JSONDecodeError:
    content = input_data
    file_path = ""

# Secret patterns (stack-agnostic)
SECRET_PATTERNS = [
    # AWS
    (r"AKIA[0-9A-Z]{16}", "AWS Access Key ID"),
    (r"ASIA[0-9A-Z]{16}", "AWS Session Token ID"),

    # Anthropic
    (r"sk-ant-[a-zA-Z0-9_-]{48,}", "Anthropic API Key"),

    # OpenAI (sk- followed by alphanumeric, but not Stripe patterns)
    (r"sk-[a-zA-Z0-9]{32,}(?<!live_)(?<!test_)", "OpenAI API Key"),

    # HuggingFace
    (r"hf_[a-zA-Z0-9]{34,}", "HuggingFace Token"),

    # GitHub
    (r"ghp_[0-9a-zA-Z]{36}", "GitHub Personal Access Token"),
    (r"gho_[0-9a-zA-Z]{36}", "GitHub OAuth Token"),
    (r"ghs_[0-9a-zA-Z]{36}", "GitHub Server Token"),
    (r"ghu_[0-9a-zA-Z]{36}", "GitHub User Token"),
    (r"github_pat_[0-9a-zA-Z_]{22,}", "GitHub Fine-grained PAT"),

    # GitLab
    (r"glpat-[0-9a-zA-Z_-]{20,}", "GitLab Personal Access Token"),

    # Generic API Keys (more precise - require assignment context)
    (r"(?:api[_-]?key|apikey)[_-]?[=:]\s*['\"]?[a-zA-Z0-9_-]{20,}['\"]?", "Generic API Key"),
    (r"(?:api[_-]?secret|apisecret)[_-]?[=:]\s*['\"]?[a-zA-Z0-9_-]{20,}['\"]?", "Generic API Secret"),

    # Private Keys
    (r"-----BEGIN\s+(RSA|DSA|EC|OPENSSH|PGP)\s+PRIVATE\s+KEY-----", "Private Key"),

    # Database URLs with credentials
    (r"(postgres|mysql|mongodb|redis)://[^:]+:[^@]+@", "Database URL with credentials"),

    # JWT (if suspiciously long)
    (r"eyJ[a-zA-Z0-9_-]{50,}\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+", "Possible JWT Token"),

    # Slack
    (r"xox[baprs]-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*", "Slack Token"),

    # Stripe
    (r"sk_live_[0-9a-zA-Z]{24,}", "Stripe Live Secret Key"),
    (r"sk_test_[0-9a-zA-Z]{24,}", "Stripe Test Secret Key"),
    (r"rk_live_[0-9a-zA-Z]{24,}", "Stripe Live Restricted Key"),

    # Google
    (r"AIza[0-9A-Za-z_-]{35}", "Google API Key"),

    # Twilio
    (r"SK[0-9a-fA-F]{32}", "Twilio API Key"),

    # SendGrid
    (r"SG\.[a-zA-Z0-9_-]{22,}\.[a-zA-Z0-9_-]{22,}", "SendGrid API Key"),

    # Mailchimp
    (r"[0-9a-f]{32}-us[0-9]+", "Mailchimp API Key"),

    # Square
    (r"sq0[a-z]{3}-[0-9A-Za-z_-]{22,}", "Square Token"),

    # npm
    (r"npm_[a-zA-Z0-9]{36}", "npm Token"),

    # PyPI
    (r"pypi-[a-zA-Z0-9_-]{50,}", "PyPI Token"),

    # Passwords in common formats
    (r"password\s*[=:]\s*['\"][^'\"]{8,}['\"]", "Hardcoded password"),
    (r"passwd\s*[=:]\s*['\"][^'\"]{8,}['\"]", "Hardcoded password"),
    (r"pwd\s*[=:]\s*['\"][^'\"]{8,}['\"]", "Hardcoded password"),
]

# Files that are OK to contain secrets (templates, examples, documentation)
ALLOWED_FILES = [
    ".env.example",
    ".env.template",
    ".env.sample",
    ".env.local.example",
    "example.env",
    "example.yaml",
    "example.yml",
    "SETUP.md",
    "INSTALL.md",
    "CONFIG.md",
]

# Patterns for allowed file paths (regex)
ALLOWED_PATH_PATTERNS = [
    r"\.example$",
    r"\.sample$",
    r"\.template$",
    r"/examples?/",
    r"/docs?/",
    r"test_fixtures",
    r"test_data",
]

# Check if file should be skipped
def should_skip_file(path: str) -> bool:
    if not path:
        return False
    filename = os.path.basename(path)
    # Check exact filename matches
    if filename in ALLOWED_FILES:
        return True
    # Check path patterns
    for pattern in ALLOWED_PATH_PATTERNS:
        if re.search(pattern, path, re.IGNORECASE):
            return True
    return False

# Check content for secrets
def find_secrets(text: str) -> list[tuple[str, str]]:
    found = []
    for pattern, description in SECRET_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            found.append((pattern, description))
    return found

# Main check
if should_skip_file(file_path):
    # Allow template/example files without checking
    sys.exit(0)

secrets_found = find_secrets(content)

if secrets_found:
    descriptions = [s[1] for s in secrets_found]
    # Use JSON decision control to properly block the operation
    # Based on: https://code.claude.com/docs/en/hooks
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"Potential secrets detected: {', '.join(descriptions)}. Use environment variables or a secrets manager instead."
        }
    }
    print(json.dumps(output))
    sys.exit(0)  # Exit 0 with JSON decision control
else:
    # Allow the operation to proceed
    sys.exit(0)
