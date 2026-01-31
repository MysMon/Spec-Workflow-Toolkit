---
description: "Respond to PR review comments - analyze feedback, implement changes, and reply systematically (Requires: GitHub CLI 'gh')"
argument-hint: "<PR number or URL>"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite
---

# /review-response - PR Review Response Workflow

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

A structured workflow to efficiently address PR review comments. Analyzes reviewer feedback, implements requested changes, and prepares responses.

## Design Principles

1. **Understand before acting**: Read all comments before making changes
2. **Batch related changes**: Group similar feedback to avoid conflicts
3. **Track responses**: Ensure every comment is addressed
4. **Preserve reviewer intent**: Ask if feedback is unclear

---

## When to Use

- Received review comments on a PR
- Need to address multiple reviewer feedback items
- Want systematic tracking of review responses
- Need to implement changes and reply to reviewers

## Input Formats

```bash
# PR number (requires gh CLI or MCP GitHub server)
/review-response 123

# PR URL (GitHub, GitLab, etc.)
/review-response <PR URL>

# Current branch's PR
/review-response
```

---

## Execution Instructions

### Phase 1: Gather Review Comments

**Goal:** Collect all review comments and categorize them.

**Fetch PR comments:**

**IMPORTANT: Validate PR number format before use:**
- PR number must be a positive integer (e.g., `123`, `4567`)
- Use `gh pr view` without number to get current branch's PR if unsure

```bash
# Using GitHub CLI (PR_NUMBER must be validated as numeric)
gh pr view "$PR_NUMBER" --comments
gh pr view "$PR_NUMBER" --json reviews,comments

# Get review comments on specific files
gh api "repos/{owner}/{repo}/pulls/${PR_NUMBER}/comments"
```

**If no PR number provided:**

```bash
# Find PR for current branch
gh pr view --json number,title,url
```

**Categorize comments:**

| Category | Description | Priority |
|----------|-------------|----------|
| **Required Changes** | "Must fix", blocking approval | High |
| **Suggestions** | "Consider", "Maybe", improvements | Medium |
| **Questions** | Clarification requests | Medium |
| **Nitpicks** | Style, naming, minor | Low |
| **Praise** | Positive feedback | N/A |

### Phase 2: Create Response Plan

**Goal:** Plan how to address each comment.

**Create TodoWrite list:**

```
For each comment:
1. File path and line number
2. Comment category
3. Planned action (implement/discuss/decline)
4. Estimated complexity
```

**Group related comments:**

```
Group by:
- Same file (batch changes)
- Same reviewer (maintain context)
- Same topic (consistent approach)
```

**Ask for prioritization if many comments:**

```
Question: "I found [N] review comments. How should I prioritize?"
Header: "Priority"
Options:
- "Required changes first" (Recommended)
- "By file (minimize conflicts)"
- "Quick wins first"
- "Let me choose specific items"
```

### Phase 3: Implement Changes

**Goal:** Make requested changes systematically.

**For each comment group:**

**Step 1: Understand the feedback**

```
Launch code-explorer agent to analyze:

Review comment: [comment text]
File: [file path]
Line: [line number]

Tasks:
1. Read the code being reviewed
2. Understand the reviewer's concern
3. Check if similar patterns exist elsewhere
4. Identify the best approach to address feedback

Thoroughness: quick
```

**Step 2: Implement the change**

**ALWAYS delegate implementation to appropriate specialist:**

```
Launch Task tool with appropriate specialist (model: haiku for simple changes):

- Code logic → backend-specialist or frontend-specialist
- Tests → qa-engineer
- Architecture concerns → code-architect

Prompt:
Address PR review comment.

Review comment: [comment text]
File: [file path]
Line: [line number]
Original code: [code snippet]
Similar patterns found: [from Step 1]

Implement the requested change following codebase patterns.
```

**Direct modification allowed ONLY for:**
- Single-line typo fixes in comments or strings
- Formatting-only changes (whitespace, indentation)

**Step 3: Mark as addressed**

Update TodoWrite after each change.

### Phase 4: Handle Discussions

**Goal:** Prepare responses for comments that need discussion.

**For questions from reviewers:**

```
Launch code-explorer to gather context:
- Why was this implementation chosen?
- What alternatives were considered?
- What are the tradeoffs?

Prepare a concise response explaining the reasoning.
```

**For suggestions you disagree with:**

1. Understand the reviewer's perspective
2. Prepare a respectful counterpoint with reasoning
3. Offer compromise if possible

**Ask user for discussion items:**

```
Question: "How should I respond to this suggestion?"
Header: "Response"
Options:
- "Implement as suggested"
- "Propose alternative: [brief description]"
- "Respectfully decline with reasoning"
- "Ask reviewer for clarification"
```

### Phase 5: Verification

**Goal:** Ensure all changes work together.

**CRITICAL: Delegate verification to qa-engineer agent (do NOT run tests directly in parent context):**

```
Launch qa-engineer agent:

Task: Verify PR review changes

Changed files:
[list of files modified in Phase 3]

Run:
1. Tests (npm test / pytest / go test / etc.)
2. Linting (npm run lint / eslint / etc.)
3. Build check (npm run build / etc.)

Output:
- Test results (PASS/FAIL)
- Lint results (PASS/FAIL)
- Build results (PASS/FAIL)
- Any failures with error details
```

Use the agent's output for verification results. Do NOT run test/lint/build commands directly in the parent context.

**Error Handling:**
If qa-engineer fails or times out:
1. Check agent's partial output for usable results
2. Retry once with simplified scope (tests only)
3. If retry fails, inform user and offer options:
   - "Retry verification"
   - "Skip automated verification (I'll verify manually)"
   - "Show me the commands to run manually"

**Check for conflicts (allowed in parent context - lightweight git state commands):**

```bash
# Ensure changes don't conflict
git status
git diff --stat
```

### Phase 6: Prepare Commit

**Goal:** Create a clean commit addressing the review.

**Commit message format:**

```
fix: address PR review feedback

- [Summary of change 1]
- [Summary of change 2]
- [Summary of change 3]

Addresses review comments from @reviewer
```

**Ask about commit:**

```
Question: "All changes are implemented. How should I proceed?"
Header: "Commit"
Options:
- "Commit all changes together"
- "Commit by category (separate commits)"
- "Show me the diff first"
- "I'll commit manually"
```

### Phase 7: Summary Report

**Goal:** Provide overview for review response.

```markdown
## Review Response Summary

### PR: #[number] - [title]

### Comments Addressed

| # | File | Comment | Action | Status |
|---|------|---------|--------|--------|
| 1 | `path/file.ts:45` | [summary] | Implemented | ✅ |
| 2 | `path/other.ts:12` | [summary] | Discussed | 💬 |
| 3 | `path/test.ts:78` | [summary] | Declined | ❌ |

### Changes Made

| File | Changes |
|------|---------|
| `path/file.ts` | [description] |

### Responses to Post

| Comment | Response |
|---------|----------|
| @reviewer on file.ts:45 | [your response] |

### Verification

- [ ] Tests pass
- [ ] Lint passes
- [ ] Build succeeds
- [ ] No regressions

### Next Steps

1. Push changes
2. Post responses to PR comments
3. Request re-review
```

---

## Comment Response Templates

### Implemented as Requested

```
Done! Updated [file] to [description of change].
```

### Implemented with Modification

```
Good catch! I've addressed this, though I went with [approach] because [reason]. Let me know if you'd prefer the original suggestion.
```

### Clarification Provided

```
The reason for this approach is [explanation]. We considered [alternative] but chose this because [tradeoff].

Happy to discuss further or change if you see issues with this approach.
```

### Respectful Decline

```
Thanks for the suggestion! I considered this but decided to keep the current approach because [reason].

[If applicable: I've opened an issue to track this as a potential future improvement: #XXX]
```

### Request for Clarification

```
Could you elaborate on this feedback? I want to make sure I understand what you're looking for.

Are you suggesting [interpretation A] or [interpretation B]?
```

---

## Rules (L1 - Hard)

- ALWAYS read all comments before implementing changes
- NEVER ignore or dismiss reviewer feedback without explanation
- NEVER push without verification
- ALWAYS verify changes don't break existing functionality

## Defaults (L2 - Soft)

- Track every comment, even if declining
- Prepare responses for discussion items
- Make a single commit for related changes (unless user prefers separate)
- Thank reviewers for their feedback

## Guidelines (L3)

- Consider batching by file to minimize conflicts
- Prefer implementing suggestions before discussing disagreements
- Consider asking for re-review after significant changes
