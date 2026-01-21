---
description: "Review code changes using 5 parallel specialized agents with confidence-based scoring and filtering"
argument-hint: "[file path, directory, PR #, or 'staged' for git staged changes]"
allowed-tools: Read, Glob, Grep, Bash, Task, AskUserQuestion
---

# /code-review - Parallel Code Review

Launch 5 specialized agents in parallel (CLAUDE.md Compliance, Bug Scan, Git History, PR Comments, Code Comments) to comprehensively review code changes, then score each issue with Haiku agents for confidence-based filtering.

Based on the official code-review plugin pattern.

## Overview

This command implements an 8-step workflow:

1. **Eligibility Check** (Haiku) - Verify PR is reviewable
2. **CLAUDE.md Discovery** (Haiku) - Find all guideline files
3. **Change Summary** (Haiku) - Summarize PR changes
4. **Parallel Review** (5 agents: Compliance, Bug Scan, Git History, PR Comments, Code Comments) - Analyze from different perspectives
5. **Confidence Scoring** (N Haiku agents) - Score each issue found
6. **Filtering** - Remove issues below 80% confidence
7. **Re-check Eligibility** (Haiku) - Verify before posting
8. **Report** - Post findings with GitHub links

## Confidence Scoring Rubric

Each issue must be scored on this scale:

| Score | Meaning | When to Use |
|-------|---------|-------------|
| **0** | Not confident at all | False positive, pre-existing issue, or unstated preference |
| **25** | Somewhat confident | Might be real but unverified |
| **50** | Moderately confident | Real issue but minor/infrequent occurrence |
| **75** | Highly confident | Verified real, happens in practice, significant impact |
| **100** | Absolutely certain | Definitely real, frequently occurring, directly verifiable |

**Default Threshold:** 80 (only reports issues with score >= 80)

### CLAUDE.md Issue Verification

For issues flagged due to CLAUDE.md:
- Double-check that CLAUDE.md **explicitly** calls out that issue
- Score low if the guideline is vague or doesn't directly apply

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

### Step 3: Launch 5 Parallel Review Agents (Sonnet)

**CRITICAL: Launch all 5 agents in a single message with 5 separate Task tool calls.**

To achieve true parallelism, invoke multiple Task tools in a single response:
```
<parallel-execution>
Task tool call 1: Agent 1 (CLAUDE.md Compliance)
Task tool call 2: Agent 2 (Bug Scan)
Task tool call 3: Agent 3 (Git History)
Task tool call 4: Agent 4 (PR Comments)
Task tool call 5: Agent 5 (Code Comments)
</parallel-execution>
```

Each Task should use `subagent_type: general-purpose` with `model: inherit` (or omit to use the agent's default model).

**Agent 1: CLAUDE.md Compliance Audit**
```
Review code for CLAUDE.md guideline compliance.

CLAUDE.md files:
[List of CLAUDE.md paths and content]

Changes to review:
[diff content]

For each violation found, return:
- Guideline violated (quote the specific rule)
- Code location (file:line)
- Brief description
```

**Agent 2: Shallow Bug Scan**
```
Review code for obvious bugs in the changed code ONLY.

Changes to review:
[diff content]

Focus ONLY on bugs introduced in this change, not pre-existing issues.

Look for:
- Logic errors, off-by-one errors
- Null/undefined handling issues
- Race conditions, resource leaks
- Incorrect error handling

For each bug:
- Bug description
- Code location (file:line)
```

**Agent 3: Git History Context Analysis**
```
Analyze git blame and history for contextual issues.

Changed files:
[list of files]

Run git blame on changed lines.
Check recent commit history for these files.

For each issue:
- Issue description
- Code location (file:line)
- Historical context (why this might be problematic)
```

**Agent 4: Related PR Comments Review**
```
Check for comments or discussions from related PRs.

Changed files:
[list of files]

Look for any existing review comments or discussions
that might apply to this code.

For each relevant finding:
- Finding description
- Code location (file:line)
- Reference to previous discussion
```

**Agent 5: Code Comments Alignment**
```
Verify code behavior matches inline comments.

Changes to review:
[diff content]

Check that:
- Comments accurately describe the code
- TODOs are addressed or still relevant
- No misleading comments

For each misalignment:
- Issue description
- Code location (file:line)
```

### Step 4: Score Each Issue with Haiku Agents

**For each issue found in Step 3, launch a parallel Haiku agent** to score confidence.

```
Launch N parallel Haiku agents (one per issue):

For each issue:
- PR context: [PR summary]
- Issue description: [from step 3]
- CLAUDE.md files: [list of guideline files]

Score this issue 0-100 based on the rubric.
For CLAUDE.md issues, verify the guideline explicitly mentions this.
```

### Step 5: Filter and De-duplicate Issues

**Remove issues with score < 80.**

**De-duplication Strategy:**
- **Same file:line + same category** → Keep highest confidence, merge descriptions
- **Same file:line + different categories** → Keep both (e.g., bug AND CLAUDE.md violation)
- **Multiple agents flag same issue** → Boost confidence by 10 (max 100)
- **Overlapping line ranges** → If >50% overlap and same category, merge

**Auto-filtered (do not report):**
- Pre-existing issues not in this change
- Issues linters/type checkers will catch
- Pedantic nitpicks
- Code with lint-ignore comments
- General code quality issues not in CLAUDE.md
- Issues where user didn't modify those lines
- Intentional functionality changes

### Step 6: Re-check Eligibility

Before presenting, verify:
- PR is still open (not closed or merged)
- No new commits since analysis started
- Issues are still relevant

### Step 7: Present Review

**For PR reviews (posting to GitHub):**

```markdown
## Code review

Found [N] issues:

1. [Brief description] (CLAUDE.md says "[quote guideline]")

https://github.com/owner/repo/blob/[full-SHA]/path/file.ext#L[start]-L[end]

2. [Brief description] (bug due to [explanation])

https://github.com/owner/repo/blob/[full-SHA]/path/file.ext#L[start]-L[end]

🤖 Generated with Claude Code
```

**Link Format Requirements:**
- Use full SHA (not shortened)
- Use `#L` notation for line references
- Include at least 1 line of context around the issue

**For local reviews:**

```markdown
## Code Review

Reviewed [N] files with [M] lines changed.

### Critical Issues (Confidence >= 90)

1. **[Issue Title]** - [Category] (Score: [N])

   File: `src/auth.ts:67-72`

   [Description of the issue]

   **Fix:** [Suggested fix]

### Important Issues (Confidence 80-89)

...

### Summary

- Critical: [N]
- Important: [N]
- Filtered (below threshold): [N]

**Verdict:** [APPROVED / NEEDS CHANGES]
```

### Step 8: User Action

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
