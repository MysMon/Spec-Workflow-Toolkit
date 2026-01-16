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
---

# Specification-Driven Development (SDD)

SDD is a disciplined approach to software development that requires explicit specifications before any implementation begins.

## Core Principles

### 1. No Code Without Spec

```
RULE: Never write implementation code without an approved specification.

Why:
- Prevents scope creep
- Forces upfront thinking
- Creates audit trail
- Enables accurate estimation
```

### 2. Ambiguity Tolerance Zero

```
RULE: If requirements are vague, DO NOT GUESS. Ask questions.

Why:
- Assumptions cause rework
- Clarification is cheaper than bugs
- Users know what they want (with help)
```

### 3. Specification as Contract

```
RULE: The spec is the source of truth for implementation.

The spec defines:
- What to build (functional requirements)
- How well to build it (non-functional requirements)
- When it's done (acceptance criteria)
- What NOT to build (out of scope)
```

## Development Phases

### Phase 1: Ambiguity Phase

User provides initial request (often vague):
- "Add user authentication"
- "Make it faster"
- "Build a dashboard"

**Action**: Invoke `product-manager` agent or `interview` skill

### Phase 2: Clarification Phase

Structured requirements gathering:
- Who are the users?
- What problem are we solving?
- What are the constraints?
- What does success look like?

**Output**: Requirements summary document

### Phase 3: Definition Phase

Create formal specification in `docs/specs/`:

```markdown
# Feature: [Name]

## Overview
[Business value summary]

## User Stories
US-001: As a [user], I want [goal], so that [benefit]

## Functional Requirements
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-001 | [What] | P0 | [Testable condition] |

## Non-Functional Requirements
| ID | Category | Requirement |
|----|----------|-------------|
| NFR-001 | Performance | [Target] |
| NFR-002 | Security | [Requirement] |

## Out of Scope
- [Explicitly excluded item 1]
- [Explicitly excluded item 2]

## Approval
[ ] Product Owner: ___________
[ ] Tech Lead: ___________
```

### Phase 4: Execution Phase

Implement strictly according to spec:

```
DO:
- Follow spec exactly
- Flag spec gaps (don't fill them)
- Track deviations
- Update spec if changes approved

DON'T:
- Add features not in spec
- Interpret ambiguous requirements
- Skip non-functional requirements
- "Improve" beyond scope
```

### Phase 5: Verification Phase

Validate against spec:

1. **Functional Testing**: Each FR has passing tests
2. **Non-Functional Testing**: NFRs are measured
3. **Acceptance Testing**: All criteria verified
4. **Security Audit**: Security NFRs validated

## Spec File Location

```
docs/
└── specs/
    ├── SPEC-TEMPLATE.md      # Template for new specs
    ├── feature-auth.md       # Example: Authentication spec
    └── feature-dashboard.md  # Example: Dashboard spec
```

## Workflow Commands

When you need to:

| Goal | Action |
|------|--------|
| Start new feature | Load `interview` skill, gather requirements |
| Create spec | Use `SPEC-TEMPLATE.md`, save to `docs/specs/` |
| Review spec | Check completeness against template |
| Start implementation | Verify spec is approved, then delegate to specialists |

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| "Just build it" | No clear success criteria | Require spec first |
| "We'll figure it out" | Scope creep guaranteed | Define scope upfront |
| "That's obvious" | Assumptions cause bugs | Document everything |
| "It's just a small change" | Small changes compound | Still needs spec |

## Integration with Agents

```
product-manager → Creates specs
architect → Designs solutions for specs
*-specialist → Implements specs
qa-engineer → Verifies against specs
security-auditor → Audits against security NFRs
```

## Rules

- NEVER implement without approved spec
- ALWAYS clarify before assuming
- NEVER add scope without approval
- ALWAYS document deviations
- NEVER skip acceptance criteria
