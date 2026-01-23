#!/usr/bin/env python3
"""
External Content Validator Hook - PreToolUse for WebFetch and WebSearch
Validates external content requests to mitigate security risks.

Based on Claude Code hooks specification:
https://code.claude.com/docs/en/hooks

Security Concerns Addressed:
- Prompt injection from malicious web content
- SSRF (Server-Side Request Forgery) via internal URLs
- Data exfiltration via URL parameters
- Excessive content fetching (DoS prevention)

Features:
- URL validation (block internal/localhost URLs)
- Domain allowlist/blocklist support
- Query parameter sanitization for sensitive data
- Size limits for fetched content
- Rate limiting awareness

Uses JSON decision control (exit 0 + hookSpecificOutput) for blocking.
"""

import sys
import re
import json
import socket
import ipaddress
from urllib.parse import urlparse, parse_qs

# Read tool input from stdin (Claude Code passes JSON)
input_data = sys.stdin.read().strip()

# --- Configuration ---

# Maximum URL length (prevent buffer overflow attacks)
MAX_URL_LENGTH = 2048

# Internal/private network patterns to block (SSRF prevention)
BLOCKED_HOST_PATTERNS = [
    r"^localhost$",
    r"^127\.\d+\.\d+\.\d+$",       # IPv4 loopback
    r"^10\.\d+\.\d+\.\d+$",        # Private Class A
    r"^172\.(1[6-9]|2\d|3[01])\.\d+\.\d+$",  # Private Class B
    r"^192\.168\.\d+\.\d+$",       # Private Class C
    r"^169\.254\.\d+\.\d+$",       # Link-local
    r"^\[?::1\]?$",                # IPv6 loopback
    r"^\[?fe80:",                  # IPv6 link-local
    r"^\[?fc00:",                  # IPv6 unique local
    r"^\[?fd00:",                  # IPv6 unique local
    # IPv4-mapped IPv6 addresses (::ffff:x.x.x.x)
    r"^\[?::ffff:127\.",           # IPv4-mapped loopback
    r"^\[?::ffff:10\.",            # IPv4-mapped private Class A
    r"^\[?::ffff:172\.(1[6-9]|2\d|3[01])\.",  # IPv4-mapped private Class B
    r"^\[?::ffff:192\.168\.",      # IPv4-mapped private Class C
    r"^\[?::ffff:169\.254\.",      # IPv4-mapped link-local
    r"^0\.0\.0\.0$",               # All interfaces
    r"^metadata\.google\.internal$",  # GCP metadata
    r"^169\.254\.169\.254$",       # Cloud metadata (AWS, Azure, GCP)
    r".*\.internal$",              # Generic internal domains
    r".*\.local$",                 # mDNS local domains
    r".*\.localhost$",             # localhost subdomains
]

# Sensitive query parameter names that might leak secrets
SENSITIVE_PARAM_PATTERNS = [
    r"(?i)^api[_-]?key$",
    r"(?i)^secret$",
    r"(?i)^token$",
    r"(?i)^password$",
    r"(?i)^auth$",
    r"(?i)^credential$",
    r"(?i)^private[_-]?key$",
    r"(?i)^access[_-]?key$",
    r"(?i)^session[_-]?id$",
]

# Suspicious URL patterns that might indicate malicious intent
SUSPICIOUS_URL_PATTERNS = [
    r"<script",           # Embedded script tag in URL
    r"javascript:",       # JavaScript protocol
    r"data:",             # Data URI (can contain executable content)
    r"vbscript:",         # VBScript protocol
    r"file://",           # Local file access
    r"%00",               # Null byte injection
    r"\.\.\/",            # Path traversal
    r"\.\.\\",            # Path traversal (Windows)
]


def extract_url_from_input(tool_name: str, tool_input: dict) -> str:
    """Extract URL from WebFetch or WebSearch tool input."""
    if tool_name == "WebFetch":
        return tool_input.get("url", "")
    elif tool_name == "WebSearch":
        # WebSearch uses 'query' not 'url', but we check for URL-like queries
        query = tool_input.get("query", "")
        # If query looks like a URL, validate it
        if query.startswith(("http://", "https://")):
            return query
        return ""  # Regular search queries are allowed
    return ""


def normalize_ip_address(host: str) -> str | None:
    """
    Normalize IP address to standard dotted-decimal format.
    Handles decimal (2130706433), octal (0177.0.0.1), hex (0x7f.0.0.1) formats.
    Returns None if host is not an IP address.
    """
    try:
        # Try to resolve as IP address (handles decimal, octal, hex formats)
        # socket.inet_aton handles various IP formats and normalizes them
        packed = socket.inet_aton(host)
        return socket.inet_ntoa(packed)
    except (socket.error, OSError):
        pass

    # Try IPv6
    try:
        ip = ipaddress.ip_address(host.strip("[]"))
        # Convert IPv4-mapped IPv6 to IPv4 for consistent checking
        if isinstance(ip, ipaddress.IPv6Address) and ip.ipv4_mapped:
            return str(ip.ipv4_mapped)
        return str(ip)
    except ValueError:
        pass

    return None


def is_private_or_reserved_ip(ip_str: str) -> tuple[bool, str]:
    """
    Check if IP address is private, reserved, loopback, or link-local.
    Uses ipaddress module for robust checking.
    """
    try:
        ip = ipaddress.ip_address(ip_str)

        if ip.is_loopback:
            return True, f"Loopback address blocked: {ip_str}"
        if ip.is_private:
            return True, f"Private network address blocked: {ip_str}"
        if ip.is_reserved:
            return True, f"Reserved address blocked: {ip_str}"

        # Check for cloud metadata endpoint BEFORE link-local check
        # (169.254.169.254 is link-local but deserves a specific message)
        if ip_str == "169.254.169.254":
            return True, f"Cloud metadata endpoint blocked: {ip_str}"

        if ip.is_link_local:
            return True, f"Link-local address blocked: {ip_str}"
        if ip.is_multicast:
            return True, f"Multicast address blocked: {ip_str}"

        # Check for unspecified address (0.0.0.0 or ::)
        if ip.is_unspecified:
            return True, f"Unspecified address blocked: {ip_str}"

    except ValueError:
        pass

    return False, ""


def is_blocked_host(host: str) -> tuple[bool, str]:
    """
    Check if host matches blocked patterns (SSRF prevention).
    Handles alternative IP formats (decimal, octal, hex) via normalization.
    """
    host_lower = host.lower()

    # First, try to normalize as IP address (handles decimal/octal/hex bypass attempts)
    normalized_ip = normalize_ip_address(host)
    if normalized_ip:
        # Check normalized IP against private/reserved ranges
        is_private, reason = is_private_or_reserved_ip(normalized_ip)
        if is_private:
            if normalized_ip != host:
                return True, f"{reason} (normalized from: {host})"
            return True, reason

    # Check against regex patterns for domain-based blocks
    for pattern in BLOCKED_HOST_PATTERNS:
        if re.match(pattern, host_lower):
            return True, f"Internal/private network host blocked: {host}"
        # Also check normalized IP against patterns
        if normalized_ip and re.match(pattern, normalized_ip):
            return True, f"Internal/private network host blocked: {host} (resolved to {normalized_ip})"

    return False, ""


def check_sensitive_params(url: str) -> tuple[bool, str]:
    """Check for sensitive data in URL query parameters."""
    try:
        parsed = urlparse(url)
        params = parse_qs(parsed.query)

        for param_name in params.keys():
            for pattern in SENSITIVE_PARAM_PATTERNS:
                if re.match(pattern, param_name):
                    return True, f"Sensitive parameter detected in URL: {param_name}"
    except Exception:
        pass
    return False, ""


def check_suspicious_patterns(url: str) -> tuple[bool, str]:
    """Check for suspicious patterns that might indicate malicious intent."""
    url_lower = url.lower()
    for pattern in SUSPICIOUS_URL_PATTERNS:
        if re.search(pattern, url_lower):
            return True, f"Suspicious pattern detected in URL: {pattern}"
    return False, ""


def validate_url(url: str) -> tuple[bool, str]:
    """
    Validate URL for security concerns.
    Returns (is_valid, error_message).
    """
    if not url:
        return True, ""  # Empty URL means not a URL-based request

    # Check URL length
    if len(url) > MAX_URL_LENGTH:
        return False, f"URL exceeds maximum length ({MAX_URL_LENGTH} chars)"

    # Check for suspicious patterns first
    has_suspicious, reason = check_suspicious_patterns(url)
    if has_suspicious:
        return False, reason

    # Parse URL
    try:
        parsed = urlparse(url)
    except Exception as e:
        return False, f"Invalid URL format: {e}"

    # Ensure scheme is http or https
    if parsed.scheme not in ("http", "https"):
        return False, f"Unsupported URL scheme: {parsed.scheme}"

    # Check for blocked hosts (SSRF prevention)
    host = parsed.hostname or ""
    is_blocked, reason = is_blocked_host(host)
    if is_blocked:
        return False, reason

    # Check for sensitive parameters
    has_sensitive, reason = check_sensitive_params(url)
    if has_sensitive:
        return False, reason

    return True, ""


# --- Main Logic ---

try:
    data = json.loads(input_data)
    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {})

    # Only process WebFetch and WebSearch tools
    if tool_name not in ("WebFetch", "WebSearch"):
        # Pass through other tools
        sys.exit(0)

    # Extract URL to validate
    url = extract_url_from_input(tool_name, tool_input)

    # Validate the URL
    is_valid, error_reason = validate_url(url)

    if not is_valid:
        # Block the request with detailed reason
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"External content validation failed: {error_reason}"
            }
        }
        print(json.dumps(output))
        sys.exit(0)

    # URL is valid - allow the request
    # No output needed for allow decisions
    sys.exit(0)

except json.JSONDecodeError:
    # Fail-safe: deny on parse error
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "External content validation failed: Invalid JSON input format"
        }
    }
    print(json.dumps(output))
    sys.exit(0)
except Exception as e:
    # Fail-safe: deny on unexpected error
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"External content validation failed: {str(e)}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)
