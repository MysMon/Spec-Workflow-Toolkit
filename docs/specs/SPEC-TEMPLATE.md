# Feature: [Feature Name]

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name]
> **Date**: YYYY-MM-DD
> **Reviewers**: [Names]

<!--
## Specification Content Guidelines

This template defines WHAT to build, not HOW to code it.

INCLUDE:
- User Stories (As a [user], I want [goal] so that [benefit])
- Acceptance Criteria in Gherkin format (Given-When-Then)
- Non-Functional Requirements with measurable targets
- Edge cases and error scenarios
- Out of Scope (explicit exclusions)
- Success metrics

DO NOT INCLUDE:
- Code snippets or implementation examples
- Pseudocode or algorithm details
- Function signatures or class definitions
- Specific tool/library version numbers
- Step-by-step implementation instructions

CODE REFERENCES:
- Use file:line pointers: "Follow pattern at `src/services/auth.ts:23`"
- Reference existing implementations: "See error handling in `utils/errors.ts`"
- NEVER copy code into this document

WHY: Specifications are contracts for AI agents and developers.
Code in specs creates ambiguity (is it a requirement or example?).
AI agents perform better with goal-oriented specs than prescriptive code.
-->

## Overview

Brief description of the feature and its business value (2-3 sentences).

## Background

Context and motivation for this feature. What problem does it solve?

## User Stories

### US-001: [Story Title]
**As a** [type of user]
**I want** [goal/desire]
**So that** [benefit/value]

### US-002: [Story Title]
**As a** [type of user]
**I want** [goal/desire]
**So that** [benefit/value]

## Functional Requirements

### FR-001: [Requirement Name]
- **Priority**: Must | Should | Could | Won't
- **Description**: Detailed description of the requirement
- **Acceptance Criteria**:
  - [ ] Criterion 1
  - [ ] Criterion 2

### FR-002: [Requirement Name]
- **Priority**: Must | Should | Could | Won't
- **Description**: Detailed description
- **Acceptance Criteria**:
  - [ ] Criterion 1

## Non-Functional Requirements

### Performance
- Response time: < X ms for Y operation
- Throughput: X requests/second

### Security
- Authentication required: Yes/No
- Authorization level: [Roles]
- Data sensitivity: Public/Internal/Confidential

### Accessibility
- WCAG 2.1 Level: A/AA/AAA
- Specific requirements: [List]

### Scalability
- Expected users: X concurrent
- Data volume: X records

## Acceptance Criteria (Gherkin)

```gherkin
Feature: [Feature Name]

  Scenario: [Scenario Name]
    Given [initial context]
    When [action taken]
    Then [expected outcome]

  Scenario: [Error Case]
    Given [initial context]
    When [invalid action]
    Then [error handling]
```

## UI/UX Considerations

- Wireframes: [Link or description]
- Design system components to use: [List]
- Responsive breakpoints: [Mobile, Tablet, Desktop]

## Technical Considerations

- Affected services/components: [List]
- Database changes required: Yes/No
- API changes required: Yes/No
- Third-party integrations: [List]

## Out of Scope

Explicitly list what is NOT included in this feature:
- Item 1
- Item 2

## Dependencies

- [Dependency 1]: [Status]
- [Dependency 2]: [Status]

## Open Questions

| # | Question | Owner | Status | Answer |
|---|----------|-------|--------|--------|
| 1 | [Question] | [Name] | Open/Resolved | [Answer] |

## Appendix

### Glossary
- **Term 1**: Definition
- **Term 2**: Definition

### References
- [Link to related documentation]
- [Link to design files]

---

## Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | [ ] Approved |
| Tech Lead | | | [ ] Approved |
| Designer | | | [ ] Approved |
