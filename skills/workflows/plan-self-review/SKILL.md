---
name: plan-self-review
description: |
  Lightweight self-review checklist for plan quality before presenting to user.
  No agent invocations — the orchestrator runs this checklist directly.

  Use when:
  - Completing /spec-plan before presenting final output
  - Validating spec↔design consistency without launching review agents
  - Quick quality gate before handing off to /spec-review

  Not for: Full parallel agent review (use /spec-review --auto for that)
allowed-tools: Read, Glob, Grep
model: sonnet
user-invocable: false
---

# Plan Self-Review Checklist

A lightweight quality gate that the orchestrator runs at the end of `/spec-plan` BEFORE presenting the final plan to the user. No agents are launched — this preserves context budget.

## When to Load

Load this skill at the end of `/spec-plan` Phase 4, after spec and design files have been saved.

## Checklist

The orchestrator reads both output files and checks each item. Mark each as PASS or FLAG.

### Specification Checklist

| # | Check | How to Verify |
|---|-------|---------------|
| S1 | **Acceptance criteria are measurable** | Each criterion has a concrete condition, not "should work well" |
| S2 | **Edge cases are listed** | At least 3 edge cases or error scenarios defined |
| S3 | **Out-of-scope is defined** | Section exists and lists at least 1 exclusion |
| S4 | **No ambiguous language** | Search for "should", "might", "could", "possibly" — flag if in requirements (OK in rationale) |
| S5 | **Security requirements exist** | Auth, authz, validation, or "N/A with reason" |
| S6 | **Non-functional requirements exist** | Performance, scalability, or "N/A with reason" |

### Design Checklist

| # | Check | How to Verify |
|---|-------|---------------|
| D1 | **Implementation map has files** | At least 1 file listed with Create/Modify action |
| D2 | **Build sequence exists** | At least 2 ordered steps |
| D3 | **Trade-offs documented** | At least 1 trade-off or rejected alternative |
| D4 | **File references are plausible** | Referenced files exist (Glob check) or are marked as "Create" |

### Consistency Checklist

| # | Check | How to Verify |
|---|-------|---------------|
| C1 | **Spec requirements covered by design** | Each spec section maps to a design component |
| C2 | **Design doesn't contradict spec** | No design choice violates a spec requirement |
| C3 | **Build sequence covers all components** | Each component in Implementation Map appears in Build Sequence |

## Output Format

```markdown
## Self-Review Results

Passed: [N]/13
Flagged: [N]

### Flagged Items
- [S4] Ambiguous language: "should" found in requirement 3.2
- [C1] Spec section "Error Handling" has no corresponding design component

### Assessment
[ALL CLEAR / MINOR FLAGS / NEEDS ATTENTION]
```

## Actions Based on Results

| Result | Action |
|--------|--------|
| ALL CLEAR (0 flags) | Present plan to user as-is |
| MINOR FLAGS (1-2 flags) | Present plan with flags noted: "Self-review found [N] items to note: ..." |
| NEEDS ATTENTION (3+ flags) | Fix the flagged items before presenting. For spec issues, edit the spec. For design issues, edit the design. Then re-run checklist once. |

## Rules (L1)

- NEVER launch subagents for this checklist — use direct file reads only
- ALWAYS run this before presenting the final plan to the user
- NEVER auto-fix items silently — always report what was flagged

## Defaults (L2)

- Fix NEEDS ATTENTION items before presenting (but inform user of changes)
- Include flagged items in the plan presentation so user is aware
