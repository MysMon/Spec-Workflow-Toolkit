# Feature: [Feature Name]

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name]
> **Date**: YYYY-MM-DD
> **Reviewers**: [Names]
> **Security Review Required**: Yes

## Overview

**What**: [1文で何を実装するかを説明]

**Why**: [1文でビジネス価値・解決する問題を説明]

**Risk**: [1文で主要なリスクや注意点を説明]

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

- Affected services/components: [List]
- Database changes required: Yes/No
- API changes required: Yes/No
- Third-party integrations: [List]
- **Breaking changes**: [Yes/No, details]
- **Migration required**: [Yes/No, approach]

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
