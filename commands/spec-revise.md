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

**Why progress file reading is acceptable (not delegated):**
- Progress files are orchestrator state metadata (not project content)
- Status checking is quick validation (typically <20 lines of JSON)
- Essential to locate spec/design file paths for this project
- Minimal context consumption compared to spec/design content analysis
- Consistent with resume.md Phase 3 pattern

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

**Reading vs Editing distinction:**
- **Reading for context**: Orchestrator MAY read spec/design files directly for quick lookups (confirming change location, verifying current value)
- **Editing/modifying**: Delegate to `product-manager` for SMALL or larger changes

Refer to `subagent-contract` skill for unified quick lookup limits (≤3 files, ≤200 lines per file, ≤300 lines total).

**Exception for TRIVIAL changes only** (Phase 5 Option A):
Single-value fixes (typos, dates, version numbers) MAY be edited directly using the Edit tool.
TRIVIAL criteria: Affects only 1-2 lines, has no semantic impact, requires no judgment calls.
See Phase 5 for detailed TRIVIAL classification with concrete examples.

**For comprehensive analysis**: ALWAYS delegate to `product-manager` or `code-architect` agents.

**Delegate context loading to `product-manager` agent:**

```
Launch product-manager agent:
Task: Summarize current project state for revision context
Inputs: Spec file path + Design file path
Output: Key requirements list + Architecture summary (concise)
```

**Error Handling for product-manager (context loading):**
If product-manager fails or times out:
1. Retry once with reduced scope (focus on key requirements only)
2. **Fallback: Read files directly** if retry fails (respecting unified limits from `subagent-contract`):
   - Read spec file directly to extract Key Requirements section (≤200 lines)
   - Read design file directly to extract Architecture Summary section (≤200 lines)
   - If file exceeds 200 lines, read first 200 lines with warning
   - Use extracted content as context for impact analysis
   - Warn user: "Using direct file read (summarization failed)"
3. Add to progress file: `"warnings": ["Context loading via agent failed, using direct read fallback"]`
4. Proceed with available context (do NOT block impact analysis entirely)

Use the agent's summary output for context when available.

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

**Error Handling for Impact Analysis agents:**

If product-manager fails or times out:
1. Retry once with reduced scope (focus on requirement impact only)
2. If retry fails, proceed with code-architect output only
3. Warn user: "Spec impact analysis unavailable. Classification will rely on design impact only."
4. Mark analysis as partial in progress file

If code-architect fails or times out:
1. Retry once with reduced scope (focus on component mapping only)
2. If retry fails, proceed with product-manager output only
3. Warn user: "Design impact analysis unavailable. Classification will rely on spec impact only."
4. Mark analysis as partial in progress file

If BOTH agents fail:
1. Inform user: "Impact analysis failed. Cannot proceed with classification."
2. Offer options:
   - "Retry both agents"
   - "Cancel and investigate"
3. Do NOT proceed to Phase 4 without at least one successful analysis

**CRITICAL: Delegate result consolidation to verification-specialist agent:**

```
Launch verification-specialist agent:
Task: Consolidate and cross-reference impact analysis from product-manager and code-architect
Inputs:
  - Change request summary
  - Product-manager findings (spec impact)
  - Code-architect findings (design impact)
Output:
  - Consolidated impact analysis with verified references
  - Recommended classification (TRIVIAL/SMALL/MEDIUM/LARGE/NEW)
  - Confidence scores for each determination
  - Identified contradictions or gaps between analyses
```

Do NOT consolidate results manually. Use the agent's consolidated output for Phase 4 presentation.

**Error Handling for verification-specialist:**
If verification-specialist fails or times out:
1. Present findings from product-manager and code-architect separately
2. Warn user: "Impact analysis consolidation failed. Showing raw agent findings."
3. **Fallback: Basic manual classification is ALLOWED** when verification-specialist fails:

   Apply this simplified classification logic:
   | Spec Impact | Design Impact | Classification |
   |-------------|---------------|----------------|
   | None mentioned | None mentioned | TRIVIAL |
   | "minor" or "clarification" only | None or "minor" | SMALL |
   | Any "new requirement" | Any | MEDIUM or higher |
   | "significant" or "breaking" | Any | LARGE |
   | "out of scope" mentioned | Any | NEW |

4. Present classification to user with confidence caveat:
   ```
   Based on available analysis (not fully consolidated):
   - Product-manager found: [summary of spec impact]
   - Code-architect found: [summary of design impact]

   Suggested classification: [TRIVIAL/SMALL/MEDIUM/LARGE/NEW]

   Note: This classification was derived without full consolidation.
   Please confirm or adjust before proceeding.

   Options:
   1. Proceed with suggested classification
   2. Retry consolidation with verification-specialist
   3. Choose different classification manually
   ```

5. Require explicit user confirmation before proceeding with fallback classification

**Present consolidated analysis to user (using verification-specialist output):**
```markdown
## Impact Analysis

### Specification Impact
- **Affected Requirements:** [from consolidated output]
- **New Requirements:** [from consolidated output]
- **Scope Assessment:** [from consolidated output]

### Design Impact
- **Affected Components:** [from consolidated output]
- **Architecture Changes:** [from consolidated output]
- **Complexity:** [from consolidated output]
- **Risks:** [from consolidated output]

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
I can apply this directly using the Edit tool for speed.

Proceed with the fix?
1. Yes, apply the change directly
2. Delegate to product-manager instead
3. No, let me reconsider
```

If yes (option 1): Proceed to Phase 5 Option A (direct edit).
If option 2: Proceed to Phase 5 Option B (product-manager delegation).

**SMALL (Spec/Design Edit + Quick Implementation):**
```
This requires updating the spec/design documents before implementation.

I'll delegate to product-manager to:
1. Update the spec with [changes]
2. Update the design with [changes]

Then you can run /quick-impl for the implementation.

Proceed?
```

If yes: Proceed to Phase 5 (SMALL execution via product-manager delegation).

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

TRIVIAL changes are single-value fixes that meet ALL criteria:
- Affect only 1-2 lines
- Have no semantic impact (see definition below)
- Require no judgment calls

**Definition of "no semantic impact":**
A change has NO semantic impact if:
1. The meaning of the spec/design is identical before and after
2. No implementation behavior would change based on the new wording
3. No developer reading the spec would interpret it differently

**Concrete Examples of TRIVIAL (delegate to product-manager by default):**

| Change Type | Example | Why TRIVIAL |
|-------------|---------|-------------|
| Typo fix | "recieve" → "receive" | Spelling error, meaning unchanged |
| Version number | "1.0.0" → "1.0.1" | Metadata update, no behavior change |
| Date update | "2025-01-01" → "2025-01-31" | Metadata update |
| Formatting | Fix markdown bullet indent | Visual only |

**Note:** Numeric value changes (timeout, retries, limits) are NOT TRIVIAL by default. Even small numeric changes may indicate spec intent changes and should be delegated to product-manager for proper context tracking.

**NOT TRIVIAL (delegate to product-manager):**

| Change Type | Example | Why NOT TRIVIAL |
|-------------|---------|-----------------|
| Value that affects behavior | `timeout: 30` → `timeout: 600` (10x increase) | May indicate spec intent change |
| Wording that affects meaning | "should" → "must" | Changes requirement strength |
| Adding/removing content | Adding a new bullet point | New requirement |
| Requirement description | "User can upload files" → "User can upload images only" | Scope change |
| Clarification with intent | "Fast response" → "Response under 100ms" | Adds specificity |

**Gray Zone - Always delegate to product-manager:**

| Change | Why it's NOT TRIVIAL | Action |
|--------|---------------------|--------|
| `maxRetries: 3` → `maxRetries: 5` | Numeric change affects behavior | Delegate to product-manager |
| `timeout: 30` → `timeout: 60` | Numeric change affects behavior | Delegate to product-manager |
| "error message" → "error notification" | Subtle meaning shift | Delegate to product-manager |
| Removing "(optional)" from a field | Changes requirement status | Delegate to product-manager |

**Rule of thumb:** If the change affects any numeric value or could influence implementation behavior, delegate to product-manager. When in doubt, always delegate.

**Execution options for TRIVIAL:**

**Option A: Delegate to product-manager (Recommended - delegation-first)**
```
Launch product-manager agent:
Task: Apply trivial change to spec/design
Change request: [user's request]
File(s): [spec and/or design file paths]
Constraint: Single-value fix only, no semantic changes
Output: Confirmation of change with before/after
```

**Option B: Direct Edit (Fallback only)**
1. Use Edit tool to apply the single-line change
2. Show user before/after diff
3. Run `git diff` to confirm change scope
4. If change affected more than intended lines, revert and escalate to SMALL

**Choose Option A by default (delegation-first principle). Use Option B only if:**
- User explicitly requests direct edit for speed
- Agent retry failed (after one retry attempt)
- Change is purely formatting (whitespace, markdown syntax only)

**Post-change verification (both options):**
- Run `git diff` to confirm only intended lines changed
- If more lines affected, warn user and offer to revert

#### For SMALL Changes

SMALL changes are minor edits that meet ALL of these criteria:
- **Line limit:** Less than 20 lines changed across all files
- **File limit:** Affects 1-2 files only
- **No architecture impact:** Does not change design decisions, data models, or API contracts
- **Low risk:** Typos, wording improvements, adding clarifications, minor requirement additions

**CRITICAL: Verify "No architecture impact" before classifying as SMALL:**
- Use verification-specialist's confidence score from Phase 3
- If confidence for "no architecture impact" < 90: escalate to MEDIUM
- If verification-specialist did not provide confidence: ask user for confirmation

If ANY criterion is not met, escalate to MEDIUM and recommend `/spec-review`.

**Delegate to product-manager:**

```
Launch product-manager agent:
Task: Apply small change to spec and design
Change request: [user's request]
Spec file: [spec file path]
Design file: [design file path]
Impact analysis: [summary from Phase 3]
Constraints:
- Less than 20 lines changed
- No architecture changes
- Maintain document consistency
Output:
- Summary of changes made
- Before/after for each modified section
```

**Present agent's output as diff summary:**
```
## Changes Applied

### Specification Updates
[from product-manager output]

### Design Updates
[from product-manager output]

Next: Run /quick-impl to implement these changes.
```

**Error Handling for SMALL execution:**
If product-manager fails or times out:
1. Retry once with single-file focus (spec or design, not both)
2. If retry fails, inform user:
   ```
   Small change application failed.

   Options:
   1. Retry with single-file scope
   2. Escalate to MEDIUM classification (use /spec-review)
   3. Cancel the change
   ```
3. Add to progress file: `"warnings": ["SMALL change application failed"]`

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

- For comprehensive spec/design analysis, delegate to `product-manager` or `code-architect` agent
- TRIVIAL changes: delegate to `product-manager` by default; direct Edit is fallback only (see Phase 5)
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
