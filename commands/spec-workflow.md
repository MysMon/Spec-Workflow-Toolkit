---
description: "Full spec-first development workflow - plans, reviews, and implements a feature end-to-end"
argument-hint: "[optional: feature description]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task, TodoWrite, Skill
---

# /spec-workflow - Full Spec-First Development Workflow

Orchestrates the complete spec-first development lifecycle by guiding you through planning, review, and implementation as separate phases.

## Attribution

Based on official feature-dev plugin, Claude Code Best Practices, Effective Harnesses for Long-Running Agents, and Building Effective Agents (6 Composable Patterns).

## Architecture: Plan → Review → Implement

This command orchestrates three separate commands, each with its own focused context:

```
/spec-plan          /spec-review         /spec-implement
Phase 1: Discovery    Completeness         Phase 1: Preparation
Phase 2: Exploration  Feasibility          Phase 2: Implementation
Phase 3: Clarification Security            Phase 3: Quality Review
Phase 4: Architecture  Testability         Phase 4: Summary
        ↓                    ↓                      ↓
   spec + design        review report         working code
```

**Why this separation?**
- Anthropic's "Effective Harnesses" found agents fail when trying to do too much at once
- Each phase gets a full context window instead of competing for tokens
- Natural checkpoints for human review between phases
- Claude Code creator's approach: "Plan Mode → refine → Auto-Accept for implementation"

## Composable Patterns Applied

| Pattern | Application |
|---------|-------------|
| **Prompt Chaining** | 3 commands executed sequentially with gates |
| **Routing** | Model selection, agent selection by task type |
| **Parallelization** | Multiple explorers/architects/reviewers within each phase |
| **Orchestrator-Workers** | Each command orchestrates its own subagents |
| **Evaluator-Optimizer** | Quality review with confidence scoring and iteration |
| **Augmented LLM** | Tools, progress files, retrieval for all agents |

## Execution Instructions

### Step 1: Planning Phase

Run the planning workflow:

```
Execute /spec-plan with the user's feature description ($ARGUMENTS).

This produces:
- docs/specs/[feature-name].md (specification)
- docs/specs/[feature-name]-design.md (architecture design)
- .claude/workspaces/{id}/claude-progress.json (progress state)
```

**Wait for /spec-plan to complete all 4 phases.**

### Step 2: Review Phase

After planning completes, recommend a spec review:

```
Planning is complete. Before implementation, it's recommended to review the spec.

Would you like to:
1. Run /spec-review now (recommended)
2. Skip review and proceed to implementation
3. Review the spec manually first
```

**If user chooses review:**
Run `/spec-review docs/specs/[feature-name].md`

**If review finds critical issues:**
Address them before proceeding. Update the spec and design files.

### Step 3: Implementation Phase

After review (or if skipped), proceed to implementation:

```
Execute /spec-implement with the spec file path.

This produces:
- Working implementation with tests
- Quality review results
- Summary of changes
```

**Wait for /spec-implement to complete.**

### Step 4: Completion

After implementation:

```markdown
## Workflow Complete

### Artifacts Produced
- Specification: `docs/specs/[feature-name].md`
- Design: `docs/specs/[feature-name]-design.md`
- Review: `docs/specs/[feature-name]-review.md` (if reviewed)
- Implementation: [list of modified files]

### Quality Status
- Spec Review: [Passed/Skipped/Issues addressed]
- Code Review: [Results from /spec-implement Phase 3]
- Tests: [Status]
```

## Individual Commands

You can also run each phase independently:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/spec-plan` | Planning only (Phase 1-4) | When you want to plan without implementing |
| `/spec-review` | Review a spec | Between planning and implementation |
| `/spec-implement` | Implementation only (Phase 5-7) | When you already have an approved spec |
| `/spec-workflow` | Full lifecycle | When you want the complete flow |

## Usage Examples

```bash
# Full workflow (plan → review → implement)
/spec-workflow Add user authentication with OAuth support

# Full workflow interactively
/spec-workflow

# Or run phases separately:
/spec-plan Add user authentication with OAuth support
/spec-review docs/specs/user-authentication.md
/spec-implement docs/specs/user-authentication.md
```

## Tips for Best Results

1. **Be patient with exploration** - Phase 2 prevents misunderstanding the codebase
2. **Answer clarifying questions thoughtfully** - Phase 3 prevents future confusion
3. **Review the spec** - Running `/spec-review` catches issues before implementation
4. **Don't skip security review** - Quality review catches issues before production

## When NOT to Use

- Single-line bug fixes (just fix it directly)
- Trivial changes with clear scope (use `/quick-impl`)
- Urgent hotfixes (use `/hotfix`)

## Comparison

| Aspect | /spec-workflow | /spec-plan | /spec-implement | /quick-impl |
|--------|----------------|------------|-----------------|-------------|
| Phases | All | 1-4 (plan) | 5-7 (build) | 1 |
| Output | Working code | Spec + design | Working code | Working code |
| Review | Included | Separate | Included | Basic |
| Best for | Complex features | Planning only | Approved specs | Small tasks |
