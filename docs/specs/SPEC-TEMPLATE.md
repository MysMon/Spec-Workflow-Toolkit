# Feature: [Feature Name]

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name]
> **Date**: YYYY-MM-DD
> **Reviewers**: [Names]

## Overview

| 項目 | 内容 |
|------|------|
| **What** | [1文で何を実装するか] |
| **Why** | [1文でビジネス価値・解決する問題] |
| **Risk** | [主要なリスクや注意点。なければ「特記事項なし」] |
| **Scope** | IN: [主要な含有項目] / OUT: [#out-of-scope](#out-of-scope)参照 |

### Must Requirements (Top 3)

> 実装者が最初に確認すべき最重要要件

1. **FR-XXX**: [最重要Must要件の1行要約]
2. **FR-XXX**: [2番目のMust要件の1行要約]
3. **FR-XXX**: [3番目のMust要件の1行要約]

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

### Must Requirements (実装必須)

| ID | 要件 | 受入条件 |
|----|------|----------|
| FR-001 | [要件の説明] | [検証方法を1行で] |
| FR-002 | [要件の説明] | [検証方法を1行で] |

### Should Requirements (重要だが調整可)

| ID | 要件 | 受入条件 |
|----|------|----------|
| FR-003 | [要件の説明] | [検証方法を1行で] |

### Could Requirements (余裕があれば)

| ID | 要件 | 受入条件 |
|----|------|----------|
| FR-004 | [要件の説明] | [検証方法を1行で] |

### Requirement Details

> 各要件の詳細な受入条件が必要な場合は以下に記載

#### FR-001: [Requirement Name]
- **Description**: Detailed description of the requirement
- **Acceptance Criteria**:
  - [ ] Criterion 1
  - [ ] Criterion 2

#### FR-002: [Requirement Name]
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
