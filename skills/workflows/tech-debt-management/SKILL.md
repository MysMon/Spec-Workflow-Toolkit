---
name: tech-debt-management
description: |
  Technical debt identification, classification, and prioritization frameworks.
  Integrates with legacy-modernizer agent for systematic debt paydown.

  Use when:
  - Identifying technical debt in a codebase
  - Prioritizing which debt to address first
  - Tracking debt over time
  - Planning refactoring sprints
  - Justifying debt paydown to stakeholders

  Trigger phrases: tech debt, technical debt, code smell, refactor priority, RICE score, debt tracking, legacy code
allowed-tools: Read, Write, Glob, Grep, TodoWrite
model: sonnet
user-invocable: true
---

# Technical Debt Management

Frameworks for identifying, classifying, prioritizing, and tracking technical debt.

## Core Principle

From Anthropic's Building Effective Agents:

> "Agents should gain ground truth from the environment at each step."

**Applied to debt**: Identify debt from actual code patterns, not assumptions. Prioritize based on measurable impact.

## Debt Classification

### Types of Technical Debt

| Type | Description | Detection Method |
|------|-------------|------------------|
| **Design Debt** | Poor abstractions, tight coupling | Dependency analysis, code-explorer |
| **Code Debt** | Duplications, complexity, bad names | Linter warnings, complexity metrics |
| **Test Debt** | Low coverage, flaky tests | Coverage reports, test history |
| **Documentation Debt** | Missing/outdated docs | /doc-audit findings |
| **Dependency Debt** | Outdated packages, vulnerabilities | npm audit, security-auditor |
| **Infrastructure Debt** | Manual processes, missing automation | devops-sre analysis |

### Debt Severity Levels

| Level | Impact | Examples |
|-------|--------|----------|
| **Critical** | Blocks development or causes outages | Circular dependencies, security vulnerabilities |
| **High** | Significantly slows development | No tests for critical paths, major duplication |
| **Medium** | Causes friction, increases bug risk | Inconsistent patterns, partial coverage |
| **Low** | Cosmetic or minor inconvenience | Naming inconsistencies, missing docs |

## Prioritization Frameworks

### RICE Score

**R**each × **I**mpact × **C**onfidence / **E**ffort

| Factor | Scale | Description |
|--------|-------|-------------|
| **Reach** | 1-10 | How many developers/features affected? |
| **Impact** | 0.25, 0.5, 1, 2, 3 | How much improvement per case? |
| **Confidence** | 0-100% | How sure are we of estimates? |
| **Effort** | Person-weeks | How much work to fix? |

**Example:**
```
Debt: Extract shared validation logic
Reach: 8 (affects 8 modules)
Impact: 2 (significant improvement)
Confidence: 80%
Effort: 1 week

RICE = (8 × 2 × 0.8) / 1 = 12.8
```

### Cost of Delay

For time-sensitive debt:

```
CoD = (Weekly Impact × Weeks Until Critical) / Effort
```

Use when:
- Security vulnerabilities with disclosure deadlines
- Dependencies reaching end-of-life
- Performance issues affecting user growth

### Quadrant Analysis

Quick visual prioritization:

```
                HIGH IMPACT
                    │
    ┌───────────────┼───────────────┐
    │               │               │
    │   QUICK WINS  │  MAJOR PROJECTS
    │   (Do First)  │  (Plan Carefully)
    │               │               │
LOW ├───────────────┼───────────────┤ HIGH
EFFORT              │               EFFORT
    │               │               │
    │   FILL-INS    │  THANKLESS TASKS
    │   (Do When    │  (Avoid or Delegate)
    │    Time)      │               │
    │               │               │
    └───────────────┼───────────────┘
                    │
                LOW IMPACT
```

## Debt Tracking Format

### Debt Registry (JSON)

```json
{
  "version": "1.0",
  "lastUpdated": "2025-01-20",
  "summary": {
    "total": 15,
    "critical": 2,
    "high": 5,
    "medium": 6,
    "low": 2
  },
  "debts": [
    {
      "id": "TD-001",
      "title": "Extract validation utilities",
      "type": "code",
      "severity": "high",
      "location": "src/services/*.ts",
      "description": "Validation logic duplicated across 8 services",
      "impact": "Bug fixes require changes in multiple places",
      "rice": {
        "reach": 8,
        "impact": 2,
        "confidence": 80,
        "effort": 1,
        "score": 12.8
      },
      "status": "identified",
      "createdAt": "2025-01-15",
      "assignee": null,
      "relatedIssues": ["#123", "#145"]
    }
  ]
}
```

### Status Values

| Status | Description |
|--------|-------------|
| `identified` | Debt found, not yet prioritized |
| `prioritized` | RICE scored, in backlog |
| `scheduled` | Assigned to sprint/milestone |
| `in_progress` | Currently being addressed |
| `resolved` | Fixed and verified |
| `accepted` | Intentionally deferred |

## Debt Identification Workflow

### Step 1: Automated Detection

```
Launch code-explorer with analysis focus:

Analyze codebase for technical debt indicators:

1. **Complexity hotspots**: Files with high cyclomatic complexity
2. **Duplication**: Similar code blocks across files
3. **Dependency issues**: Circular imports, outdated packages
4. **Test gaps**: Critical paths without tests
5. **Code smells**: Long methods, large classes, deep nesting

Return findings with file locations and severity assessment.
```

### Step 2: Manual Review

For each automated finding:
1. Verify it's actual debt (not intentional design)
2. Assess real-world impact
3. Estimate fix effort
4. Calculate RICE score

### Step 3: Registry Update

Add confirmed debt items to tracking file:
- `.claude/tech-debt.json` (project-level)
- Or integrate with issue tracker

## Integration with Agents

### Using legacy-modernizer

For addressing identified debt:

```
DELEGATE to legacy-modernizer:

Address this technical debt:

Debt ID: TD-001
Title: Extract validation utilities
Location: src/services/*.ts
Description: [from registry]

Approach:
1. Create shared validation module
2. Migrate each service incrementally
3. Verify no behavior changes (characterization tests)
4. Update imports across codebase

Constraints:
- Preserve existing test coverage
- No breaking API changes
- Commit after each service migration
```

### Using security-auditor

For dependency debt:

```
DELEGATE to security-auditor:

Audit dependencies for security debt:

Focus:
- Known vulnerabilities (npm audit, etc.)
- End-of-life packages
- Packages with security advisories

Return prioritized list with severity and upgrade paths.
```

## Paydown Strategies

### 1. Boy Scout Rule

"Leave the code better than you found it."

- Fix small debts during related work
- No dedicated debt sprints needed
- Track cumulative improvements

### 2. Dedicated Debt Sprints

Allocate percentage of capacity:
- 20% rule: 1 day per week for debt
- Debt sprints: Quarterly focused cleanup
- Milestone debt: Clear before major releases

### 3. Strangler Fig Pattern

For large legacy systems:
1. Build new alongside old
2. Incrementally route traffic
3. Remove old when new is proven

## Reporting Template

### For Stakeholders

```markdown
## Technical Debt Report - [Date]

### Health Score: [X]/100

### Summary
- **Total Items**: [N]
- **Critical**: [N] (requires immediate attention)
- **Estimated Total Effort**: [X] person-weeks

### Top 5 by RICE Score

| Rank | Title | Type | RICE | Effort |
|------|-------|------|------|--------|
| 1 | [title] | [type] | [score] | [effort] |

### Recent Progress
- Resolved: [N] items this [period]
- New: [N] items identified

### Recommendations
1. [Top priority action]
2. [Second priority action]
```

## Rules (L1 - Hard)

- ALWAYS verify debt against actual code, not assumptions
- NEVER prioritize debt without impact assessment
- ALWAYS track debt formally (registry or issues)
- NEVER address critical security debt without urgency

## Defaults (L2 - Soft)

- Use RICE scoring for prioritization
- Store debt registry in `.claude/tech-debt.json`
- Review debt status monthly
- Include debt in sprint planning

## Guidelines (L3)

- Consider dedicating 20% capacity to debt paydown
- Prefer paying down debt near code being modified
- Consider debt visibility in team retrospectives
- Track debt trends over time for health metrics
