# Feature Design: [Feature Name]

> **Spec Reference**: `docs/specs/[feature-name].md`
> **Status**: Draft | In Review | Approved
> **Author**: [Name]
> **Date**: YYYY-MM-DD

## Pattern Analysis from Codebase

### Relevant Existing Patterns
| Pattern | Location | Applicability |
|---------|----------|---------------|
| [Pattern name] | [file:line] | [How to reuse] |

### Code to Modify
| Component | File | Change Type | Description |
|-----------|------|-------------|-------------|
| [Component] | [file path] | Modify/Add/Remove | [What changes] |

## Recommended Approach

### Architecture Summary
[2-3文で設計アプローチを説明]

### Rationale
[なぜこのアプローチを選んだか]

## Design Decisions

| Decision | Options Considered | Chosen | Rationale | Trade-offs |
|----------|-------------------|--------|-----------|------------|
| [Topic] | [Option A, B, C] | [Chosen] | [Why] | [Pros/Cons] |

## Implementation Map

### Component → File → Action
| Requirement | Component | File | Action | Notes |
|-------------|-----------|------|--------|-------|
| FR-001 | [Component] | [file path] | [Create/Modify] | [Implementation notes] |

### Data Flow
[データの流れを説明。必要に応じて図を追加]

## Build Sequence

Recommended implementation order with rationale:

1. **[Task 1]**
   - Files: [affected files]
   - Reason: [why first]
   - Dependencies: None

2. **[Task 2]**
   - Files: [affected files]
   - Reason: [why this order]
   - Dependencies: Task 1

3. **[Task 3]**
   - Files: [affected files]
   - Reason: [why this order]
   - Dependencies: Task 1, 2

## Rejected Approaches

### [Rejected Approach 1]
- **Description**: [What was considered]
- **Rejection Reason**: [Why not chosen]
- **Trade-off**: [What would have been gained/lost]

### [Rejected Approach 2]
- **Description**: [What was considered]
- **Rejection Reason**: [Why not chosen]

## Edge Cases and Error Handling

| Scenario | Expected Behavior | Implementation Notes |
|----------|-------------------|---------------------|
| [Edge case 1] | [Behavior] | [How to implement] |
| [Error case 1] | [Handling] | [How to implement] |

## Testing Strategy

| Test Type | Scope | Approach |
|-----------|-------|----------|
| Unit | [Components] | [Approach] |
| Integration | [Interactions] | [Approach] |
| E2E | [User flows] | [Approach] |

## Open Design Questions

| # | Question | Impact | Status | Resolution |
|---|----------|--------|--------|------------|
| 1 | [Question] | [What it affects] | Open/Resolved | [Answer] |

---

## Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Tech Lead | | | [ ] Approved |
| System Architect | | | [ ] Approved |
