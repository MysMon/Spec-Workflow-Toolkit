---
name: spec-philosophy
description: |
  Specification-Driven Development methodology and workflow. Use when:
  - Starting new features or projects ("new feature", "implement", "build")
  - User request is vague or unclear ("add something", "make it better")
  - Enforcing spec-first development ("write spec", "create specification")
  - Someone says "just build it" or wants to skip planning
  - Discussing requirements, acceptance criteria, or scope
  Trigger phrases: specification, PRD, requirements document, scope definition, feature planning
allowed-tools: Read, Write, Glob, AskUserQuestion
model: sonnet
user-invocable: true
context: fork
agent: general-purpose
---

# Specification-Driven Development (SDD)

SDD is a disciplined approach to software development that requires explicit specifications before any implementation begins.

## Core Principles

### 1. No Code Without Spec

**RULE**: Never write implementation code without an approved specification.

- Prevents scope creep
- Forces upfront thinking
- Creates audit trail
- Enables accurate estimation

### 2. Ambiguity Tolerance Zero

**RULE**: If requirements are vague, DO NOT GUESS. Ask questions.

- Assumptions cause rework
- Clarification is cheaper than bugs
- Users know what they want (with help)

### 3. Specification as Contract

**RULE**: The spec is the source of truth for implementation.

The spec defines:
- What to build (functional requirements)
- How well to build it (non-functional requirements)
- When it's done (acceptance criteria)
- What NOT to build (out of scope)

## Development Phases

| Phase | Name | Action | Output |
|-------|------|--------|--------|
| 1 | Ambiguity | Receive vague request | Understanding of intent |
| 2 | Clarification | Invoke `interview` skill | Requirements summary |
| 3 | Definition | Create spec in `docs/specs/` | Approved specification |
| 4 | Execution | Implement per spec | Working code |
| 5 | Verification | Validate against spec | Passing tests |

### Relationship to Plan→Review→Implement Commands

The 5-phase model above is the **logical abstraction**. The plan→review→implement commands expand this into an **operational workflow**:

| Logical Phase | Command / Phase | Details |
|---------------|----------------|---------|
| 1. Ambiguity | `/spec-plan`: Discovery | Initial requirements gathering |
| 2. Clarification | `/spec-plan`: Exploration + Clarifying Questions | Codebase analysis and user interview |
| 3. Definition | `/spec-plan`: Spec Drafting + Architecture Design | Specification and design with self-review |
| 4. Review | `/spec-review`: Interactive Feedback | User-driven plan review and refinement |
| 5. Execution | `/spec-implement`: Implementation | TDD-driven development |

## Quick Reference

### Spec File Location

```
docs/specs/
├── SPEC-TEMPLATE.md      # Template for new specs
└── feature-*.md          # Feature specifications
```

### Agent Integration

| Agent | Role in SDD |
|-------|-------------|
| `product-manager` | Creates specs |
| `system-architect` | System-level design (ADRs, schemas) |
| `code-architect` | Feature implementation blueprints |
| `*-specialist` | Implements specs |
| `qa-engineer` | Verifies specs |
| `security-auditor` | Audits security NFRs |

## Additional Resources

For detailed information:

- **Complete Spec Template**: See [references/spec-template.md](references/spec-template.md)
- **Workflow Examples**: See [examples/workflow-example.md](examples/workflow-example.md)
- **Project Template**: See `docs/specs/SPEC-TEMPLATE.md`

## Balancing Structure with Flexibility

SDD provides structure, but rigid adherence can hinder effective problem-solving.

### Goal-Oriented Approach

From Claude Code Best Practices:

> "Claude often performs better with high level instructions rather than step-by-step prescriptive guidance."

**Apply to SDD:**
- Phases define WHAT to achieve, not exactly HOW
- Adapt approach based on task complexity
- Skip phases when genuinely unnecessary (e.g., typo fixes)

### When to Apply Full SDD

| Scenario | Full Plan→Implement | Abbreviated |
|----------|--------------|-------------|
| New feature | ✅ | |
| Complex change | ✅ | |
| Architecture decision | ✅ | |
| Bug fix | | ✅ `/debug` |
| Typo/config change | | ✅ `/quick-impl` |
| Clear, scoped task | | ✅ `/quick-impl` |

### Flexibility Clause

The SDD workflow is a framework, not a checklist.

If you identify that a situation warrants deviation:
1. Confirm all L1 rules are still respected (no code without understanding, no skipping security)
2. Explain why the standard approach doesn't fit
3. Proceed with the adapted approach

**L1 Rules (Never Skip):**
- Understanding requirements before implementation
- Security review for security-sensitive code
- Approval for scope changes

**L2/L3 (Adapt as Needed):**
- Number of exploration agents
- Spec document format
- Phase ordering for simple tasks

## Rules (L1 - Hard)

- NEVER implement without understanding requirements
- ALWAYS clarify before assuming
- NEVER add scope without approval
- ALWAYS document significant deviations

## Defaults (L2 - Soft)

- Create formal spec for features > 1 day effort
- Use `/spec-plan` for new features (can use `/quick-impl` for obvious small tasks)
- Acceptance criteria should be testable

## Guidelines (L3)

- Consider TDD for complex logic
- Prefer parallel agent execution when independent
- Document architectural decisions in ADRs
