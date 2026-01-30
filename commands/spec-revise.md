---
description: "Process user change requests after implementation - analyze impact against spec/design and route appropriately"
argument-hint: "[change request description or 'interactive']"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, TodoWrite
---

# /spec-revise - Post-Implementation Change Request Handler

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

Process user change requests after `/spec-implement` completion. This command reads the original spec and design documents, analyzes the impact of requested changes, and routes to the appropriate workflow.

## When to Use

- After `/spec-implement` when user wants modifications
- When user requests additions or changes to implemented features
- When feedback requires evaluating impact against original design

## When NOT to Use

- Before implementation (use `/spec-plan` or `/spec-review`)
- For new unrelated features (use `/spec-plan`)
- For urgent production fixes (use `/hotfix`)
- For debugging errors (use `/debug`)

## Phase Overview

1. **Context Loading** - Locate and read spec, design, and implementation state
2. **Change Request Collection** - Gather and clarify user's modification request
3. **Impact Analysis** - Analyze how changes affect spec and design
4. **Classification & Routing** - Determine appropriate response path
5. **Execution** - Apply changes or route to appropriate command
6. **Completion** - Update documents and progress files

## Execution Instructions

---

### Phase 1: Context Loading

**Goal:** Understand the current state of spec, design, and implementation.

#### Locate Project Files

1. **Check progress file** for current project:
   - Look for `.claude/workspaces/{workspace-id}/claude-progress.json`
   - Extract spec and design file paths

2. **If no progress file**, search for recent specs:
   - List files in `docs/specs/`
   - Ask user which project to revise

3. **Check existence only (do not read full content):**
   - Specification: Use Glob to check if `docs/specs/[feature-name].md` exists
   - Design: Use Glob to check if `docs/specs/[feature-name]-design.md` exists
   - Review log: Use Glob to check if `docs/specs/[feature-name]-review.md` exists
   - Progress file: Use Glob to check if `.claude/workspaces/{id}/claude-progress.json` exists

**CRITICAL: Do NOT read spec/design files directly. Delegate to subagent.**

**Delegate context loading to `product-manager` agent:**

```
Launch product-manager agent:
Task: Summarize current project state for revision context
Inputs: Spec file path + Design file path
Output: Key requirements list + Architecture summary (concise)
```

Use the agent's summary output for context. Do NOT read spec/design files directly.

**Present current state to user (using agent output):**
```
## Current Project State

**Feature:** [feature name]
**Spec:** docs/specs/[feature-name].md
**Design:** docs/specs/[feature-name]-design.md
**Status:** [from progress file if exists, or "No progress file"]

### Key Requirements (from product-manager summary)
[Agent-generated summary]

### Architecture Summary (from product-manager summary)
[Agent-generated summary]

Ready to receive your change request.
```

---

### Phase 2: Change Request Collection

**Goal:** Gather and clarify what the user wants to change.

#### If `$ARGUMENTS` contains a change request:
- Parse the request
- Proceed to clarification if needed

#### If `$ARGUMENTS` is empty or "interactive":
- Ask user what they want to change

```
What would you like to change or add?

Examples:
- "Add pagination to the user list"
- "Change authentication from JWT to sessions"
- "Remove the export feature"
- "Make the search faster"
```

#### Clarification Loop

**CRITICAL:** Use AskUserQuestion when the request is ambiguous.

| User Says | Ask About |
|-----------|-----------|
| "Make it better" | Better how? Performance? UX? Reliability? |
| "Add more features" | Which specific features? |
| "Change the design" | UI design? Architecture? Data model? |
| "It's too slow" | Which operation? What's acceptable? |
| "Something's wrong" | What behavior? Expected vs actual? |

**Continue until you have:**
- Clear description of what to change
- Why the change is needed (if not obvious)
- Any constraints or preferences

---

### Phase 3: Impact Analysis

**Goal:** Analyze how the requested change affects spec and design.

**Launch 2 parallel agents:**

```
1. product-manager agent
   Task: Analyze change request against specification
   Inputs: Change request + spec file
   Output:
   - Which requirements are affected
   - New requirements needed
   - Requirements to remove
   - Scope assessment (in-scope / out-of-scope / boundary)

2. code-architect agent
   Task: Analyze change request against design
   Inputs: Change request + design file + exploration findings
   Output:
   - Which components are affected
   - Architecture changes needed
   - Estimated complexity (low / medium / high)
   - Risk assessment
```

**Wait for both agents to complete.**

**Consolidate findings:**
```markdown
## Impact Analysis

### Specification Impact
- **Affected Requirements:** [list from product-manager]
- **New Requirements:** [list]
- **Scope Assessment:** [in-scope / out-of-scope / boundary]

### Design Impact
- **Affected Components:** [list from code-architect]
- **Architecture Changes:** [none / minor / significant]
- **Complexity:** [low / medium / high]
- **Risks:** [list]

### Classification
[See Phase 4 for classification result]
```

---

### Phase 4: Classification & Routing

**Goal:** Determine the appropriate response path based on impact analysis.

#### Classification Matrix

| Spec Impact | Design Impact | Classification | Route |
|-------------|---------------|----------------|-------|
| None | None/Minor | **TRIVIAL** | Direct fix |
| Minor | None/Minor | **SMALL** | Edit spec/design, then `/quick-impl` |
| Minor | Significant | **MEDIUM** | `/spec-review` for design revision |
| Significant | Any | **LARGE** | `/spec-plan` for re-planning |
| Out of scope | Any | **NEW** | `/spec-plan` as new feature |

#### Present Classification to User

```
## Change Classification

**Your Request:** [summary]

**Classification:** [TRIVIAL / SMALL / MEDIUM / LARGE / NEW]

**Rationale:**
- Spec impact: [description]
- Design impact: [description]

**Recommended Action:**
[Based on classification - see options below]

Options:
1. [Recommended action] - [why]
2. [Alternative action] - [trade-off]
3. Discuss further - I'll explain more about the impact
```

**CRITICAL:** Always let user choose. Never auto-route without confirmation.

#### Routing Actions

**TRIVIAL (Direct Fix):**
```
This is a minor change that doesn't affect the spec or design.
I can apply this directly.

Proceed with the fix?
1. Yes, apply the change
2. No, let me reconsider
```

If yes: Apply fix directly using Edit tool, then verify.

**SMALL (Spec/Design Edit + Quick Implementation):**
```
This requires updating the spec/design documents before implementation.

I'll:
1. Update the spec with [changes]
2. Update the design with [changes]
3. You can then run /quick-impl for the implementation

Proceed?
```

If yes: Edit spec and design files, present changes, suggest `/quick-impl`.

**MEDIUM (Design Revision Needed):**
```
This change significantly affects the architecture.

Recommended: Run /spec-review to revise the design with full analysis.

I'll update the progress file so /spec-review knows to focus on:
- [Affected area 1]
- [Affected area 2]

Run /spec-review now?
1. Yes, start design revision
2. No, I want to proceed anyway (risky)
3. Let me think about it
```

If yes: Update progress file with revision context, instruct user to run `/spec-review`.

**LARGE (Re-planning Needed):**
```
This is a significant change that affects core requirements.

Recommended: Run /spec-plan to re-analyze with the new constraints.

The original plan assumed [X], but your change requires [Y].
Re-planning will ensure we have a solid foundation.

Options:
1. Run /spec-plan with new constraints
2. Try to adapt current plan (higher risk)
3. Abandon the change
```

If option 1: Update progress file, instruct user to run `/spec-plan`.

**NEW (New Feature):**
```
This request is outside the scope of the current feature.

It should be planned as a separate feature using /spec-plan.

Current feature: [name] - [scope summary]
Your request: [summary] - [why it's out of scope]

Options:
1. Start /spec-plan for new feature
2. Try to incorporate into current feature (scope creep risk)
3. Save for later
```

---

### Phase 5: Execution (for TRIVIAL and SMALL only)

**Goal:** Apply changes when classification allows direct action.

#### For TRIVIAL Changes

1. Apply the fix using Edit tool
2. Run verification:
   ```
   Launch verification-specialist agent:
   Task: Verify change is consistent with spec and design
   Inputs: Changed files + spec + design
   Output: Consistency check result
   ```
3. Present result to user

#### For SMALL Changes

1. Delegate spec update to product-manager agent with change request
2. Delegate design update to code-architect agent with change request
3. Present diff summary (using agent outputs):
   ```
   ## Changes Applied

   ### Specification Updates
   - [Change 1]
   - [Change 2]

   ### Design Updates
   - [Change 1]
   - [Change 2]

   Next: Run /quick-impl to implement these changes.
   ```

---

### Phase 6: Completion

**Goal:** Update all relevant files and present next steps.

#### Update Progress File

```json
{
  "currentPhase": "revise-complete",
  "currentTask": "Change request processed",
  "lastUpdated": "{timestamp}",
  "resumptionContext": {
    "changeRequest": "{summary}",
    "classification": "{TRIVIAL/SMALL/MEDIUM/LARGE/NEW}",
    "action": "{what was done or recommended}",
    "nextAction": "{next command to run}"
  }
}
```

#### Update Review Log

Append to `docs/specs/[feature-name]-review.md`:
```markdown
## Revision: {date}

### Change Request
{user's request}

### Classification
{classification} - {rationale}

### Action Taken
{what was done}

### Next Steps
{recommendations}
```

#### Present Summary

```
## Revision Complete

**Request:** {summary}
**Classification:** {classification}
**Action:** {what was done}

### Next Steps
{based on classification}

### Files Updated
- {list of modified files}
```

---

## Feedback Loop

After completion, offer to process additional changes:

```
Would you like to make any other changes?
1. Yes, I have another change
2. No, I'm done for now
3. Undo the last change
```

If "Yes": Return to Phase 2.
If "Undo": Revert changes using git, return to Phase 2.

---

## Usage Examples

```bash
# Interactive mode - describe changes conversationally
/spec-revise

# Direct change request
/spec-revise Add pagination to the user list API

# Specific modification
/spec-revise Change the auth token expiry from 1 hour to 24 hours

# Feature adjustment
/spec-revise Remove the email notification feature
```

---

## Rules (L1 - Hard)

- ALWAYS delegate spec/design reading to `product-manager` agent — do NOT read directly
- ALWAYS use AskUserQuestion when change request is ambiguous
- NEVER auto-route to other commands without user confirmation
- NEVER skip impact analysis - always run both agents
- ALWAYS update progress file on completion
- ALWAYS append to review log
- MUST present classification and let user choose action

## Defaults (L2 - Soft)

- Launch product-manager and code-architect in parallel for impact analysis
- Present classification matrix rationale to help user understand
- Offer feedback loop for additional changes after completion
- For MEDIUM/LARGE/NEW, recommend but don't force the appropriate command

## Guidelines (L3)

- Consider showing relevant parts of spec/design when presenting current state
- Prefer explaining trade-offs when user wants to override classification
- Consider offering to save change requests for later if user is unsure
