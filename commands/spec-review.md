---
description: "Review a specification using multiple specialized agents in parallel for comprehensive validation"
argument-hint: "[path to spec file or feature name]"
allowed-tools: Read, Write, Glob, Grep, Task, AskUserQuestion
---

# /spec-review - Parallel Specification Review

Launch multiple specialized agents in parallel to comprehensively review a specification before implementation begins.

## Overview

This command uses 4 parallel agents to review specifications from different perspectives:
1. **Completeness Agent** - Checks for missing requirements
2. **Technical Feasibility Agent** - Validates implementation viability
3. **Security Agent** - Identifies security concerns
4. **Quality Agent** - Reviews testability and acceptance criteria

## Confidence Scoring

Each issue is scored 0-100:
- **0-24**: Likely false positive, ignore
- **25-49**: Minor concern, consider addressing
- **50-74**: Moderate issue, should address
- **75-100**: Critical issue, must address

Only issues with confidence >= 70 are reported by default.

## Execution Instructions

### Step 1: Locate Specification

If `$ARGUMENTS` is provided:
- If it's a file path, read that file
- If it's a feature name, search in `docs/specs/` directory

If no arguments:
- List available specs in `docs/specs/`
- Ask user which one to review

### Step 2: Launch Parallel Review Agents

**CRITICAL: Launch all 4 agents in a single Task tool call for true parallelism.**

**Agent 1: Completeness Review**
```
Launch product-manager agent to review specification completeness.

Specification: [content]

Check for:
- Missing user stories
- Undefined edge cases
- Unclear acceptance criteria
- Missing non-functional requirements
- Ambiguous language ("should", "might", "could")
- Missing out-of-scope section
- Undefined error scenarios

For each issue, provide:
- Issue description
- Location in spec
- Confidence score (0-100)
- Suggested fix
```

**Agent 2: Technical Feasibility Review**
```
Launch system-architect agent to review technical feasibility.

Specification: [content]
Project context: [detected stack]

Check for:
- Unrealistic performance requirements
- Missing technical constraints
- Incompatible technology choices
- Scalability concerns
- Integration complexity underestimated
- Missing dependency considerations

For each issue, provide:
- Issue description
- Technical concern
- Confidence score (0-100)
- Alternative approach
```

**Agent 3: Security Review**
```
Launch security-auditor agent to review security aspects.

Specification: [content]

Check for:
- Missing authentication requirements
- Undefined authorization rules
- Data sensitivity not classified
- Missing encryption requirements
- Compliance gaps (GDPR, HIPAA, etc.)
- Input validation not specified
- Audit logging requirements missing

For each issue, provide:
- Issue description
- Security impact
- Confidence score (0-100)
- Recommended requirement
```

**Agent 4: Quality & Testability Review**
```
Launch qa-engineer agent to review testability.

Specification: [content]

Check for:
- Unmeasurable acceptance criteria
- Missing test scenarios
- Undefined success metrics
- Untestable requirements
- Missing boundary conditions
- Performance targets not quantified

For each issue, provide:
- Issue description
- Testability concern
- Confidence score (0-100)
- Improved criteria
```

### Step 3: Consolidate Results

After all agents complete:

1. **Collect all issues** from 4 agents
2. **Filter by confidence** (>= 70 by default)
3. **Remove duplicates** where multiple agents found same issue
4. **Sort by severity** (highest confidence first)

### Step 4: Present Review Report

```markdown
## Specification Review: [Feature Name]

### Summary
- Total issues found: [N]
- Critical (75-100): [N]
- Important (50-74): [N]
- Minor (25-49): [N]

### Critical Issues (Must Address)

#### Issue 1: [Title] (Confidence: 95)
**Category:** [Completeness/Feasibility/Security/Quality]
**Location:** [Section in spec]
**Description:** [What's wrong]
**Recommendation:** [How to fix]

...

### Important Issues (Should Address)

...

### Suggested Improvements

...

### Review Verdict

[ ] APPROVED - Ready for implementation
[ ] NEEDS REVISION - Address critical issues first
[ ] REJECTED - Major rework required
```

### Step 5: User Decision

Ask user:
```
Review complete. Found [N] issues ([X] critical).

What would you like to do?
1. Update spec to address issues
2. Proceed anyway (document exceptions)
3. Get more details on specific issues
4. Cancel and revise manually
```

If user chooses to update:
- Apply fixes to the spec file
- Re-run review on updated spec (optional)

## Usage Examples

```bash
# Review specific spec file
/spec-review docs/specs/user-authentication.md

# Review by feature name
/spec-review user-authentication

# Interactive - list and choose
/spec-review
```

## Customization

### Adjust Confidence Threshold

To change the default threshold, specify in your request:
```
/spec-review docs/specs/my-feature.md --threshold 50
```

### Focus on Specific Aspects

```
/spec-review docs/specs/my-feature.md --focus security
```

## Output Files

Review results are saved to:
```
docs/specs/[feature-name]-review.md
```

This creates an audit trail of what was reviewed and decided.
