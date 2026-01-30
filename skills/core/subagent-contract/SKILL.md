---
name: subagent-contract
description: |
  Standardized communication protocol for orchestrators AND subagents.
  Defines rules, responsibilities, and result formats for the delegation system.

  Use when:
  - Writing or maintaining command files (orchestrator rules)
  - Defining new subagent behaviors (subagent rules)
  - Aggregating results from multiple agents
  - Understanding delegation constraints
  - Handling agent failures (error handling section)

  Trigger phrases: subagent format, agent output, result format, orchestrator rules, delegation protocol

  This skill defines the CONTRACT between orchestrator and subagents - both sides.
allowed-tools: Read
model: sonnet
user-invocable: false
---

# Subagent Communication Contract

A standardized protocol for subagent inputs, outputs, and error handling to ensure consistent orchestration.

## Why Standardization Matters

From Claude Code Best Practices:

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

## Rules for Orchestrators

The orchestrator (command executor) has specific responsibilities and constraints to maintain efficient context usage and delegation consistency.

### Rules (L1 - Hard)

Critical for context protection and delegation consistency.

- **MUST delegate bulk Grep/Glob operations to `code-explorer`** - Use directly only for single targeted lookups (≤3 files)
- **NEVER read more than 3 files directly** - Delegate bulk reading to subagents
- **NEVER implement code yourself** - Delegate to specialist agents (frontend-specialist, backend-specialist, qa-engineer)
- **NEVER write tests yourself** - Delegate to `qa-engineer`
- **NEVER do security analysis yourself** - Delegate to `security-auditor`
- **NEVER edit spec/design files directly** - Delegate to `product-manager`
- **ALWAYS wait for subagent completion** before synthesizing results
- **ALWAYS use subagent output** for context - do not re-read files the subagent already analyzed

### Defaults (L2 - Soft)

Important for orchestration quality. Override with reasoning when appropriate.

- Launch parallel agents when tasks are independent
- Use appropriate model for agent tasks (haiku for simple lookups, sonnet for analysis, opus for complex PRD)
- Present subagent results to user before proceeding to next phase
- Update progress files at each phase completion

### Guidelines (L3)

Recommendations for effective orchestration.

- Consider splitting large tasks across multiple agents
- Prefer asking user questions over guessing intent
- Document agent failures in progress files for debugging

### Orchestrator Responsibilities

The orchestrator's ONLY responsibilities are:

1. **Orchestrate** - Launch and coordinate subagents
2. **Synthesize** - Combine subagent outputs into coherent summaries
3. **Communicate** - Present findings and ask user questions
4. **Track Progress** - Update TodoWrite and progress files
5. **Verify Minimally** - Read specific files identified by subagents (max 3 at a time) only when necessary

### Error Handling for Orchestrators

When a subagent fails or times out:

1. **Check partial output** for usable findings
2. **Retry once** with reduced scope if critical
3. **Proceed with available results** if non-critical, documenting the gap
4. **Escalate to user** if critical agent fails after retry

Add to progress file when agents fail:
```json
"warnings": ["Agent X failed, results may be incomplete"]
```

---

## Rules for Subagents

### Rules (L1 - Hard)

Critical for orchestration consistency and context protection.

- ALWAYS use the standardized result format (enables aggregation)
- NEVER exceed ~500 tokens for summaries (context protection critical)
- ALWAYS report blockers that prevent completion (orchestrator needs to know)
- ALWAYS complete Pre-Submission Verification checklist before returning results (see below)
- ALWAYS verify file:line references exist before submitting (prevents hallucinations)
- NEVER submit results with hallucinated file paths or line numbers
- MUST include confidence breakdown (verified_confidence + inferred_confidence) when confidence >= 75

### Defaults (L2 - Soft)

Important for quality and usability. Override with reasoning when appropriate.

- Include file:line references for all findings (aids navigation)
- Provide confidence scores with justification (enables prioritization)
- Summarize exploration results, don't return raw output
- Categorize issues by severity (critical/important/minor)

### Guidelines (L3)

Recommendations for better results.

- Include next steps when applicable
- Suggest recovery options for errors
- Note trade-offs considered in design decisions
- Reference patterns found for architectural consistency

## Self-Verification Checklist
Before submitting results, subagents MUST verify their output quality to prevent hallucinations and ensure accuracy.

### Pre-Submission Verification (L1 - Required)

All subagents must complete this checklist before returning results:

```markdown
### Verification Completed
- [ ] **File References Valid**: All `file:line` references have been verified to exist
- [ ] **Code Snippets Accurate**: Any quoted code matches the actual file content
- [ ] **No Hallucinated Paths**: No file paths were assumed or invented
- [ ] **Evidence Documented**: Each finding has supporting evidence cited
```

### Confidence Breakdown (L1 Required for confidence >= 75)

Report confidence as two components:
- **verified_confidence**: Based on direct code evidence (file read, test output)
- **inferred_confidence**: Based on pattern analysis and reasonable assumptions
- **combined_confidence**: (verified + inferred) / 2

Example:
- verified_confidence: 90 (read the exact function, saw the bug)
- inferred_confidence: 70 (similar pattern likely exists elsewhere)
- combined_confidence: 80

### Confidence Justification (L2 - Required for Confidence >= 85)

When reporting high confidence (85+), provide explicit justification:

```markdown
### Confidence Justification
**Score**: [X]
**Evidence Count**: [N findings with direct code evidence]
**Verification Method**: [How findings were verified]
**Potential Blind Spots**: [What might have been missed]
```

### Cross-Verification Triggers (L2)

Request additional verification when:

| Condition | Action |
|-----------|--------|
| Single source of evidence | Flag as "needs corroboration" |
| Conflicting findings | Escalate to orchestrator |
| Confidence < 70 | Include "Uncertainty" section |
| Security-related finding | Require code evidence |

### Anti-Hallucination Practices

1. **Never invent file paths** - If unsure, use Glob/Grep to verify
2. **Never quote code without reading** - Always Read the file first
3. **Never assume implementation details** - Verify with actual code
4. **Flag uncertainty explicitly** - Use "uncertain" or "assumed" labels

### Example: Verified vs Unverified Output

**Unverified (BAD)**:
```
Found authentication in src/auth/login.ts:45
```

**Verified (GOOD)**:
```
Found authentication in src/auth/login.ts:45
- Verified: Read tool confirmed file exists
- Code match: `export async function authenticate()`
- Confidence: 95 (direct code evidence)
```
