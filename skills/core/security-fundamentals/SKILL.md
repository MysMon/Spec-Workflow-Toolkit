---
name: security-fundamentals
description: Core security principles and practices applicable to any technology stack. Use when implementing authentication, handling sensitive data, validating input, or reviewing code for security issues.
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
user-invocable: true
---

# Security Fundamentals

Stack-agnostic security principles and practices for building secure applications.

## Core Principles

### 1. Defense in Depth

```
Never rely on a single security measure.

Layers:
- Network (firewalls, VPNs)
- Infrastructure (hardening, least privilege)
- Application (validation, authentication)
- Data (encryption, access control)
```

### 2. Least Privilege

```
Grant minimum required permissions.

Examples:
- Database users: Only necessary tables
- API tokens: Only needed scopes
- File permissions: Only required access
- IAM roles: Specific actions only
```

### 3. Fail Secure

```
When in doubt, deny access.

Example:
if (!hasPermission(user, resource)) {
    return DENIED;  // Fail closed
}
```

### 4. Input Validation

```
Never trust input from untrusted sources.

Validate at:
- API boundaries (external input)
- Service boundaries (inter-service calls)
- Database boundaries (before queries)
```

## OWASP Top 10 Quick Reference

| # | Vulnerability | Prevention |
|---|---------------|------------|
| A01 | Broken Access Control | Auth checks on every request |
| A02 | Cryptographic Failures | Strong encryption, no secrets in code |
| A03 | Injection | Parameterized queries, input validation |
| A04 | Insecure Design | Threat modeling, secure defaults |
| A05 | Security Misconfiguration | Hardened defaults, minimal footprint |
| A06 | Vulnerable Components | Dependency updates, audits |
| A07 | Auth Failures | Strong passwords, MFA, rate limiting |
| A08 | Data Integrity | Signature verification, secure CI/CD |
| A09 | Logging Failures | Comprehensive logging, no PII in logs |
| A10 | SSRF | URL validation, allowlists |

## Secret Management

### Never Hardcode Secrets

```
BAD:
api_key = "sk-1234567890abcdef"
database_url = "postgres://user:password@host/db"

GOOD:
api_key = os.environ["API_KEY"]
database_url = os.environ["DATABASE_URL"]
```

### Environment Files

```
# .env.example (commit this)
API_KEY=your-api-key-here
DATABASE_URL=postgres://user:pass@localhost/db

# .env (NEVER commit)
API_KEY=sk-actual-secret-key
DATABASE_URL=postgres://real:secret@prod/db
```

### .gitignore Pattern

```gitignore
# Environment files
.env
.env.local
.env.*.local
.env.production

# Secrets
*.pem
*.key
*.p12
secrets/
credentials.json
```

## Input Validation Patterns

### Allowlist vs Denylist

```
PREFER ALLOWLIST:
- Define what IS allowed
- Reject everything else

AVOID DENYLIST:
- Trying to block bad input
- Always incomplete
```

### Validation Schema Pattern

```
Define schema:
- Type constraints
- Length limits
- Format patterns
- Required fields

Validate:
- Parse input against schema
- Reject if invalid
- Use validated data only
```

## Authentication Security

### Password Requirements

```
Modern recommendations:
- Minimum 12 characters
- No composition rules (upper/lower/number/special)
- Check against breach databases
- Use bcrypt/argon2/scrypt (not MD5/SHA1)
```

### Session Security

```
Cookie attributes:
- HttpOnly: Prevent XSS access
- Secure: HTTPS only
- SameSite: CSRF protection
- Short expiration
```

### Token Best Practices

```
Access tokens:
- Short expiration (15-60 minutes)
- Minimal claims
- Validate on every request

Refresh tokens:
- Longer expiration
- Rotate on use
- Store securely
```

## Authorization Patterns

### Check on Every Request

```
Pattern:
1. Authenticate user
2. Load resource
3. Check permission
4. Return or deny

NEVER:
- Rely on URL obscurity
- Trust client-side checks
- Cache permissions without invalidation
```

### Resource-Level Checks

```
Example:
1. User requests /documents/123
2. Load document 123
3. Verify user.id == document.owner_id OR user.isAdmin
4. Return document or 403
```

## Logging Security

### What to Log

- Authentication attempts (success and failure)
- Authorization failures
- Input validation failures
- System errors (sanitized)
- Configuration changes

### What NOT to Log

- Passwords (even hashed)
- API keys or tokens
- PII (names, emails, addresses)
- Credit card numbers
- Session tokens

## Dependency Security

### Regular Audits

| Language | Audit Command |
|----------|---------------|
| JavaScript | `npm audit` |
| Python | `pip-audit` or `safety check` |
| Go | `govulncheck ./...` |
| Rust | `cargo audit` |
| Java | `mvn dependency-check:check` |
| Ruby | `bundle audit` |

### Update Strategy

```
1. Monitor for vulnerabilities
2. Test updates in CI
3. Apply security patches promptly
4. Schedule regular dependency updates
```

## Rules

- NEVER hardcode secrets
- ALWAYS validate untrusted input
- NEVER trust client-side validation alone
- ALWAYS use parameterized queries
- NEVER log sensitive data
- ALWAYS hash passwords with strong algorithms
- NEVER expose stack traces to users
- ALWAYS keep dependencies updated
