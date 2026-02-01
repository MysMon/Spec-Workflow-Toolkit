# SDD Workflow Examples

Real-world examples of Specification-Driven Development in action.

## Example 1: User Authentication Feature

### Phase 1: Ambiguity Phase (User Request)

```
User: "Add user authentication"
```

This is vague. We need to clarify.

### Phase 2: Clarification Phase (Interview)

```
Claude: I'll help you add user authentication. Let me gather some requirements.

Questions:
1. What authentication methods do you need?
   - Email/password only
   - OAuth (Google, GitHub, etc.)
   - Magic link / passwordless
   - All of the above

2. Do you need role-based access control?
   - Yes, multiple roles (admin, user, etc.)
   - No, just authenticated vs anonymous

3. What's your session strategy?
   - JWT tokens
   - Server-side sessions
   - No preference (recommend)

User: OAuth with Google, simple auth (no roles), JWT tokens
```

### Phase 3: Definition Phase (Specification)

```markdown
# Feature: User Authentication

## Overview
Enable users to authenticate via Google OAuth to access protected features.

## User Stories
| ID | Story | Priority |
|----|-------|----------|
| US-001 | As a user, I want to sign in with Google so I don't need another password | P0 |
| US-002 | As a user, I want to stay logged in across browser sessions | P0 |
| US-003 | As a user, I want to sign out to secure my account on shared devices | P0 |

## Functional Requirements
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-001 | System SHALL allow Google OAuth sign-in | P0 | User clicks "Sign in with Google" → redirected → returns authenticated |
| FR-002 | System SHALL issue JWT on successful auth | P0 | JWT contains user ID, email, expiry |
| FR-003 | System SHALL refresh tokens before expiry | P0 | Token refreshed within 5 min of expiry |
| FR-004 | System SHALL allow sign out | P0 | Sign out clears tokens, returns to home |

## Non-Functional Requirements
| ID | Category | Requirement |
|----|----------|-------------|
| NFR-001 | Security | Tokens stored in httpOnly cookies |
| NFR-002 | Security | CSRF protection enabled |
| NFR-003 | Performance | Auth flow < 3 seconds |

## Out of Scope
- Email/password authentication
- Role-based access control
- Multi-factor authentication
- Account linking (multiple providers)

## Approval
[x] Product Owner: Approved
[x] Tech Lead: Approved
```

### Phase 4: Execution Phase

```
Claude: Delegating to backend-specialist for OAuth implementation...

Backend-specialist implements:
- /api/auth/google (initiates OAuth)
- /api/auth/callback (handles OAuth callback)
- /api/auth/refresh (refreshes tokens)
- /api/auth/logout (clears session)

Claude: Delegating to frontend-specialist for UI...

Frontend-specialist implements:
- Sign in button component
- Auth context/provider
- Protected route wrapper
- Sign out functionality
```

### Phase 5: Verification Phase

```
Claude: Delegating to qa-engineer for testing...

Tests created:
- Unit: Token generation, validation
- Integration: OAuth flow, refresh flow
- E2E: Full sign-in journey

Claude: Delegating to security-auditor for review...

Security audit:
- Tokens in httpOnly cookies
- CSRF protection
- State parameter prevents CSRF on OAuth
- Recommendation: Add rate limiting to auth endpoints
```

---

## Example 2: Spec Deviation Handling

What happens when implementation reveals a spec gap:

```
Backend-specialist: While implementing FR-001, I discovered we need to handle
the case where a user's Google account email changes. This wasn't specified.

Options:
A) Treat email as immutable (use Google ID only)
B) Update email on each sign-in
C) Flag for manual review

Claude: This is a spec gap. Asking user for clarification...

User: Use option A - treat email as immutable, use Google ID as identifier.

Claude: Updating specification with FR-005: System SHALL use Google ID
(not email) as the unique user identifier.
```

---

## Example 3: Handling "Just Build It"

When users want to skip specs:

```
User: Just build the dashboard, I don't need a spec.

Claude: I understand you want to move fast. However, without a spec:
- We might build the wrong thing
- We'll likely need rework
- We have no acceptance criteria

Let me ask 3 quick questions to create a minimal spec:

1. What data should the dashboard show?
2. Who is the primary user?
3. How will you know it's successful?

This takes 5 minutes and saves hours of rework.

User: OK. It should show sales metrics, for the sales team, success = they stop asking for reports.

Claude: Great! Here's a minimal spec:

# Feature: Sales Dashboard

## Problem
Sales team manually requests reports; need self-service dashboard.

## Requirements
- [ ] Show daily/weekly/monthly sales totals
- [ ] Filter by product, region, rep
- [ ] Export to CSV

## Success Criteria
- [ ] Sales team can answer their own questions
- [ ] Report requests reduced by 80%

Ready to proceed with this spec?
```

---

## Anti-Pattern Examples

### Bad: Assuming Requirements

```
User: Add search functionality

Claude: I'll add full-text search with Elasticsearch, faceted filtering,
autocomplete suggestions, and search analytics...

[WRONG: Never assumed all these requirements]
```

### Good: Clarifying Requirements

```
User: Add search functionality

Claude: I'll help add search. Let me understand what you need:

1. What content should be searchable?
   - Products only
   - Products and blog posts
   - Everything

2. What search features do you need?
   - Basic keyword search
   - Filters (price, category, etc.)
   - Autocomplete suggestions
   - Full-text search with relevance ranking

3. What's your scale?
   - < 1000 items (simple search is fine)
   - 1000-100K items (need indexing)
   - > 100K items (need dedicated search service)
```

### Bad: Gold-Plating

```
# Implementing FR-001: Display user name

Claude: I'll also add:
- Avatar upload
- Custom themes
- Profile page
- Social links
- Bio editor

[WRONG: Only FR-001 was requested]
```

### Good: Scope Discipline

```
# Implementing FR-001: Display user name

Claude: Implementing FR-001 as specified.
Note: I noticed we might want avatar support in the future.
Should I add a placeholder requirement for the next iteration?
```
