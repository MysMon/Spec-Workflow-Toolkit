---
description: "Plan a feature with spec-first methodology - discovery, exploration, clarification, and architecture design"
argument-hint: "[optional: feature description]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task, TodoWrite, Skill
---

# /spec-plan - Specification-First Planning

Plan a feature through 4 phases: Discovery, Exploration, Clarification, and Architecture Design. Produces a reviewed specification and design document ready for `/spec-implement`.

## Attribution

Based on official feature-dev plugin, Claude Code Best Practices, Effective Harnesses for Long-Running Agents, and Building Effective Agents (6 Composable Patterns).

## Why Separate Planning from Implementation?

Anthropic's "Effective Harnesses for Long-Running Agents" found that agents "fall short when attempting to one-shot" complex work. The solution: an **Initializer** (planning) phase separate from incremental **Coding** sessions.

Benefits:
- Full context window available for planning (no implementation artifacts consuming tokens)
- Natural checkpoint for human review before costly implementation
- `/spec-review` can be run between planning and implementation
- Claude Code creator's workflow: "Plan Mode → refine plan → Auto-Accept for implementation"

## Phase Overview

1. **Discovery** - Understand what needs to be built
2. **Codebase Exploration** - Understand existing code and patterns (parallel agents)
3. **Clarifying Questions** - Fill gaps, resolve ambiguities, draft spec
4. **Architecture Design** - Analyze from multiple angles, synthesize one approach

## Execution Instructions

---

## ORCHESTRATOR-ONLY RULES (NON-NEGOTIABLE)

**YOU ARE THE ORCHESTRATOR. YOU DO NOT DO THE WORK YOURSELF.**

Load the `subagent-contract` skill for detailed orchestration protocols.

### Absolute Prohibitions

1. **Prefer delegating bulk Grep/Glob operations to `code-explorer`** - Use directly only for single targeted lookups
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

### Phase 1: Discovery

**Goal:** Understand what needs to be built and why.

---

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

---

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
  "currentPhase": "phase1-in_progress",
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

---

#### Discovery Work

If the user provided a feature description (`$ARGUMENTS`), analyze it first:
- What problem is being solved?
- Who are the target users?
- What are potential constraints?

If the request is vague or missing:
1. Ask clarifying questions using AskUserQuestion
2. Identify stakeholders and use cases
3. Document initial understanding

**Output:** Summary of understanding and confirmation from user.

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

**Progress Update:**
Update `claude-progress.json`:
- currentPhase: "phase2-complete"
- resumptionContext.nextAction: "Proceed to Phase 3: Clarifying Questions"

### Phase 3: Clarifying Questions

**Goal:** Fill in gaps and resolve all ambiguities.

Based on discovery and exploration, identify:
- Edge cases
- Error handling requirements
- Integration points
- Backward compatibility needs
- Performance requirements

**Ask clarifying questions using AskUserQuestion.**

**CRITICAL: Wait for user answers before proceeding.**

**Output:** Complete requirements with all ambiguities resolved.

**Draft the specification (required before Phase 4):**
If a spec already exists, review/update it. Otherwise, draft a new spec using `product-manager`.

```
Launch product-manager agent to draft the spec:
Specification target: docs/specs/[feature-name].md
Template: docs/specs/SPEC-TEMPLATE.md
Inputs: Clarified requirements + exploration findings
Output: Draft spec for user review
```

**Ask user to approve the spec** before moving to Phase 4.

**Progress Update:**
Update `claude-progress.json`:
- currentPhase: "phase3-complete"
- resumptionContext.nextAction: "Proceed to Phase 4: Architecture Design"

### Phase 4: Architecture Design

**Goal:** Design the implementation approach based on codebase patterns.

**LAUNCH 2-3 `code-architect` AGENTS IN PARALLEL with different analysis focuses:**

```
Launch these code-architect agents in parallel:

1. code-architect (reuse analysis)
   Analyze: How existing patterns and code can be reused
   Context: [Exploration findings], [Requirements]
   Output: Reuse opportunities with file:line evidence

2. code-architect (extensibility analysis)
   Analyze: Clean abstraction opportunities for future growth
   Context: [Exploration findings], [Requirements]
   Output: Abstraction recommendations with file:line evidence

3. code-architect (performance analysis) - if relevant
   Analyze: Performance implications and optimizations
   Context: [Exploration findings], [Requirements]
   Output: Performance considerations with file:line evidence
```

**Wait for all agents to complete.**

**Synthesize all agent outputs into ONE definitive recommendation:**
```markdown
## Architecture Analysis

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
- [Trade-off 1]: [Why this choice is best]
- [Trade-off 2]: [Why this choice is best]
```

**Ask user: "Does this approach work for you? Any concerns?"**

**Output:** Approved design saved to `docs/specs/[feature-name]-design.md`

**Progress Update:**
Update `claude-progress.json`:
- currentPhase: "phase4-complete"
- currentTask: "Planning complete - ready for review and implementation"
- resumptionContext.nextAction: "Run /spec-review, then /spec-implement"

---

## Planning Complete - Next Steps

After Phase 4, present:

```markdown
## Planning Complete

### Outputs
- Specification: `docs/specs/[feature-name].md`
- Design: `docs/specs/[feature-name]-design.md`
- Progress: `.claude/workspaces/{id}/claude-progress.json`

### Recommended Next Steps
1. `/spec-review docs/specs/[feature-name].md` - Review the spec for gaps
2. `/spec-implement` - Start implementation from the approved plan

### Why Review Before Implementation?
Running /spec-review catches completeness, feasibility, security, and
testability issues BEFORE implementation effort begins. Fixing a spec
is cheaper than fixing code.
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
