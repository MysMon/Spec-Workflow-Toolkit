# Specification Template Reference

Full specification template for SDD workflow.

## Complete Template

```markdown
# Feature: [Name]

## Document Info
- **Version**: 1.0
- **Status**: Draft | In Review | Approved | Implemented
- **Created**: YYYY-MM-DD
- **Last Updated**: YYYY-MM-DD

## Overview

| 項目 | 内容 |
|------|------|
| **What** | [1文で何を実装するか] |
| **Why** | [1文でビジネス価値・解決する問題] |
| **Risk** | [主要なリスクや注意点。なければ「特記事項なし」] |
| **Scope** | IN: [主要な含有項目] / OUT: [#out-of-scope](#out-of-scope)参照 |

### Must Requirements (Top 3)

> 実装者が最初に確認すべき最重要要件

1. **FR-001**: [最重要Must要件の1行要約]
2. **FR-002**: [2番目のMust要件の1行要約]
3. **FR-003**: [3番目のMust要件の1行要約]

## Background
[Why is this needed? What is the current state?]

## User Stories

### Primary Users
- **Persona 1**: [Description]
- **Persona 2**: [Description]

### Stories
| ID | Story | Priority |
|----|-------|----------|
| US-001 | As a [user], I want [goal] so that [benefit] | Must |
| US-002 | As a [user], I want [goal] so that [benefit] | Should |

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

### Priority Legend
- **Must**: 実装必須 (launch blocker)
- **Should**: 重要だが調整可
- **Could**: 余裕があれば
- **Won't**: 今回は対象外

## Non-Functional Requirements

| ID | Category | Requirement | Measurement |
|----|----------|-------------|-------------|
| NFR-001 | Performance | Response time < 200ms | p95 latency |
| NFR-002 | Security | All inputs validated | Audit scan |
| NFR-003 | Scalability | Support 1000 concurrent users | Load test |
| NFR-004 | Availability | 99.9% uptime | Monitoring |
| NFR-005 | Accessibility | WCAG 2.1 AA compliant | axe-core |

## Technical Design

### Architecture
[High-level architecture description or diagram reference]

### Data Model
[Key entities and relationships]

### API Contracts
[Endpoint definitions or OpenAPI reference]

### Dependencies
- [External service 1]
- [Library 1]

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| User has no network | Show cached data with offline indicator |
| Invalid input | Display validation error, don't submit |
| Concurrent edit | Last-write-wins with conflict notification |

## Out of Scope
- [Explicitly excluded item 1]
- [Explicitly excluded item 2]

## Security Considerations
- [ ] Authentication required
- [ ] Authorization checks
- [ ] Input validation
- [ ] Output encoding
- [ ] Rate limiting
- [ ] Audit logging

## Testing Strategy
- Unit tests for business logic
- Integration tests for API endpoints
- E2E tests for critical user journeys

## Rollout Plan
1. Feature flag deployment
2. Internal testing
3. Beta users (10%)
4. General availability

## Metrics & Success Criteria
| Metric | Target | Measurement |
|--------|--------|-------------|
| User adoption | 80% within 2 weeks | Analytics |
| Error rate | < 0.1% | Error tracking |
| Performance | p95 < 200ms | APM |

## Open Questions
- [ ] [Question that needs resolution]

## Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | [ ] Approved |
| Tech Lead | | | [ ] Approved |
| Security | | | [ ] Approved |
```

## Minimal Template (Quick Specs)

For smaller changes:

```markdown
# Feature: [Name]

## Problem
[What problem does this solve?]

## Solution
[Proposed solution summary]

## Requirements
- [ ] FR-001: [Requirement]
- [ ] FR-002: [Requirement]

## Acceptance Criteria
- [ ] [Testable condition 1]
- [ ] [Testable condition 2]

## Out of Scope
- [Excluded item]
```
