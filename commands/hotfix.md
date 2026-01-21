---
description: "Rapid emergency fix workflow for production issues - minimal process, maximum safety"
argument-hint: "[issue description or ticket reference]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task, TodoWrite
---

# /hotfix - Emergency Production Fix

A streamlined workflow for urgent production issues that balances speed with safety. Bypasses full SDD workflow while maintaining critical safety checks.

## Purpose

Production issues require immediate attention. This command provides:

1. **Speed** - Minimal process overhead
2. **Safety** - Essential checks preserved (security, tests)
3. **Traceability** - Clear documentation of what changed and why
4. **Rollback readiness** - Easy to revert if needed

## When to Use

- Production bug affecting users NOW
- Critical security vulnerability discovered
- Service outage requiring immediate code fix
- Data corruption that needs urgent patching

## When NOT to Use

- Non-urgent bugs (use `/quick-impl` or `/sdd`)
- Feature development (use `/sdd`)
- Refactoring (use `/sdd`)
- CI failures (use `/ci-fix`)

---

## Rules (L1 - Hard)

**These rules apply even in emergencies:**

- NEVER skip security validation for auth/data handling code
- NEVER commit secrets or credentials
- ALWAYS create a hotfix branch (never commit directly to main/production)
- ALWAYS run existing tests before pushing
- ALWAYS document what was changed and why

---

## Execution Instructions

### Phase 1: Rapid Assessment (2-3 minutes)

**Goal:** Understand the issue quickly without deep analysis.

**Gather essential info:**

```
Question: "What's the production issue?"
Header: "Issue"
Options:
- "Users seeing errors"
- "Feature not working"
- "Security issue"
- "Performance degradation"
```

**Get specifics:**
- Error message or symptoms
- Affected users/scope
- When it started
- Any recent deployments

**Quick context check:**

```bash
# Recent deployments
git log --oneline -5 --date=short

# Current production branch
git branch -r | grep -E "(main|master|production|release)"
```

### Phase 2: Create Hotfix Branch (30 seconds)

**Goal:** Isolate changes for safe deployment and easy rollback.

```bash
# Ensure we're on the production branch
git fetch origin
git checkout main  # or master/production

# Create hotfix branch
git checkout -b hotfix/[brief-description]-$(date +%Y%m%d)
```

**Branch naming:** `hotfix/[issue-id]-[brief-description]`

Examples:
- `hotfix/fix-login-500-20250120`
- `hotfix/SEC-123-xss-patch`
- `hotfix/payment-timeout-fix`

### Phase 3: Locate and Fix (5-10 minutes)

**Goal:** Find the issue and implement minimal fix.

**Quick search strategy:**

```
1. If error message known:
   Grep for error message in codebase

2. If feature broken:
   Trace from entry point (API route, UI component)

3. If performance issue:
   Check recent changes to affected code path
```

**Use Task tool with subagent_type=Explore for rapid search:**

```
Launch Task tool with subagent_type=Explore:
- Find the specific file/function causing the issue
- Return file:line reference
```

**Implement MINIMAL fix:**

| Principle | Explanation |
|-----------|-------------|
| **Smallest change** | Fix only what's broken, nothing more |
| **No refactoring** | Resist urge to clean up nearby code |
| **No new features** | Even if "while we're here..." |
| **Preserve behavior** | Match existing patterns exactly |

**Fix the issue directly** (no subagent delegation for hotfixes - speed is priority):

```
Read the problematic file
Implement the minimal fix
```

### Phase 4: Safety Verification (2-3 minutes)

**Goal:** Ensure fix doesn't break anything else.

**Mandatory checks:**

```bash
# 1. Run tests (required)
npm test
# or
pytest

# 2. Run linter (if quick)
npm run lint
# or skip if > 30 seconds

# 3. Type check (if quick)
npm run typecheck
# or skip if > 30 seconds
```

**Security check (L1 - NEVER skip for auth/data code):**

```
If fix touches authentication, authorization, or data handling:
- Delegate quick security review to security-auditor
- Focus only on the changed code
- Must pass before proceeding
```

**If tests fail:**
- Fix the test if it's testing the bug (bug was "correct" behavior)
- Fix the code if test reveals new issue
- Do NOT skip failing tests

### Phase 5: Document and Commit (1-2 minutes)

**Goal:** Create traceable commit for audit and rollback.

**Commit message format:**

```bash
git add [changed-files]
git commit -m "$(cat <<'EOF'
hotfix: [brief description]

Issue: [ticket/description]
Root cause: [one line explanation]
Fix: [one line explanation]

Affected: [list affected functionality]
Tested: [how it was verified]
Rollback: git revert [this-commit-sha]
EOF
)"
```

**Example:**

```
hotfix: fix login 500 error for users with special chars in email

Issue: Users with + in email getting 500 on login
Root cause: URL encoding not applied before API call
Fix: Added encodeURIComponent to email parameter

Affected: Login flow only
Tested: Manual test with test+user@example.com, unit tests pass
Rollback: git revert abc123
```

### Phase 6: Push and Deploy

**Goal:** Get fix to production quickly.

**Push hotfix branch:**

```bash
git push -u origin hotfix/[branch-name]
```

**Deployment options:**

| Method | When to Use |
|--------|-------------|
| **Merge to main, auto-deploy** | Standard CI/CD in place |
| **Direct deploy from branch** | Emergency override available |
| **Cherry-pick to release** | Release branch workflow |

**Ask user:**

```
Question: "Fix is ready. How do you want to deploy?"
Header: "Deploy"
Options:
- "Create PR to main" (Recommended)
- "I'll deploy manually"
- "Show me deployment commands"
```

### Phase 7: Post-Hotfix

**Goal:** Ensure fix is tracked and followed up.

**Create summary:**

```markdown
## Hotfix Complete

### Issue
[Brief description]

### Fix Applied
| File | Change |
|------|--------|
| `src/api/auth.ts:45` | Added URL encoding |

### Verification
- [x] Tests pass
- [x] Security check (if applicable)
- [x] Manual verification

### Deployment
- Branch: `hotfix/[name]`
- PR: [link if created]

### Follow-up Required
- [ ] Add regression test for this case
- [ ] Review if root cause indicates larger issue
- [ ] Update monitoring/alerting if needed
```

**Suggest follow-up:**

```
The hotfix is deployed. Recommended follow-up:
1. Monitor for recurrence
2. Create proper regression test (use /sdd if substantial)
3. Root cause analysis if pattern issue
```

---

## Hotfix Checklist

Quick reference during emergency:

```
[ ] 1. Understand issue (2-3 min)
[ ] 2. Create hotfix branch
[ ] 3. Find and fix (minimal change)
[ ] 4. Run tests (REQUIRED)
[ ] 5. Security check (if auth/data)
[ ] 6. Commit with full context
[ ] 7. Push and deploy
[ ] 8. Document for follow-up
```

---

## Rollback Procedure

If hotfix causes new issues:

```bash
# Option 1: Revert the commit
git revert [hotfix-commit-sha]
git push

# Option 2: Deploy previous version
git checkout main
git reset --hard [pre-hotfix-sha]
git push --force  # DANGER: coordinate with team

# Option 3: Cherry-pick revert to release
git checkout release
git cherry-pick -n [revert-commit]
git push
```

---

## Time Budget

Target total time: **15-20 minutes**

| Phase | Target | Max |
|-------|--------|-----|
| Assessment | 2-3 min | 5 min |
| Branch setup | 30 sec | 1 min |
| Find and fix | 5-10 min | 15 min |
| Verification | 2-3 min | 5 min |
| Commit/push | 1-2 min | 3 min |

**If exceeding 30 minutes:** The issue may be more complex than a hotfix. Consider:
- Temporary mitigation (feature flag, rollback)
- Escalate to `/sdd` for proper fix

---

## Comparison with Other Commands

| Aspect | /hotfix | /quick-impl | /sdd |
|--------|---------|-------------|------|
| **Speed** | Fastest | Fast | Thorough |
| **Process** | Minimal | Light | Full 7-phase |
| **Exploration** | Quick only | Light | Parallel agents |
| **Testing** | Required | Expected | Comprehensive |
| **Documentation** | Commit message | Light | Full spec |
| **Best for** | Emergencies | Small tasks | Features |
