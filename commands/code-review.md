---
description: "Review code changes using multiple specialized agents in parallel with confidence-based filtering"
argument-hint: "[file path, directory, or 'staged' for git staged changes]"
allowed-tools: Read, Glob, Grep, Bash, Task, AskUserQuestion
---

# /code-review - Parallel Code Review

Launch multiple specialized agents in parallel to comprehensively review code changes before committing or merging.

## Overview

This command uses 4 parallel agents to review code from different perspectives:
1. **CLAUDE.md Compliance** - Checks adherence to project guidelines
2. **Bug Detection** - Finds potential bugs and logic errors
3. **Security Analysis** - Identifies security vulnerabilities
4. **Code Quality** - Reviews maintainability and best practices

## Confidence Scoring System

```
0   - Not confident, likely false positive
25  - Somewhat confident, might be real
50  - Moderately confident, real but minor
75  - Highly confident, real and important
100 - Absolutely certain, definitely real
```

**Default Threshold:** 80 (only reports issues >= 80 confidence)

## Execution Instructions

### Step 1: Identify Changes to Review

Based on `$ARGUMENTS`:

**If "staged" or empty:**
```bash
git diff --staged --name-only
git diff --staged
```

**If file path:**
```bash
git diff HEAD -- [file]
# or if not in git, just read the file
```

**If directory:**
```bash
git diff HEAD -- [directory]
```

**If PR number (e.g., "#123"):**
```bash
gh pr diff 123
```

### Step 2: Gather Context

Before launching agents, gather:
1. **CLAUDE.md contents** - Project guidelines
2. **Related files** - Files that interact with changed code
3. **Recent history** - Why these files were changed recently

```bash
# Find CLAUDE.md files
find . -name "CLAUDE.md" -o -name ".claude/rules/*.md"

# Get git blame for changed lines
git blame [files]

# Get recent commits touching these files
git log --oneline -10 -- [files]
```

### Step 3: Launch Parallel Review Agents

**CRITICAL: Launch all 4 agents in a single Task tool call.**

**Agent 1: CLAUDE.md Compliance**
```
Review code for CLAUDE.md guideline compliance.

Guidelines:
[CLAUDE.md content]

Changes to review:
[diff content]

For each violation:
- Guideline violated
- Code location (file:line)
- Confidence (0-100)
- How to fix
```

**Agent 2: Bug Detection**
```
Review code for potential bugs.

Changes to review:
[diff content]

Focus ONLY on bugs introduced in this change, not pre-existing issues.

Look for:
- Logic errors
- Off-by-one errors
- Null/undefined handling
- Race conditions
- Resource leaks
- Incorrect error handling

For each bug:
- Bug description
- Code location (file:line)
- Confidence (0-100)
- Suggested fix
```

**Agent 3: Security Analysis**
```
Review code for security vulnerabilities.

Changes to review:
[diff content]

Check for OWASP Top 10:
- Injection (SQL, command, XSS)
- Broken authentication
- Sensitive data exposure
- XXE
- Broken access control
- Security misconfiguration
- Insecure deserialization
- Known vulnerable components
- Insufficient logging

For each vulnerability:
- Vulnerability type
- Code location (file:line)
- Confidence (0-100)
- Remediation
```

**Agent 4: Code Quality**
```
Review code for quality and maintainability.

Changes to review:
[diff content]

Check for:
- DRY violations
- Complex functions (high cyclomatic complexity)
- Missing error handling
- Poor naming
- Missing or incorrect types
- Dead code
- Performance issues

For each issue:
- Issue description
- Code location (file:line)
- Confidence (0-100)
- Improvement suggestion
```

### Step 4: Score and Filter Issues

For each issue found:
1. **Verify it's in the changed code** - Not pre-existing
2. **Check confidence score** - Filter below threshold
3. **Remove duplicates** - Same issue found by multiple agents
4. **Filter out linter issues** - Tools will catch these

**Auto-filtered (do not report):**
- Pre-existing issues not in this change
- Issues linters will catch
- Pedantic nitpicks
- Code with ignore comments

### Step 5: Present Review

```markdown
## Code Review

Reviewed [N] files with [M] lines changed.

### Critical Issues (Confidence >= 90)

1. **[Issue Title]** - [Category]

   File: `src/auth.ts` lines 67-72

   [Description of the issue]

   ```typescript
   // Problematic code
   ```

   **Fix:**
   ```typescript
   // Suggested fix
   ```

### Important Issues (Confidence 80-89)

...

### Summary

- Critical: [N]
- Important: [N]
- Filtered (below threshold): [N]

**Verdict:** [APPROVED / NEEDS CHANGES]
```

### Step 6: User Action

Ask user:
```
Review complete. What would you like to do?
1. Fix critical issues now
2. Fix all issues now
3. Proceed without changes
4. Get more details on specific issues
```

## Usage Examples

```bash
# Review staged changes
/code-review staged
/code-review

# Review specific file
/code-review src/auth/login.ts

# Review directory
/code-review src/components/

# Review PR
/code-review #123
```

## Configuration

### Adjust Confidence Threshold

In your request:
```
/code-review staged --threshold 60
```

### Focus Mode

```
/code-review staged --focus security
/code-review staged --focus bugs
```

## Integration with Git

After review, if approved:
```bash
# Stage and commit with review reference
git add .
git commit -m "feat: implement feature X

Code review completed:
- Security: Passed
- Quality: Passed
- Compliance: Passed"
```

## Comparison with /spec-review

| Aspect | /spec-review | /code-review |
|--------|--------------|--------------|
| When | Before implementation | After implementation |
| What | Specification documents | Code changes |
| Focus | Completeness, feasibility | Bugs, security, quality |
| Output | Spec improvements | Code fixes |
