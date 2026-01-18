---
name: subagent-contract
description: |
  Standardized result format and communication protocol for all subagents.
  Ensures consistent, aggregatable outputs across the SDD Toolkit.

  Use when:
  - Defining new subagent behaviors
  - Aggregating results from multiple agents
  - Understanding subagent output expectations
  - Designing inter-agent communication

  This skill defines the CONTRACT between orchestrator and subagents.
allowed-tools: Read
model: sonnet
user-invocable: false
---

# Subagent Communication Contract

A standardized protocol for subagent inputs, outputs, and error handling to ensure consistent orchestration.

## Why Standardization Matters

From [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices):

> "Subagents use their own isolated context windows, and only send relevant information back to the orchestrator."

Standardized formats enable:
- Efficient aggregation of multiple agent outputs
- Consistent error handling
- Predictable parsing and processing
- Clear expectations for both agents

## Result Format Specification

### Universal Result Structure

All subagent results MUST follow this structure:

```markdown
## [Agent Name] Result

### Status
[SUCCESS | PARTIAL | FAILED]

### Summary
[2-3 sentence summary of what was accomplished or found]

### Findings
[Structured content specific to agent type - see below]

### Key References
| Item | Location | Relevance |
|------|----------|-----------|
| [Name] | `file:line` | [Why important] |

### Confidence
[0-100] - [Brief justification]

### Issues (if any)
- [Issue 1]: [Description] | Severity: [critical/important/minor]
- [Issue 2]: [Description] | Severity: [critical/important/minor]

### Next Steps (if applicable)
1. [Recommended action 1]
2. [Recommended action 2]

### Blockers (if any)
- [Blocker description] | Resolution: [What's needed]
```

## Agent-Specific Formats

### Exploration Agents (code-explorer, Explore)

```markdown
## Code Explorer Result

### Status
SUCCESS

### Summary
Traced authentication flow from login endpoint through JWT validation to session creation.

### Findings

#### Entry Points
| Entry | File:Line | Type |
|-------|-----------|------|
| POST /auth/login | `src/api/auth.ts:45` | REST endpoint |
| POST /auth/refresh | `src/api/auth.ts:89` | REST endpoint |

#### Execution Flow
1. Request → `src/api/auth.ts:45` (loginHandler)
2. Validation → `src/validators/auth.ts:23` (validateLogin)
3. Service → `src/services/auth.ts:67` (authenticate)
4. Repository → `src/repositories/user.ts:34` (findByEmail)
5. Response ← Token generated

#### Architecture Patterns
- Pattern: Repository + Service + Controller
- Evidence: `src/services/auth.ts:8`, `src/repositories/user.ts:5`

#### Dependencies
- Internal: UserRepository, SessionService
- External: bcrypt, jsonwebtoken

### Key References
| Item | Location | Relevance |
|------|----------|-----------|
| AuthService | `src/services/auth.ts:8` | Core authentication logic |
| JWTMiddleware | `src/middleware/jwt.ts:15` | Token validation |
| UserRepository | `src/repositories/user.ts:5` | User data access |

### Confidence
92 - Clear patterns, all paths traced to completion

### Next Steps
1. Read `src/services/auth.ts` for implementation details
2. Review `src/config/jwt.ts` for token configuration
```

### Design Agents (code-architect, system-architect)

```markdown
## Code Architect Result

### Status
SUCCESS

### Summary
Designed OAuth integration following existing auth patterns. Single recommended approach with implementation map.

### Findings

#### Pattern Analysis
| Pattern | Example | Recommendation |
|---------|---------|----------------|
| Service layer | `src/services/auth.ts:8` | Extend with OAuthService |
| Repository | `src/repositories/user.ts:5` | Add OAuthCredential model |
| Config | `src/config/auth.ts:12` | Add OAuth provider config |

#### Recommended Architecture

**Approach**: Extend existing AuthService with OAuth capabilities

**Rationale**:
- Aligns with existing service pattern at `src/services/auth.ts:8`
- Minimal changes to existing code
- Reuses JWT infrastructure at `src/middleware/jwt.ts:15`

#### Implementation Map

| Component | File | Action |
|-----------|------|--------|
| OAuthService | `src/services/oauth.ts` | Create |
| OAuthConfig | `src/config/oauth.ts` | Create |
| AuthService | `src/services/auth.ts:145` | Modify (add OAuth methods) |
| routes | `src/routes/auth.ts:78` | Modify (add OAuth routes) |

#### Build Sequence
1. Create OAuthConfig with provider settings
2. Create OAuthService with provider handling
3. Extend AuthService with OAuth flow
4. Add OAuth routes
5. Write integration tests

### Key References
| Item | Location | Relevance |
|------|----------|-----------|
| AuthService | `src/services/auth.ts:8` | Base to extend |
| JWTConfig | `src/config/jwt.ts:5` | Token pattern to follow |
| UserModel | `src/models/user.ts:12` | May need OAuth link |

### Confidence
88 - Clear patterns, one assumption about user model

### Trade-offs Considered
- Separate OAuth microservice: Rejected (overhead for this scale)
- Direct provider SDK: Rejected (less abstraction)
```

### Review Agents (qa-engineer, security-auditor)

```markdown
## Security Auditor Result

### Status
PARTIAL

### Summary
Reviewed authentication module. Found 2 critical issues and 3 recommendations.

### Findings

#### Issues Detected

| ID | Issue | File:Line | Severity | Confidence |
|----|-------|-----------|----------|------------|
| SEC-001 | Hardcoded JWT secret | `src/config/jwt.ts:8` | Critical | 98 |
| SEC-002 | Missing rate limiting | `src/api/auth.ts:45` | Critical | 95 |
| SEC-003 | Verbose error messages | `src/services/auth.ts:89` | Important | 85 |

#### Issue Details

**SEC-001: Hardcoded JWT Secret**
```typescript
// src/config/jwt.ts:8
const JWT_SECRET = 'hardcoded-secret-key-123'; // CRITICAL
```
**Risk**: Token forgery, complete auth bypass
**Fix**: Use environment variable `process.env.JWT_SECRET`

**SEC-002: Missing Rate Limiting**
```typescript
// src/api/auth.ts:45 - No rate limiting
router.post('/login', loginHandler);
```
**Risk**: Brute force attacks on login
**Fix**: Add express-rate-limit middleware

**SEC-003: Verbose Error Messages**
```typescript
// src/services/auth.ts:89
throw new Error(`User ${email} not found in database`);
```
**Risk**: Information disclosure (confirms email existence)
**Fix**: Generic "Invalid credentials" message

#### Compliance Check
| Standard | Status | Notes |
|----------|--------|-------|
| OWASP A07 Auth Failures | FAIL | SEC-001, SEC-002 |
| OWASP A01 Access Control | PASS | Proper authorization checks |

### Key References
| Item | Location | Relevance |
|------|----------|-----------|
| JWT Config | `src/config/jwt.ts:8` | Contains hardcoded secret |
| Login Handler | `src/api/auth.ts:45` | Missing rate limit |

### Confidence
94 - Issues verified with code evidence

### Severity Summary
- Critical: 2
- Important: 1
- Minor: 0

### Next Steps
1. Fix SEC-001 immediately (security critical)
2. Add rate limiting before deployment
3. Review all error messages for information disclosure
```

### Implementation Agents (frontend-specialist, backend-specialist)

```markdown
## Backend Specialist Result

### Status
SUCCESS

### Summary
Implemented UserService with registration, login, and password reset. All tests passing.

### Findings

#### Files Created
| File | Purpose | Lines |
|------|---------|-------|
| `src/services/user.ts` | User business logic | 145 |
| `src/repositories/user.ts` | Data access | 78 |
| `tests/services/user.test.ts` | Unit tests | 234 |

#### Files Modified
| File | Change | Lines Changed |
|------|--------|---------------|
| `src/routes/index.ts:45` | Added user routes | +5 |
| `src/services/index.ts:8` | Export UserService | +1 |

#### Test Results
```
PASS tests/services/user.test.ts
  UserService
    createUser
      ✓ should create user with hashed password (45ms)
      ✓ should reject duplicate email (23ms)
      ✓ should validate password length (12ms)
    login
      ✓ should return token for valid credentials (34ms)
      ✓ should reject invalid password (18ms)

Tests: 5 passed, 5 total
Coverage: 94%
```

#### Implementation Notes
- Followed repository pattern from `src/repositories/product.ts:8`
- Used bcrypt with cost factor 12 (matches existing)
- JWT tokens expire in 24h (configurable via env)

### Key References
| Item | Location | Relevance |
|------|----------|-----------|
| UserService | `src/services/user.ts:8` | Main implementation |
| createUser | `src/services/user.ts:45` | Registration logic |
| login | `src/services/user.ts:89` | Auth logic |

### Confidence
96 - Tests passing, patterns followed

### Next Steps
1. Review implementation for approval
2. Run integration tests if available
3. Update API documentation
```

## Error Result Format

When a subagent encounters errors:

```markdown
## [Agent Name] Result

### Status
FAILED

### Summary
Unable to complete task due to [error category].

### Error Details
| Aspect | Value |
|--------|-------|
| Type | [ErrorType] |
| Message | [Error message] |
| Occurred At | [file:line or step] |
| Recoverable | [true/false] |

### Attempted Actions
1. [What was tried first]
2. [What was tried second]
3. [Final attempt before failure]

### Root Cause Analysis
[Analysis of why the error occurred]

### Recovery Options
1. [Option 1]: [Description]
2. [Option 2]: [Description]

### Blockers
- [Description of what's blocking progress]
  Resolution: [What's needed to unblock]
```

## Confidence Score Guidelines

| Score | Meaning | Evidence Required |
|-------|---------|-------------------|
| 95-100 | Certain | Direct code evidence, verified by execution |
| 85-94 | High | Clear code evidence, consistent patterns |
| 75-84 | Moderate | Some evidence, reasonable inference |
| 60-74 | Low | Limited evidence, assumptions made |
| <60 | Uncertain | Speculation, should request clarification |

## Aggregation Protocol

When orchestrator receives multiple subagent results:

### 1. Status Aggregation

```
All SUCCESS → Continue to next phase
Any FAILED → Handle error, possibly retry
Any PARTIAL → Review findings, decide path
```

### 2. Issue Deduplication

```
Same file:line + same category → Keep highest confidence
Multiple agents report same issue → Boost confidence +10 (max 100)
Conflicting findings → Flag for human review
```

### 3. Confidence Weighting

```
Combined confidence = weighted average by agent expertise

Example:
- security-auditor says SEC-001 (conf: 95)
- qa-engineer also flags (conf: 78)
- Combined: (95 + 78) / 2 + 10 (agreement bonus) = 96.5
```

## Rules for Subagents

- ALWAYS use the standardized result format
- ALWAYS include file:line references for all findings
- ALWAYS provide confidence scores with justification
- NEVER return raw exploration results (summarize)
- ALWAYS categorize issues by severity
- ALWAYS include next steps when applicable
- NEVER exceed ~500 tokens for summaries (context protection)
- ALWAYS report blockers that prevent completion
