---
description: "Quick implementation for well-defined, small tasks that don't need full SDD workflow"
argument-hint: "<task description>"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, TodoWrite
---

# /quick-impl - Quick Implementation

For small, well-defined tasks that don't require the full SDD workflow. Use when:
- Task is clearly defined (not vague)
- Scope is small (1-3 files)
- No architectural decisions needed
- Risk is low

## Guardrails

Even quick implementations follow core principles:

1. **Understand before coding** - Read related files first
2. **Test your changes** - Run existing tests, add if needed
3. **Security check** - No secrets, no vulnerabilities
4. **Quality check** - Lint/format after changes

## Execution Instructions

### Step 1: Validate Scope

Check if this is actually a quick task:

**Proceed if:**
- [ ] Task is clearly defined in `$ARGUMENTS`
- [ ] Affects 3 or fewer files
- [ ] No database schema changes
- [ ] No API contract changes
- [ ] No security-sensitive code

**Escalate to /sdd if:**
- Task is vague or ambiguous
- Multiple components affected
- Architectural decisions needed
- Security implications

### Step 2: Context Gathering

Before implementing:

1. **Detect stack** (via Task tool with subagent_type=Explore, or read config files like package.json, pyproject.toml)
2. **Read related files** - Understand existing code
3. **Check for tests** - Know what to update

```
Launch Task tool with subagent_type=Explore (quick mode) to find:
- Files related to [task]
- Existing patterns for similar functionality
- Test files to update
```

### Step 3: Implementation

**IMPORTANT:** For anything beyond trivial changes, delegate to specialist:

```
Launch [frontend-specialist|backend-specialist] agent to implement:
[Task description]

Context:
- Related files: [list]
- Existing patterns: [summary]
- Test file: [path]
```

**Trivial Change Definition** (all criteria must be met):
- ≤10 lines of code changed
- Single logical change (not multiple unrelated fixes)
- No new functions, classes, or modules
- No changes to public APIs or interfaces
- Examples: typos, config values, import additions, simple string changes

For trivial changes meeting ALL criteria above:
- Make the change directly
- Run linter/formatter
- Run tests

### Step 4: Verification

Quick verification checklist:

```bash
# Run linters (auto-detected)
# Run tests
npm test  # or pytest, go test, cargo test, etc.

# Check for secrets
# (automatic via prevent_secret_leak hook)
```

### Step 5: Summary

Brief summary:
- What was changed
- Files modified
- Tests status
- Any follow-up needed

## Usage Examples

```bash
# Fix a typo
/quick-impl Fix typo in README.md - "recieve" should be "receive"

# Add a config value
/quick-impl Add CACHE_TTL environment variable with default 3600

# Simple refactor
/quick-impl Rename getUserById to findUserById across the codebase

# Add a simple utility
/quick-impl Add formatCurrency utility function that formats numbers as USD
```

## Escalation Triggers

If during implementation you discover:
- Scope is larger than expected
- Architectural questions arise
- Security concerns emerge
- Requirements are unclear

**STOP and inform the user:**

```
This task is more complex than initially expected because [reason].

Recommend switching to /sdd workflow for proper specification.

Would you like to:
1. Continue with /sdd workflow
2. Proceed anyway (at your own risk)
3. Abandon and reassess
```

## Comparison with /sdd

| Aspect | /quick-impl | /sdd |
|--------|-------------|------|
| When | Clear, small tasks | Vague or complex features |
| Phases | 1 (implement) | 6 (full workflow) |
| Spec | Not required | Required |
| Review | Basic checks | Full parallel review |
| Time | Minutes | Hours to days |
| Risk | Low scope only | Any complexity |
