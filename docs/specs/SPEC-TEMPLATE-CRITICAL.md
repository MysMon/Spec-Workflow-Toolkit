# Feature: [Feature Name]

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name]
> **Date**: YYYY-MM-DD
> **Reviewers**: [Names]
> **Security Review Required**: Yes

## Quick Navigation

<!-- 読者が必要なセクションに直接アクセス可能 -->
- [Overview](#overview) - 30秒で概要把握
- [Critical Constraints](#critical-constraints) - 絶対守るべき制約
- [Must Requirements](#must-requirements-top-3) - 最重要要件
- [Security Considerations](#security-considerations) - セキュリティ詳細
- [Technical Considerations](#technical-considerations) - 技術制約
- [Rollback Plan](#rollback-plan) - ロールバック手順

---

## Overview

<!-- 記入ガイド: 各項目は1文で簡潔に。詳細は後続セクションに記載 -->

| 項目 | 内容 |
|------|------|
| **What** | [1文で何を実装するか] |
| **Why** | [1文でビジネス価値・解決する問題] |
| **Risk** | [主要なリスクや注意点] |
| **Complexity** | Low / Medium / High |
| **Scope** | IN: [主要な含有項目] / OUT: [#out-of-scope](#out-of-scope)参照 |
| **Security** | [セキュリティ上の主要懸念点] |

### Must Requirements (Top 3)

> 実装者が最初に確認すべき最重要要件

1. **FR-XXX**: [最重要Must要件の1行要約]
2. **FR-XXX**: [2番目のMust要件の1行要約]
3. **FR-XXX**: [3番目のMust要件の1行要約]

### Critical Constraints

> 実装時に絶対守るべき制約（3項目以内）

- **[制約カテゴリ]**: [制約内容と理由]
- **[制約カテゴリ]**: [制約内容と理由]

## Background

<!-- 記入ガイド:
- 1-3文でこの機能が必要な背景を説明
- 「なぜ今これが必要か」を明確に
- セキュリティ上の動機があれば明記
-->

Context and motivation for this feature. What problem does it solve?

## User Stories

<!-- 記入ガイド:
- 各ストーリーは「誰が」「何を」「なぜ」の形式で記載
- セキュリティ関連のユーザーストーリーを含める
-->

### US-001: [Story Title]
**As a** [type of user]
**I want** [goal/desire]
**So that** [benefit/value]

### US-002: [Story Title]
**As a** [type of user]
**I want** [goal/desire]
**So that** [benefit/value]

## Functional Requirements

<!-- 記入ガイド:
- Must: リリースに必須。これがないと機能しない
- Should: 重要だがスケジュール調整可能
- Could: あれば良いが、なくてもリリース可能
- セキュリティ要件は Must に含める
-->

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
- **Measurement method**: [How to measure]
- **Test approach**: [Load test tool, scenarios]

### Security
- Authentication required: Yes/No
- Authorization level: [Roles]
- Data sensitivity: Public/Internal/Confidential
- **Threat model**: [Key threats to consider]

### Accessibility
- WCAG 2.1 Level: A/AA/AAA
- Specific requirements: [List]

### Scalability
- Expected users: X concurrent
- Data volume: X records
- **Growth projection**: [Expected growth over time]

## Security Considerations

### Threat Analysis
| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| [Threat 1] | High/Medium/Low | High/Medium/Low | [Mitigation approach] |
| [Threat 2] | High/Medium/Low | High/Medium/Low | [Mitigation approach] |

### Security Checklist
- [ ] Input validation implemented (whitelist approach)
- [ ] Output encoding applied
- [ ] Authentication/authorization verified at all entry points
- [ ] Sensitive data encrypted at rest and in transit
- [ ] Rate limiting configured
- [ ] Audit logging enabled for security events
- [ ] No secrets in code or logs
- [ ] CSRF protection enabled (if applicable)
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention measures

### Data Protection
- **PII handled**: [Yes/No, what data]
- **Encryption**: [At rest / In transit / Both]
- **Retention policy**: [How long, deletion process]
- **Access controls**: [Who can access]

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

  Scenario: [Security Scenario]
    Given [unauthorized user]
    When [attempts restricted action]
    Then [access is denied]
    And [attempt is logged]
```

## UI/UX Considerations

- Wireframes: [Link or description]
- Design system components to use: [List]
- Responsive breakpoints: [Mobile, Tablet, Desktop]

## Technical Considerations

<!-- 記入ガイド:
- 実装に影響する技術的制約を記載
- セキュリティに影響する技術的選択を明記
- Breaking changesがある場合は必ずMigration計画も記載
-->

- Affected services/components: [List]
- Database changes required: Yes/No
- API changes required: Yes/No
- Third-party integrations: [List]
- **Breaking changes**: [Yes/No, details]
- **Migration required**: [Yes/No, approach]

### Known Pitfalls

<!-- このタイプの実装でよくある間違いや注意点（特にセキュリティ関連） -->

| やりがちな間違い | 正しいアプローチ | 理由 |
|-----------------|------------------|------|
| [例: 平文でのパスワード保存] | [bcryptでハッシュ化] | [セキュリティ要件] |
| [例: N+1クエリ] | [バッチ取得を使用] | [パフォーマンス劣化防止] |

## Rollback Plan

### Rollback Criteria
- [Condition 1 that triggers rollback]
- [Condition 2 that triggers rollback]

### Rollback Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Data Recovery
- [How to recover data if needed]

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
| Security Lead | | | [ ] Approved |
| Designer | | | [ ] Approved |

<!--
Usage: Use this critical template for:
- P0 (launch blocker) features
- Security-sensitive changes (authentication, authorization, PII)
- Architecture-level changes
- Features affecting data integrity
- External API changes

For standard features, use SPEC-TEMPLATE.md instead.
For small changes, use SPEC-TEMPLATE-MINIMAL.md instead.
-->
