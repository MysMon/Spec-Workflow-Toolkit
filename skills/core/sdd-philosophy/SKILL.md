---
name: sdd-philosophy
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
| `architect` | Designs solutions |
| `*-specialist` | Implements specs |
| `qa-engineer` | Verifies specs |
| `security-auditor` | Audits security NFRs |

## Additional Resources

For detailed information:

- **Complete Spec Template**: See [references/spec-template.md](references/spec-template.md)
- **Workflow Examples**: See [examples/workflow-example.md](examples/workflow-example.md)
- **Project Template**: See `docs/specs/SPEC-TEMPLATE.md`

## Rules

- NEVER implement without approved spec
- ALWAYS clarify before assuming
- NEVER add scope without approval
- ALWAYS document deviations
- NEVER skip acceptance criteria
