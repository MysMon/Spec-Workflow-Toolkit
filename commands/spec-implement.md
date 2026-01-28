---
description: "Implement a feature from an approved spec and design - builds, tests, and reviews code"
argument-hint: "[optional: spec file path or feature name]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task, TodoWrite, Skill
---

# /spec-implement - Specification-Based Implementation

Implement a feature from an approved specification and design document. This command handles the build phase: preparation, implementation, quality review, and summary.

## Prerequisites

Before running this command, you should have:
- A specification file (`docs/specs/[feature-name].md`) - produced by `/spec-plan`
- A design document (`docs/specs/[feature-name]-design.md`) - produced by `/spec-plan`
- Optionally: a review report (`docs/specs/[feature-name]-review.md`) - produced by `/spec-review`

If these don't exist, suggest running `/spec-plan` first.

## Attribution

Based on Anthropic's Initializer + Coding Agent pattern from Effective Harnesses for Long-Running Agents.

## Phase Overview

1. **Preparation** - Load spec, design, review state; validate consistency
2. **Implementation** - Build features one at a time with specialist agents
3. **Quality Review** - Parallel review agents validate the implementation
4. **Summary** - Document what was accomplished

## Execution Instructions

---

## ORCHESTRATOR-ONLY RULES (NON-NEGOTIABLE)

**YOU ARE THE ORCHESTRATOR. YOU DO NOT DO THE WORK YOURSELF.**

Load the `subagent-contract` skill for detailed orchestration protocols.

### Absolute Prohibitions

1. **Prefer delegating bulk Grep/Glob operations to `code-explorer`** - Use directly only for single targeted lookups
2. **NEVER read more than 3 files directly** - Delegate bulk reading to subagents
3. **NEVER implement code yourself** - Delegate to `frontend-specialist` or `backend-specialist`
4. **NEVER write tests yourself** - Delegate to `qa-engineer`
5. **NEVER do security analysis yourself** - Delegate to `security-auditor`

---

### Agent Selection

| Agent | Model | Use For |
|-------|-------|---------|
| `code-explorer` | Sonnet | Quick verification of codebase state |
| `code-architect` | Sonnet | Design clarification if needed |
| `frontend-specialist` | **inherit** | UI implementation |
| `backend-specialist` | **inherit** | API implementation |
| `qa-engineer` | Sonnet | Testing and quality review |
| `security-auditor` | Sonnet | Security review (read-only) |
| `verification-specialist` | Sonnet | Reference validation |

---

### Phase 1: Preparation

**Goal:** Load context, validate readiness, and check for consistency.

#### Locate Spec and Design

If `$ARGUMENTS` is provided:
- If it's a file path, read that spec file and look for corresponding design file
- If it's a feature name, search in `docs/specs/` for matching files

If no arguments:
- Check progress file for current project spec
- List available specs in `docs/specs/`
- Ask user which to implement

#### Validate Prerequisites

1. **Read the spec file** - Understand what to build
2. **Read the design file** - Understand how to build it
3. **Check for review report** - Note review verdict and unresolved issues
4. **Check progress file** - Determine if resuming or starting fresh

If spec or design is missing:
```
Missing prerequisite files for implementation.

Spec: [found/missing]
Design: [found/missing]

Recommended: Run /spec-plan first to create these files.
```

#### Review-Aware Handoff

Check the progress file for review status:

| Progress Phase | Meaning | Action |
|----------------|---------|--------|
| `plan-complete` | Review was skipped | Warn: "No review was run. Consider /spec-review first." Proceed if user confirms. |
| `review-complete` + APPROVED | Reviewed and approved | Proceed normally |
| `review-complete` + NEEDS REVISION | Reviewed with unresolved issues | Show unresolved issues. Ask: "Address these first, or proceed anyway?" |
| `review-complete` + REJECTED | Review rejected the spec | Strongly recommend: "The spec was rejected in review. Run /spec-plan to revise." |

If a review report file exists, read it and note any unresolved critical issues.

#### Initialize or Resume Progress

**If starting fresh (no implementation progress):**
Create `feature-list.json` from the design document's Build Sequence.

Update progress file:
- currentPhase: "impl-starting"
- currentTask: "Beginning implementation"

**If progress file shows implementation in progress:**
Resume from the last incomplete feature.

**IMPORTANT:** Wait for explicit user approval before starting implementation.

Ask user: "Ready to start implementation? This will modify files in your codebase."

---

### Phase 2: Implementation

**Goal:** Build the feature according to spec and design.

Load the `long-running-tasks` skill for the Initializer + Coding pattern.

#### CRITICAL: One Feature at a Time

1. Identify next incomplete feature from `feature-list.json`
2. Delegate implementation to specialist agent
3. Wait for completion
4. Run tests (delegate to `qa-engineer`)
5. Update progress files (`claude-progress.json`, `feature-list.json`)
6. Commit working code with descriptive message
7. Move to next feature

**NEVER proceed to next feature until current one is:**
- Implemented
- Tested
- Committed
- Progress files updated

#### Implementation Pattern Selection

| Condition | Pattern | Workflow |
|-----------|---------|----------|
| Clear acceptance criteria | **TDD** | qa-engineer writes failing tests → Specialist implements → Refactor |
| Exploratory, UI-heavy | **Standard** | Specialist implements → qa-engineer validates → Iterate |
| Bug fix with reproduction steps | **TDD** | qa-engineer writes failing test → Specialist fixes |

**TDD Pattern** (Load `tdd-workflow` skill):
- RED: `qa-engineer` writes failing tests based on acceptance criteria
- GREEN: Specialist implements minimal code to pass
- REFACTOR: Review and clean up

**Standard Pattern**:
- Specialist implements feature
- `qa-engineer` validates and writes tests
- Iterate on feedback

#### Delegation to Specialist Agents

Note: `frontend-specialist` and `backend-specialist` use `model: inherit`, so they use whatever model the user's session is running.

For frontend work:
```
Launch the frontend-specialist agent to implement: [component/feature]
Following specification: docs/specs/[feature-name].md
Following design: docs/specs/[feature-name]-design.md
Key files from design: [Implementation Map entries]
TDD mode: [yes/no] - If yes, reference test file
Expected output: Working component with tests
```

For backend work:
```
Launch the backend-specialist agent to implement: [service/API]
Following specification: docs/specs/[feature-name].md
Following design: docs/specs/[feature-name]-design.md
Key files from design: [Implementation Map entries]
TDD mode: [yes/no] - If yes, reference test file
Expected output: Working service with tests
```

**After each specialist agent completes:**
1. Verify the agent's output summary
2. Note the agent ID for potential resume
3. Update `feature-list.json` (mark feature as completed)
4. Update `claude-progress.json` (update currentTask, nextAction)
5. Run TodoWrite to update visible progress
6. Ask user if they want to review before committing

#### Subagent Resume for Iterative Work

| Scenario | Action |
|----------|--------|
| Expanding scope of same feature | Resume |
| Permission error recovery | Resume in foreground |
| Completely different feature | New agent |
| Agent hit context limit | New agent with summary |

#### Handling Spec-Reality Divergence

During implementation, the specialist agent or you may discover that the spec/design doesn't match reality (e.g., an API doesn't exist as assumed, a pattern works differently than expected).

**If divergence is minor** (implementation detail, not spec-level):
- Adapt implementation and note the deviation
- Add to progress log: `"deviation": "Adapted X because Y"`

**If divergence is significant** (contradicts spec requirements):
1. Stop implementation of the current feature
2. Present the issue to the user:
   ```
   Implementation discovered a spec-reality mismatch:

   Spec says: [what the spec assumes]
   Reality: [what was actually found]
   Impact: [how this affects the plan]

   Options:
   1. Adapt the design → I'll adjust the approach for this feature only
   2. Update spec and design → Pause implementation, update documents
   3. Go back to planning → Re-run /spec-plan with new knowledge
   ```
3. Proceed based on user's choice

---

### Phase 3: Quality Review

**Goal:** Ensure code meets quality, security, and spec requirements.

**LAUNCH 4 PARALLEL REVIEW AGENTS (Sonnet):**

```
Launch these review agents in parallel:

1. qa-engineer agent
   Focus: Test coverage, edge cases, acceptance criteria
   Confidence threshold: 80
   Output: Test gaps, quality issues with file:line

2. security-auditor agent
   Focus: OWASP Top 10, auth/authz, data validation
   Confidence threshold: 80
   Output: Vulnerabilities with file:line and remediation

3. code-explorer agent (verification)
   Focus: Verify implementation matches design spec
   Thoroughness: quick
   Compare: Implementation vs docs/specs/[feature]-design.md
   Output: Deviations, missing pieces with file:line

4. verification-specialist agent
   Focus: Validate file:line references from other agents
   Task: Cross-check findings for accuracy
   Output: Verification report with VERIFIED/PARTIAL/UNVERIFIED status
```

**Wait for all agents to complete.**

**Error Handling:**
If any agent fails or times out:
1. Check the agent's partial output for usable findings
2. If critical agent failed (e.g., security-auditor), retry once with reduced scope
3. If retry fails, proceed with available results and document the gap
4. Add to progress file: `"warnings": ["Agent X failed, results may be incomplete"]`

#### Cross-Validation of File References

Review the verification-specialist's report before scoring:

| Verification Status | Action |
|---------------------|--------|
| VERIFIED | Keep finding as-is |
| PARTIAL | Reduce confidence by 10 |
| UNVERIFIED | Reduce confidence by 20, flag as `"verified": false` |

**Consolidate findings with confidence weighting:**

| Scenario | Action |
|----------|--------|
| Score < 80 | Filter out |
| 1 agent reports (80+) | Report as-is |
| 2 agents agree | Boost confidence |
| 3 agents agree | Treat as confirmed |

**Present findings to user:**
```markdown
## Quality Review Results

### Critical Issues (Confidence >= 90)
1. **[Issue Title]** - [Category] (Score: [N], Verified: [Yes/No])
   File: `file:line`
   **Fix:** [Remediation]

### Important Issues (Confidence 80-89)
...

### Summary
- Critical: [N]
- Important: [N]
- Filtered (below 80): [N]

**Verdict:** [APPROVED / NEEDS CHANGES]
```

**Ask user:** "Found [N] issues. What would you like to do?"
1. Fix critical issues now
2. Fix all issues now
3. Proceed without changes
4. Get more details on specific issues

#### Evaluator-Optimizer Loop (For Critical Issues)

If critical issues are found and user chooses to fix:

```
Iteration Loop (max 3):

1. GENERATOR: Delegate fix to specialist agent
2. EVALUATOR: Delegate re-check to original reviewer
3. If score >= 80: Accept. If < 80: Loop. If max reached: Escalate to user.
```

See `skills/workflows/evaluator-optimizer/SKILL.md` for detailed pattern.

**Progress Update:**
Update `claude-progress.json`:
- currentPhase: "impl-review-complete"
- resumptionContext.nextAction: "Proceed to Summary"

---

### Phase 4: Summary

**Goal:** Document what was accomplished.

**Update progress file to completed status.**

```markdown
## Implementation Complete

### What Was Built
- [Feature description]

### Key Decisions
- [Decision 1]: [Rationale]

### Deviations from Design
- [Deviation 1]: [Why and what was adapted]

### Files Modified
| File | Changes |
|------|---------|
| `path/to/file.ts` | [Summary] |

### Quality Status
- Tests: [Passing/Failing]
- Security: [Approved/Issues]
- Coverage: [Percentage]

### Next Steps
1. [Suggested follow-up 1]
2. [Suggested follow-up 2]
```

**Mark all todos complete.**

## Usage Examples

```bash
# Implement from spec file
/spec-implement docs/specs/user-authentication.md

# Implement by feature name
/spec-implement user-authentication

# Resume implementation (auto-detects from progress file)
/spec-implement
```

## When NOT to Use

- No spec or design exists (run `/spec-plan` first)
- Single-line bug fixes (just fix it directly)
- Trivial changes (use `/quick-impl`)
- Urgent hotfixes (use `/hotfix`)
