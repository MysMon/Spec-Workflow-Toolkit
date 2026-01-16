---
description: "Launch the SDD (Specification-Driven Development) workflow - a guided multi-phase process from requirements to implementation"
argument-hint: "[optional: feature description]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task
---

# /sdd - Specification-Driven Development Workflow

Launch a guided multi-phase development workflow that ensures disciplined, spec-first development.

## Phase Overview

This command orchestrates 6 phases:
1. **Discovery** - Understand what needs to be built
2. **Requirements** - Gather detailed specifications
3. **Design** - Architecture decisions
4. **Implementation** - Build the feature
5. **Quality Review** - Ensure code meets standards
6. **Summary** - Document what was accomplished

## Execution Instructions

### CRITICAL: Context Protection

**ALWAYS delegate to subagents for complex work.** The main context must remain clean and focused on orchestration.

- Use `product-manager` agent for requirements gathering
- Use `architect` agent for design decisions
- Use `frontend-specialist` or `backend-specialist` for implementation
- Use `qa-engineer` agent for testing
- Use `security-auditor` agent for security review

### Phase 1: Discovery

**Goal:** Understand what needs to be built and why.

If the user provided a feature description (`$ARGUMENTS`), analyze it first:
- What problem is being solved?
- Who are the target users?
- What are potential constraints?

If the request is vague or missing:
1. Ask clarifying questions using AskUserQuestion
2. Identify stakeholders and use cases
3. Document initial understanding

**Output:** Summary of understanding and confirmation from user.

### Phase 2: Requirements Gathering

**Goal:** Create a complete specification.

**DELEGATE TO `product-manager` agent:**

```
Launch the product-manager agent to gather requirements for: [feature description]

Context:
- [Summary from Phase 1]
- [Any constraints identified]

Expected output:
- Requirements summary with FR and NFR
- User stories
- Acceptance criteria
- Out of scope items
```

**Wait for agent completion.** Review the requirements summary.

Ask user: "Are these requirements complete? Should we proceed to design?"

**Output:** Approved specification saved to `docs/specs/[feature-name].md`

### Phase 3: Design

**Goal:** Design the architecture and implementation approach.

**DELEGATE TO `architect` agent:**

```
Launch the architect agent to design the implementation for: [feature name]

Context:
- Specification: docs/specs/[feature-name].md
- Project stack: [detected or specified]

Expected output:
- Architecture decisions (ADR format)
- Component design
- Data flow
- Implementation approach options (minimum 2)
```

**Present options to user:**
- Option A: [Approach 1] - Pros/Cons
- Option B: [Approach 2] - Pros/Cons
- Recommendation: [Your recommendation]

Ask user: "Which approach should we take?"

**Output:** Approved design saved to `docs/specs/[feature-name]-design.md`

### Phase 4: Implementation

**Goal:** Build the feature according to spec and design.

**IMPORTANT:** Wait for explicit user approval before starting implementation.

Ask user: "Ready to start implementation? This will modify files in your codebase."

**DELEGATE TO specialist agents:**

For frontend work:
```
Launch the frontend-specialist agent to implement: [component/feature]
Following specification: docs/specs/[feature-name].md
Following design: docs/specs/[feature-name]-design.md
```

For backend work:
```
Launch the backend-specialist agent to implement: [service/API]
Following specification: docs/specs/[feature-name].md
Following design: docs/specs/[feature-name]-design.md
```

**Track progress** using TodoWrite tool. Update status as each component completes.

### Phase 5: Quality Review

**Goal:** Ensure code meets quality, security, and spec requirements.

**Launch 3 parallel review agents:**

1. **QA Engineer** - Test coverage and correctness
```
Launch qa-engineer agent to review and test the implementation for: [feature]
Focus on: Test coverage, edge cases, acceptance criteria verification
```

2. **Security Auditor** - Security review
```
Launch security-auditor agent to audit the implementation for: [feature]
Focus on: OWASP Top 10, authentication/authorization, data validation
```

3. **Code Quality** - Apply code-quality skill
```
Run code-quality checks on modified files
```

**Consolidate findings:**
- Critical issues (must fix)
- Important issues (should fix)
- Suggestions (nice to have)

Ask user: "Found [N] issues. Should we fix them now, fix later, or proceed as-is?"

### Phase 6: Summary

**Goal:** Document what was accomplished.

Create summary including:
- What was built
- Key decisions made
- Files modified/created
- Test coverage
- Security review status
- Suggested next steps

**Output:** Summary displayed to user, todos marked complete.

## Usage Examples

```bash
# Start with a feature idea
/sdd Add user authentication with OAuth support

# Start from scratch (interactive)
/sdd

# Start with existing requirements
/sdd Implement the feature specified in docs/specs/user-dashboard.md
```

## Tips for Best Results

1. **Be patient with requirements** - Phase 2 prevents future rework
2. **Choose architecture deliberately** - Phase 3 options exist for a reason
3. **Don't skip security review** - Phase 5 catches issues before production
4. **Read agent outputs carefully** - They contain important decisions and context

## When NOT to Use

- Single-line bug fixes (just fix it directly)
- Trivial changes with clear scope
- Urgent hotfixes requiring immediate deployment
- Changes already fully specified
