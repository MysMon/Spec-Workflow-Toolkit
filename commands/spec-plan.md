---
description: "Plan a feature with spec-first methodology - discovery, exploration, clarification, and architecture design with iterative refinement"
argument-hint: "[optional: feature description]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task, TodoWrite, Skill
---

# /spec-plan - Specification-First Planning

Plan a feature through 4 phases with iterative refinement at each gate. Produces a specification and design document ready for `/spec-review` and `/spec-implement`.

## Attribution

Based on official feature-dev plugin, Claude Code Best Practices, Effective Harnesses for Long-Running Agents, and Building Effective Agents (6 Composable Patterns).

## Why Separate Planning from Implementation?

Anthropic's "Effective Harnesses for Long-Running Agents" found that agents "fall short when attempting to one-shot" complex work. The solution: an **Initializer** (planning) phase separate from incremental **Coding** sessions.

Benefits:
- Full context window available for planning (no implementation artifacts consuming tokens)
- Natural checkpoint for human review before costly implementation
- `/spec-review` can validate the plan between planning and implementation
- Claude Code creator's workflow: "Plan Mode → refine plan → Auto-Accept for implementation"

## Phase Overview

1. **Discovery** - Understand what needs to be built
2. **Codebase Exploration** - Understand existing code and patterns (parallel agents)
3. **Specification Drafting** - Fill gaps, resolve ambiguities, draft and refine spec
4. **Architecture Design** - Analyze from multiple angles, synthesize and refine one approach

Each phase with user interaction includes a **refinement loop** — not just approve/reject, but iterative revision based on user feedback.

## Execution Instructions

---

## ORCHESTRATOR-ONLY RULES (NON-NEGOTIABLE)

**YOU ARE THE ORCHESTRATOR. YOU DO NOT DO THE WORK YOURSELF.**

Load the `subagent-contract` skill for detailed orchestration protocols.

### Absolute Prohibitions

1. **MUST delegate bulk Grep/Glob operations to `code-explorer`** - Use directly only for single targeted lookups
2. **NEVER read more than 3 files directly** - Delegate bulk reading to subagents
3. **NEVER implement code yourself** - This is a planning command
4. **NEVER skip to implementation** - Output is a plan, not code

### Your ONLY Responsibilities

1. **Orchestrate** - Launch and coordinate subagents
2. **Synthesize** - Combine subagent outputs into coherent summaries
3. **Communicate** - Present findings and ask user questions
4. **Track Progress** - Update TodoWrite and progress files
5. **Read Specific Files** - Only files identified by subagents (max 3 at a time)

---

### Agent Selection

| Agent | Model | Use For |
|-------|-------|---------|
| `code-explorer` | Sonnet | Deep codebase analysis (4-phase exploration) |
| Built-in `Explore` | Haiku | Quick lookups and simple searches |
| `code-architect` | Sonnet | Feature-level implementation blueprints |
| `product-manager` | Sonnet | Specification drafting |
| `verification-specialist` | Sonnet | Reference validation |

---

### Phase 1: Discovery

**Goal:** Understand what needs to be built and why.

#### CRITICAL: Check for Existing Progress (L1 - MUST DO FIRST)

**Before creating new progress files, check if work already exists for this project.**

1. **Check for existing progress file:**
   - Generate workspace ID: `{branch}_{path-hash}` (from SessionStart hook context)
   - Look for `.claude/workspaces/{workspace-id}/claude-progress.json`

2. **If progress file exists and status is NOT "completed":**
   ```
   EXISTING PROGRESS DETECTED

   Project: [project name from progress file]
   Current Phase: [currentPhase from progress file]
   Last Activity: [lastUpdated from progress file]
   Status: [status from progress file]

   Options:
   1. Continue existing work → Use /resume command
   2. Start fresh → Existing progress will be archived to .claude/workspaces/{id}/archived/
   3. Cancel → Do nothing

   What would you like to do?
   ```

3. **If user chooses "Start fresh":**
   - Archive existing progress: Move `claude-progress.json` to `archived/claude-progress-{timestamp}.json`
   - Archive feature list if exists: Move `feature-list.json` to `archived/feature-list-{timestamp}.json`
   - Proceed to create new progress files

4. **If progress file doesn't exist or status is "completed":**
   - Proceed directly to Progress File Initialization

#### CRITICAL: Progress File Initialization (L1 - MUST DO AFTER CHECK)

**NEVER skip this step. The progress file MUST be created before ANY other Phase 1 work.**

1. **Generate workspace ID**: Use format `{branch}_{path-hash}` (from SessionStart hook context)
2. **Create directory**: `.claude/workspaces/{workspace-id}/`
3. **Create progress file**: `.claude/workspaces/{workspace-id}/claude-progress.json`

**Initial progress file structure:**
```json
{
  "workspaceId": "{generated-workspace-id}",
  "project": "{project-name}",
  "started": "{ISO-8601-timestamp}",
  "lastUpdated": "{ISO-8601-timestamp}",
  "status": "in_progress",
  "currentPhase": "plan-discovery",
  "currentTask": "Discovery - gathering requirements",
  "sessions": [],
  "log": [],
  "resumptionContext": {
    "position": "Phase 1: Discovery",
    "nextAction": "Complete requirements gathering and user interview",
    "dependencies": [],
    "blockers": []
  }
}
```

**Verification:** After creating, read the file back to confirm it was written correctly.

#### Discovery Work

If the user provided a feature description (`$ARGUMENTS`), analyze it first:
- What problem is being solved?
- Who are the target users?
- What are potential constraints?

**CRITICAL: Use AskUserQuestion when request is vague or ambiguous.**

If the request is vague or missing:
1. **MUST use AskUserQuestion** to clarify:
   - What problem is being solved?
   - Who are the target users?
   - What does success look like?
2. Identify stakeholders and use cases
3. Document initial understanding

Example triggers for AskUserQuestion:
| User Says | Ask About |
|-----------|-----------|
| "Add a feature" | What feature? For whom? Why? |
| "Improve performance" | Which operation? What's the target? |
| "Make it better" | Better how? Faster? Easier? More reliable? |

**Domain Knowledge Injection:** Ask the user:
```
Before I explore the codebase, is there any context I should know?
- Internal design guidelines or conventions?
- Reference implementations to follow?
- Constraints not visible in the code?

(Skip if none)
```

**Output:** Summary of understanding and confirmation from user.

**Progress Update:** currentPhase: "plan-discovery-complete"

---

### Phase 2: Codebase Exploration

**Goal:** Understand relevant existing code and patterns.

**LAUNCH 2-3 `code-explorer` AGENTS IN PARALLEL:**

```
Launch these code-explorer agents in parallel:

1. code-explorer (similar features)
   Task: Explore existing implementations of similar features
   Thoroughness: medium
   Output: Entry points, execution flow, key files

2. code-explorer (architecture)
   Task: Map the overall architecture and patterns used
   Thoroughness: medium
   Output: Layers, boundaries, conventions

3. code-explorer (UI patterns) - if frontend work
   Task: Trace UI component patterns and state management
   Thoroughness: medium
   Output: Component hierarchy, data flow
```

**Wait for all agents to complete.**

**Error Handling:**
If any agent fails or times out:
1. Check the agent's partial output for usable findings
2. If critical agent failed, retry once with reduced scope
3. If retry fails, proceed with available results and document the gap
4. Add to progress file: `"warnings": ["Agent X failed, results may be incomplete"]`

**Read up to 3 of the most critical files** identified by explorers.

**Present comprehensive summary of findings to user.**

**Progress Update:** currentPhase: "plan-exploration-complete"

---

### Phase 3: Specification Drafting

**Goal:** Fill in gaps, resolve ambiguities, draft and refine the specification.

Based on discovery and exploration, identify:
- Edge cases
- Error handling requirements
- Integration points
- Backward compatibility needs
- Performance requirements

**Ask clarifying questions using AskUserQuestion.**

**CRITICAL: Wait for user answers before proceeding.**

**Draft the specification:**
If a spec already exists, review/update it. Otherwise, draft a new spec using `product-manager`.

```
Launch product-manager agent to draft the spec:
Specification target: docs/specs/[feature-name].md
Template: docs/specs/SPEC-TEMPLATE.md
Inputs: Clarified requirements + exploration findings + user domain knowledge
Output: Draft spec for user review
```

#### Specification Refinement Loop (max 3 iterations)

Present the draft spec to the user and ask:

```
Here is the draft specification. Please review it.

Options:
1. Approve as-is → proceed to Architecture Design
2. Request changes → tell me what to modify (I'll revise and re-present)
3. Add requirements → provide additional context or constraints
4. Reject and restart → re-gather requirements
```

**If the user requests changes (option 2 or 3):**
1. Incorporate the user's feedback
2. Re-launch `product-manager` with updated inputs, OR apply targeted edits directly to the spec file
3. Present the revised spec
4. Repeat until approved or max 3 iterations reached

**If max iterations reached without approval:**
Ask user: "We've iterated 3 times. Would you like to approve the current version, continue refining manually, or start over?"

**Output:** Approved specification at `docs/specs/[feature-name].md`

**Progress Update:** currentPhase: "plan-spec-approved"

---

### Phase 4: Architecture Design

**Goal:** Design the implementation approach based on codebase patterns and approved spec.

**LAUNCH 2-3 `code-architect` AGENTS IN PARALLEL with different analysis focuses:**

```
Launch these code-architect agents in parallel:

1. code-architect (reuse analysis)
   Analyze: How existing patterns and code can be reused
   Context: [Exploration findings], [Approved spec]
   Output: Reuse opportunities with file:line evidence

2. code-architect (extensibility analysis)
   Analyze: Clean abstraction opportunities for future growth
   Context: [Exploration findings], [Approved spec]
   Output: Abstraction recommendations with file:line evidence

3. code-architect (performance analysis) - if relevant
   Analyze: Performance implications and optimizations
   Context: [Exploration findings], [Approved spec]
   Output: Performance considerations with file:line evidence
```

**Wait for all agents to complete.**

**Synthesize all agent outputs into ONE definitive recommendation:**
```markdown
## Architecture Design

### Pattern Analysis from Codebase
Based on code-architect findings:
- Service pattern: [Pattern] (see `file:line`)
- Data access: [Pattern] (see `file:line`)
- API structure: [Pattern] (see `file:line`)

### Recommended Approach

**Architecture**: [Summary of recommended approach]

**Rationale**:
- Aligns with existing pattern at `file:line`
- Follows convention in `file:line`

**Implementation Map**:
| Component | File | Action |
|-----------|------|--------|
| [Name] | `src/...` | Create |
| [Name] | `src/...` | Modify |

**Build Sequence**:
- [ ] Step 1: [Task]
- [ ] Step 2: [Task]
- [ ] Step 3: [Task]

**Trade-offs Considered**:
- [Alternative A]: [Why not chosen]
- [Alternative B]: [Why not chosen]

**Rejected Approaches** (for future reference):
- [Approach]: [Reason for rejection]
```

#### Architecture Refinement Loop (max 3 iterations)

Present the design to the user and ask:

```
Here is the proposed architecture. Please review it.

Options:
1. Approve → save design and complete planning
2. Request changes → tell me what to modify (e.g., "use session-based auth instead of JWT")
3. Explore alternative → re-analyze with different constraints
4. Go back to spec → revise the specification first
```

**If the user requests changes (option 2):**
1. Re-launch relevant `code-architect` agent(s) with updated constraints
2. Revise the design document
3. Present the revised design
4. Repeat until approved or max 3 iterations

**If the user wants to explore an alternative (option 3):**
1. Launch `code-architect` with the alternative approach
2. Present comparison: original vs alternative with trade-offs
3. Let user choose

**If the user wants to go back to spec (option 4):**
1. Return to Phase 3 Specification Refinement Loop
2. After spec is re-approved, re-run Phase 4

**Output:** Approved design saved to `docs/specs/[feature-name]-design.md`

---

### Self-Review Gate

**After Phase 4 design is approved, run the self-review gate before presenting the final output.**

Load the `plan-self-review` skill. Run the 13-item checklist against the spec and design files. This is a lightweight direct-read check, NOT a subagent invocation.

**Based on self-review results:**

| Result | Action |
|--------|--------|
| ALL CLEAR (0 flags) | Present plan to user as-is |
| MINOR FLAGS (1-2 flags) | Present plan with flags noted |
| NEEDS ATTENTION (3+ flags) | Fix flagged items, re-run checklist once, then present |

Include self-review results in the final output so the user sees what was checked.

---

**Progress Update:**
Update `claude-progress.json`:
- currentPhase: "plan-complete"
- currentTask: "Planning complete - ready for user review"
- resumptionContext.nextAction: "Run /spec-review for user feedback, then /spec-implement"

## Planning Complete - Next Steps

After self-review gate, present:

```markdown
## Planning Complete

### Outputs
- Specification: `docs/specs/[feature-name].md`
- Design: `docs/specs/[feature-name]-design.md`
- Progress: `.claude/workspaces/{id}/claude-progress.json`

### Self-Review
[ALL CLEAR / MINOR FLAGS / results summary]

### Next Step
Run `/spec-review docs/specs/[feature-name].md` to review the plan
interactively — give feedback, request changes, or approve.
Then run `/spec-implement` to build it.
```

## Usage Examples

```bash
# Start planning a feature
/spec-plan Add user authentication with OAuth support

# Start interactively
/spec-plan

# Plan from existing requirements
/spec-plan Implement the feature specified in docs/specs/user-dashboard.md
```

## When NOT to Use

- Single-line bug fixes (just fix it directly)
- Trivial changes with clear scope (use `/quick-impl`)
- Urgent hotfixes (use `/hotfix`)
- Already have an approved spec (go straight to `/spec-implement`)

---

## Rules (L1 - Hard)

Critical for orchestration and planning quality.

- MUST delegate bulk Grep/Glob operations to `code-explorer` (use directly only for single targeted lookups)
- NEVER read more than 3 files directly — delegate bulk reading to subagents
- NEVER implement code yourself — this is a planning command
- NEVER skip to implementation — output is a plan, not code
- MUST use AskUserQuestion when:
  - User request is vague or missing critical details
  - Multiple interpretations of requirements are possible
  - Clarification is needed before proceeding to next phase
  - User feedback during refinement loop is ambiguous
- NEVER guess user intent — ask first using AskUserQuestion
- ALWAYS create progress file before any Phase 1 work
- ALWAYS update progress file at each phase completion

## Defaults (L2 - Soft)

Important for quality planning. Override with reasoning when appropriate.

- Launch 2-3 parallel agents per exploration/design phase
- Use refinement loops (max 3 iterations) for spec and design approval
- Document trade-offs and rejected approaches in design file
- Present findings to user before proceeding to next phase

## Guidelines (L3)

Recommendations for effective planning.

- Consider asking for domain knowledge before codebase exploration
- Prefer presenting options with trade-offs rather than single recommendations
- Consider running self-review gate before presenting final output
