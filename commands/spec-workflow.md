---
description: "Guide for the full spec-first development lifecycle - explains the plan → review → implement flow"
argument-hint: "[optional: feature description]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task, TodoWrite, Skill
---

# /spec-workflow - Spec-First Development Guide

Guides you through the complete spec-first development lifecycle. This command explains the workflow and helps you start the right phase.

## Why Three Separate Commands?

Anthropic's "Effective Harnesses for Long-Running Agents" found agents fail when trying to do too much at once. Each phase runs as a **separate command with its own fresh context window**:

```
/spec-plan               /spec-review              /spec-implement
 Discovery                Completeness              Preparation
 Exploration              Feasibility               Implementation
 Spec Drafting ←→ user    Security                  Quality Review
 Architecture ←→ user     Testability               Summary
        ↓                 Spec↔Design consistency ←→ user
   spec + design                ↓                         ↓
                          review report              working code
        ←→ = iterative refinement with user feedback
```

**Key design principle:** Each command has built-in feedback loops. Users can revise specs, explore alternative architectures, and address review findings — not just approve or reject.

## Composable Patterns Applied

| Pattern | Application |
|---------|-------------|
| **Prompt Chaining** | 3 commands executed sequentially with user-controlled gates |
| **Routing** | Model selection, agent selection by task type |
| **Parallelization** | Multiple explorers/architects/reviewers within each phase |
| **Orchestrator-Workers** | Each command orchestrates its own subagents |
| **Evaluator-Optimizer** | Refinement loops in spec-plan, revision loops in spec-review, quality fix loops in spec-implement |
| **Augmented LLM** | Tools, progress files, retrieval for all agents |

## How to Use

### Starting a New Feature

Run `/spec-plan` to begin:
```bash
/spec-plan Add user authentication with OAuth support
```

This guides you through discovery, exploration, spec drafting (with iterative refinement), and architecture design (with alternative exploration). It produces:
- `docs/specs/[feature-name].md` — the specification
- `docs/specs/[feature-name]-design.md` — the architecture design

### Reviewing Before Implementation (Recommended)

Run `/spec-review` to validate both spec and design:
```bash
/spec-review docs/specs/user-authentication.md
```

This launches 5 parallel agents (including a spec↔design consistency checker). It can fix issues in both files and updates the progress file so `/spec-implement` knows the review status.

### Implementing the Plan

Run `/spec-implement` to build from the approved plan:
```bash
/spec-implement docs/specs/user-authentication.md
```

This checks review status before starting, implements features one at a time, and runs quality review with an evaluator-optimizer loop.

### Resuming Interrupted Work

```bash
/resume
```

Progress files track state across all three commands using consistent phase naming (`plan-*`, `review-*`, `impl-*`).

## When to Use Each Command

| Scenario | Command |
|----------|---------|
| New complex feature | Start with `/spec-plan` |
| Have a spec, want validation | `/spec-review` |
| Have an approved spec, ready to build | `/spec-implement` |
| Small, well-defined task | `/quick-impl` instead |
| Urgent fix | `/hotfix` instead |
| Want the full guided flow | Start with `/spec-plan`, then `/spec-review`, then `/spec-implement` |

## What If Requirements Change?

| When | What to Do |
|------|------------|
| During planning | Use the refinement loops built into `/spec-plan` |
| After review finds issues | `/spec-review` can fix both spec and design files |
| During implementation (minor) | `/spec-implement` adapts and logs deviations |
| During implementation (major) | `/spec-implement` pauses and offers to return to planning |
| After implementation | Start a new `/spec-plan` for the change |

## Progress File Flow

All three commands share a progress file at `.claude/workspaces/{id}/claude-progress.json`:

```
/spec-plan sets:     plan-discovery → plan-exploration-complete → plan-spec-approved → plan-complete
/spec-review sets:   review-complete (with verdict: APPROVED/NEEDS REVISION/REJECTED)
/spec-implement sets: impl-starting → impl-in-progress → impl-review-complete → completed
```

The `/resume` command reads this file to determine where to continue.

## Comparison

| Aspect | /spec-plan | /spec-review | /spec-implement | /quick-impl |
|--------|------------|--------------|-----------------|-------------|
| Purpose | Plan | Validate | Build | Small tasks |
| Output | Spec + design | Review report | Working code | Working code |
| Feedback loops | Spec refinement, architecture alternatives | Issue fixing, re-review | Spec-reality divergence handling, evaluator-optimizer | None |
| Agents | Explorer, Architect, PM | PM, Architect, Security, QA, Verifier | Explorer, Specialist, QA, Security, Verifier | Specialist |
| Best for | Complex features | Pre-implementation validation | Approved plans | Trivial changes |

## Tips for Best Results

1. **Be patient with exploration** - Phase 2 in `/spec-plan` prevents misunderstanding the codebase
2. **Use the refinement loops** - Don't just approve; request changes when something feels off
3. **Run `/spec-review`** - It catches issues humans miss, including spec↔design inconsistencies
4. **Don't skip security review** - Quality review in `/spec-implement` catches issues before production
5. **Inject domain knowledge early** - Share conventions and constraints in Phase 1 of `/spec-plan`
