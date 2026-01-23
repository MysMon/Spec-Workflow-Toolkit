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
import base64

# Read tool input from stdin (Claude Code passes JSON)
input_data = sys.stdin.read().strip()

try:
    data = json.loads(input_data)
    tool_input = data.get("tool_input", {})
    # Handle both Write (content) and Edit (new_string) tools
    content = tool_input.get("content", "") or tool_input.get("new_string", "")
    file_path = tool_input.get("file_path", "")
except json.JSONDecodeError:
    # Fail-safe: deny on parse error (do not process raw input)
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "Secret leak check failed: Invalid JSON input format"
        }
    }
    print(json.dumps(output))
    sys.exit(0)

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

    # Supabase
    (r"sbp_[a-f0-9]{40,}", "Supabase Service Key"),
    (r"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+", "Supabase JWT (anon/service key)"),

    # DigitalOcean
    (r"dop_v1_[a-f0-9]{64}", "DigitalOcean Personal Access Token"),
    (r"doo_v1_[a-f0-9]{64}", "DigitalOcean OAuth Token"),

    # Datadog
    (r"DD[A-Z0-9]{32}", "Datadog API Key"),
    (r"[a-f0-9]{40}", "Datadog App Key (40 char hex)"),

    # Azure
    (r"[a-zA-Z0-9+/]{86}==", "Azure Storage Account Key"),

    # Vercel
    (r"vercel_[a-zA-Z0-9_-]{24,}", "Vercel Token"),

    # Netlify
    (r"[a-f0-9]{64}", "Netlify Personal Access Token (64 char hex)"),

    # HashiCorp Vault
    (r"hvs\.[a-zA-Z0-9_-]{24,}", "HashiCorp Vault Token"),
    (r"hvb\.[a-zA-Z0-9_-]{24,}", "HashiCorp Vault Batch Token"),

    # Linear
    (r"lin_api_[a-zA-Z0-9]{40,}", "Linear API Key"),

    # Figma
    (r"figd_[a-zA-Z0-9_-]{40,}", "Figma Personal Access Token"),

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

# Base64 encoded secret detection
def find_base64_secrets(text: str) -> list[tuple[str, str]]:
    """
    Detect base64-encoded secrets by finding base64 strings and checking
    their decoded content against known secret patterns.

    Returns: list of (pattern, description) tuples for found secrets

    Design decisions:
    - Minimum 24 chars: Base64 encodes 3 bytes to 4 chars, so 24 chars = 18 bytes minimum.
      This is enough for most API key prefixes (sk-ant-, ghp_, AKIA) after decoding.
    - Assignment context ([=:]) required to avoid matching image data, random strings.
    - Padding ={0,3}: Base64 can have 0-2 padding chars, but we allow 3 for malformed input.
    - High-value patterns only: We check for specific known secret formats after decoding
      to minimize false positives (e.g., random base64 that decodes to gibberish).
    """
    found = []

    # Pattern to find potential base64 strings in assignment context
    # Minimum 24 chars (encodes 18 bytes) to reduce false positives
    base64_context_pattern = r'[=:]\s*["\']?([A-Za-z0-9+/]{24,}={0,3})["\']?'

    candidates = re.findall(base64_context_pattern, text)

    for candidate in candidates:
        try:
            # Try to decode as base64
            decoded = base64.b64decode(candidate, validate=True).decode('utf-8', errors='ignore')

            # Check decoded content against secret patterns
            # Only check specific high-value patterns to reduce false positives
            high_value_patterns = [
                (r"sk-ant-[a-zA-Z0-9_-]{20,}", "Anthropic API Key (base64 encoded)"),
                (r"sk-[a-zA-Z0-9]{20,}", "OpenAI API Key (base64 encoded)"),
                (r"AKIA[0-9A-Z]{16}", "AWS Access Key ID (base64 encoded)"),
                (r"ghp_[0-9a-zA-Z]{36}", "GitHub Personal Access Token (base64 encoded)"),
                (r"glpat-[0-9a-zA-Z_-]{20,}", "GitLab Personal Access Token (base64 encoded)"),
                (r"-----BEGIN\s+(RSA|DSA|EC|OPENSSH|PGP)\s+PRIVATE\s+KEY-----", "Private Key (base64 encoded)"),
                (r"(postgres|mysql|mongodb)://[^:]+:[^@]+@", "Database URL (base64 encoded)"),
            ]

            for pattern, description in high_value_patterns:
                if re.search(pattern, decoded, re.IGNORECASE):
                    found.append((pattern, description))
                    break  # One match per candidate is enough
        except Exception:
            # Not valid base64 or decode error - skip
            pass

    return found

# Main check - wrapped in try/except for fail-closed behavior
try:
    if should_skip_file(file_path):
        # Allow template/example files without checking
        sys.exit(0)

    # Check for plaintext secrets first
    secrets_found = find_secrets(content)

    # Also check for base64-encoded secrets
    base64_secrets = find_base64_secrets(content)
    secrets_found.extend(base64_secrets)

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

except Exception as e:
    # Fail-safe: deny on unexpected error to prevent secret leakage
    # This ensures fail-closed behavior consistent with external_content_validator.py
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"Secret leak check failed: {str(e)}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)
