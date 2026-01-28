---
description: "Review a specification and its design document using multiple specialized agents in parallel"
argument-hint: "[path to spec file or feature name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, TodoWrite
---

# /spec-review - Parallel Specification & Design Review

Launch multiple specialized agents in parallel to comprehensively review both the specification and its corresponding design document before implementation begins.

## Overview

This command reviews **both spec and design** from 5 perspectives:
1. **Completeness Agent** - Checks for missing requirements in the spec
2. **Technical Feasibility Agent** - Validates implementation viability of the design
3. **Security Agent** - Identifies security concerns across spec and design
4. **Quality Agent** - Reviews testability and acceptance criteria
5. **Consistency Agent** - Validates spec↔design alignment

## Confidence Scoring

Each issue is scored 0-100:
- **0-24**: Likely false positive, ignore
- **25-49**: Minor concern, consider addressing
- **50-74**: Moderate issue, should address
- **75-100**: Critical issue, must address

**Default Threshold:** 80 (unified with `/code-review` for consistency)

## Execution Instructions

### Step 1: Locate Specification and Design

If `$ARGUMENTS` is provided:
- If it's a file path, read that file
- If it's a feature name, search in `docs/specs/` directory

**Also locate the corresponding design document:**
- If spec is `docs/specs/user-auth.md`, look for `docs/specs/user-auth-design.md`
- If design file is not found, note it but proceed with spec-only review

If no arguments:
- List available specs in `docs/specs/`
- Ask user which one to review

**Check progress file:**
- Look for `.claude/workspaces/{workspace-id}/claude-progress.json`
- If found, note current phase for context

### Step 2: Launch Parallel Review Agents

**CRITICAL: Launch all agents in a single message with separate Task tool calls.**

**Agent 1: Completeness Review**
```
Launch product-manager agent to review specification completeness.

Specification: [spec content]

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

Specification: [spec content]
Design document: [design content, if available]
Project context: [detected stack]

Check for:
- Unrealistic performance requirements
- Missing technical constraints
- Incompatible technology choices
- Scalability concerns
- Integration complexity underestimated
- Missing dependency considerations
- Design patterns inconsistent with codebase

For each issue, provide:
- Issue description
- Technical concern
- Confidence score (0-100)
- Alternative approach
- Whether this affects spec, design, or both
```

**Agent 3: Security Review**
```
Launch security-auditor agent to review security aspects.

Specification: [spec content]
Design document: [design content, if available]

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
- Whether this affects spec, design, or both
```

**Agent 4: Quality & Testability Review**
```
Launch qa-engineer agent to review testability.

Specification: [spec content]

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

**Agent 5: Spec↔Design Consistency Review** (only if design document exists)
```
Launch verification-specialist agent to check spec-design consistency.

Specification: [spec content]
Design document: [design content]

Check for:
- Requirements in spec not addressed by design
- Design decisions that contradict spec requirements
- Spec changes not reflected in design (check timestamps if available)
- Build sequence gaps (design references components not in spec)
- Trade-offs in design that violate spec constraints

For each issue, provide:
- Issue description
- Spec section vs design section
- Confidence score (0-100)
- Which document needs updating
```

### Step 3: Consolidate Results

After all agents complete:

1. **Collect all issues** from all agents
2. **Filter by confidence** (>= 80 by default)
3. **Categorize by target:** spec-only, design-only, or both
4. **De-duplicate findings** using these rules:
   - **Same location + same type** → Keep highest confidence, merge descriptions
   - **Same location + different types** → Keep both (e.g., security AND completeness)
   - **Similar description + different locations** → Keep both as separate issues
   - **Multiple agents flag same issue** → Boost confidence by 10 (max 100)
5. **Sort by severity** (highest confidence first)

### Step 4: Present Review Report

```markdown
## Specification & Design Review: [Feature Name]

### Summary
- Total issues found: [N]
- Critical (90-100): [N]
- Important (80-89): [N]
- Filtered (below 80): [N]
- Spec↔Design consistency: [ALIGNED / MISMATCHED]

### Critical Issues (Must Address)

#### Issue 1: [Title] (Confidence: 95)
**Category:** [Completeness/Feasibility/Security/Quality/Consistency]
**Affects:** [Spec / Design / Both]
**Location:** [Section in spec or design]
**Description:** [What's wrong]
**Recommendation:** [How to fix]

...

### Important Issues (Should Address)

...

### Consistency Check Results
[Results from Agent 5, or "No design document found - skipped"]

### Review Verdict

[ ] APPROVED - Ready for implementation
[ ] NEEDS REVISION - Address critical issues first
[ ] REJECTED - Major rework required
```

### Step 5: User Decision and Revision

Ask user:
```
Review complete. Found [N] issues ([X] critical, [Y] spec-only, [Z] design-only, [W] both).

What would you like to do?
1. Fix all issues → I'll update spec and design files
2. Fix critical only → address high-confidence issues
3. Discuss specific issues → get more details before deciding
4. Proceed anyway → document exceptions and continue
5. Go back to planning → re-run /spec-plan to revise
```

**If user chooses to fix (option 1 or 2):**

#### Spec/Design Revision Loop (max 2 iterations)

1. Apply fixes to the spec file for spec-related issues
2. Apply fixes to the design file for design-related issues
3. For issues affecting both:
   - Update the spec first (source of truth)
   - Then update the design to match
4. Present the changes summary to the user
5. Ask: "Would you like to re-run review on the updated documents, or approve?"

**If re-run requested:**
- Re-launch only the agents relevant to the changed areas (not all 5)
- Present delta report (new issues, resolved issues)

**If user chooses to go back to planning (option 5):**
- Inform user to run `/spec-plan` to revise
- Update progress file to indicate review-requested-replanning

### Step 6: Save Results and Update Progress

**Save review report:**
```
docs/specs/[feature-name]-review.md
```

**Update progress file** (if `.claude/workspaces/{workspace-id}/claude-progress.json` exists):
```json
{
  "currentPhase": "review-complete",
  "currentTask": "Review complete - [APPROVED/NEEDS REVISION]",
  "resumptionContext": {
    "nextAction": "Run /spec-implement to begin implementation",
    "reviewVerdict": "[APPROVED/NEEDS REVISION/REJECTED]",
    "unresolvedIssues": [N]
  }
}
```

This ensures `/spec-implement` can detect whether a review was completed and its outcome.

## Usage Examples

```bash
# Review specific spec file (also reviews matching design file)
/spec-review docs/specs/user-authentication.md

# Review by feature name
/spec-review user-authentication

# Interactive - list and choose
/spec-review
```

## Customization

### Adjust Confidence Threshold

```
/spec-review docs/specs/my-feature.md --threshold 50
```

### Focus on Specific Aspects

```
/spec-review docs/specs/my-feature.md --focus security
```

---

## Rules (L1 - Hard)

- ALWAYS use parallel agent execution (all agents in single message)
- ALWAYS apply confidence filtering before reporting (default >= 80)
- NEVER proceed to implementation with unaddressed critical issues (>= 90 confidence)
- ALWAYS de-duplicate findings across agents
- ALWAYS update progress file if one exists
- ALWAYS check for design document alongside spec

## Defaults (L2 - Soft)

- Use 80% confidence threshold (adjustable with --threshold)
- Save review results to docs/specs/[feature-name]-review.md
- Boost confidence by 10 when multiple agents flag same issue
- Ask user before proceeding when critical issues found
- Run consistency check when design document exists

## Guidelines (L3)

- Consider re-running review after spec/design updates
- Prefer addressing critical issues before important ones
- Consider domain-specific reviewers for specialized specs
