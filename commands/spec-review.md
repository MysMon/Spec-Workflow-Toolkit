---
description: "Review a specification using multiple specialized agents in parallel for comprehensive validation"
argument-hint: "[path to spec file or feature name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion
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

**Default Threshold:** 80 (unified with `/code-review` for consistency)

**Why 80% threshold?**
- Aligned with official code-review plugin pattern
- Reduces false positives and noise
- Ensures only actionable issues are reported
- Users can adjust with `--threshold` flag if needed

## Execution Instructions

### Step 1: Locate Specification

If `$ARGUMENTS` is provided:
- If it's a file path, read that file
- If it's a feature name, search in `docs/specs/` directory

If no arguments:
- List available specs in `docs/specs/`
- Ask user which one to review

### Step 2: Launch Parallel Review Agents

**CRITICAL: Launch all 4 agents in a single message with 4 separate Task tool calls.**

To achieve true parallelism, invoke multiple Task tools in a single response:
```
<parallel-execution>
Task tool call 1: product-manager (Completeness)
Task tool call 2: system-architect (Technical Feasibility)
Task tool call 3: security-auditor (Security)
Task tool call 4: qa-engineer (Quality/Testability)
</parallel-execution>
```

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
2. **Filter by confidence** (>= 80 by default)
3. **De-duplicate findings** using these rules:
   - **Same location + same type** → Keep highest confidence, merge descriptions
   - **Same location + different types** → Keep both (e.g., security AND completeness)
   - **Similar description + different locations** → Keep both as separate issues
   - **Multiple agents flag same issue** → Boost confidence by 10 (max 100)
4. **Sort by severity** (highest confidence first)

**De-duplication Example:**
```
Agent 1: "Missing auth" (Security, line 15, confidence 85)
Agent 4: "No auth test" (Quality, line 15, confidence 75)
→ Keep both: different perspectives on same location

Agent 2: "Scalability issue" (Feasibility, line 20, confidence 90)
Agent 3: "Performance concern" (Feasibility, line 20, confidence 85)
→ Merge: "Scalability/performance issue" (confidence 95)
```

### Step 4: Present Review Report

```markdown
## Specification Review: [Feature Name]

### Summary
- Total issues found: [N]
- Critical (90-100): [N]
- Important (80-89): [N]
- Filtered (below 80): [N]

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
