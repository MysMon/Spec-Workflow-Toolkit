---
description: "Interactively review and refine a spec and design with the user - feedback loop until approved"
argument-hint: "[path to spec file or feature name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, TodoWrite, Skill
---

# /spec-review - Interactive Plan Review

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

Review a specification and design document interactively with the user. This is a **user-driven feedback loop** — the user reads the plan, gives feedback, and the plan is revised until approved.

For automated machine review, use `--auto` to run parallel review agents before the feedback loop.

## Two Review Modes

| Mode | Command | What Happens |
|------|---------|--------------|
| **Interactive** (default) | `/spec-review feature.md` | User reads plan, gives feedback, iterate |
| **Auto + Interactive** | `/spec-review feature.md --auto` | 5 agents review first, then user feedback loop |

## Execution Instructions

### Step 1: Locate Spec and Design

**CRITICAL: Do NOT read spec/design files directly. ALWAYS delegate to subagent.**

This applies to ALL steps including the feedback loop in Step 4. The orchestrator never edits spec/design files directly - delegate to product-manager.

If `$ARGUMENTS` is provided:
- If it's a file path, use Glob to verify the file exists (do NOT read it directly)
- If it's a feature name, search in `docs/specs/` directory using Glob

**Also locate the corresponding design document:**
- If spec is `docs/specs/user-auth.md`, look for `docs/specs/user-auth-design.md` using Glob

If no arguments:
- List available specs in `docs/specs/` using Glob
- Ask user which one to review

**Delegate content loading to `product-manager` agent:**

```
Launch product-manager agent:
Task: Summarize spec and design for review presentation
Inputs: Spec file path + Design file path (if exists)
Output:
- Key requirements list
- Architecture summary
- Build sequence
- Trade-offs and decisions
```

Use the agent's summary output for presenting to user. Do NOT read spec/design files directly.

### Step 2: Auto Review (only if `--auto` flag is present)

**If `--auto` is specified**, launch 5 parallel review agents before the user feedback loop:

**CRITICAL: Launch all agents in a single message.**

```
1. product-manager: Completeness review
2. system-architect: Technical feasibility review (spec + design)
3. security-auditor: Security review (spec + design)
4. qa-engineer: Quality/testability review
5. verification-specialist: Spec↔design consistency check (if design exists)
```

**Delegate result consolidation to verification-specialist agent:**
```
Launch verification-specialist agent:
Task: Consolidate review results from 5 agents
Rules:
- Filter by confidence (>= 80)
- De-duplicate across agents (boost confidence by 10 when multiple agents agree)
- Categorize: spec-only / design-only / both
- Sort by severity
Output: Consolidated findings list with confidence scores
```

Use the agent's consolidated output for presentation. Do NOT consolidate results manually.

**Error Handling for verification-specialist:**
If verification-specialist fails or times out:
1. Present raw findings from the 5 review agents without consolidation
2. Warn user: "Auto-review consolidation failed. Showing raw agent findings (duplicates not merged)."
3. Proceed with user feedback loop using unfiltered findings
4. Consider duplicates as potential high-confidence issues

**Present auto-review results to user:**
```markdown
## Auto-Review Results

Found [N] issues ([X] critical, [Y] important).

### Critical Issues (>= 90)
1. **[Title]** ([Category], affects [Spec/Design/Both])
   [Description]
   Suggested fix: [fix]

### Important Issues (80-89)
...

These will be incorporated into the feedback loop below.
```

**Apply auto-fixes for issues where:**
- Confidence >= 90
- Fix is a simple addition (e.g., adding a missing "Out of Scope" section)
- Fix does NOT change architecture decisions or user-approved requirements
- Always inform the user what was auto-fixed

**Escalate to user** any issue that:
- Changes architecture or core design decisions
- Contradicts user-approved spec requirements
- Has confidence 80-89 (ambiguous)

### Step 3: Present Plan for User Review

Display both spec and design (or summaries for long documents), then provide **guided review questions** to help the user focus:

```
Here is your plan. I'll walk you through key areas to check.

## Guided Review

1. **Requirements**: Do these capture what you want to build?
   [List key requirements from spec]

2. **Architecture**: Does this approach fit your codebase and team?
   [Summary of approach from design]

3. **Build Sequence**: Is this order realistic?
   [Build sequence from design]

4. **Security & Edge Cases**: Anything missing?
   [Key security items and edge cases from spec]

5. **Trade-offs**: Do you agree with these choices?
   [Trade-offs from design]

What would you like to change? (Or "approve" if it looks good)
```

### Step 4: User Feedback Loop

**Loop until the user approves or exits.**

#### Handling Ambiguous Feedback

**CRITICAL:** When user feedback is unclear or contains multiple possible interpretations:

1. **MUST use AskUserQuestion** to present structured options
2. **Do NOT guess** the user's intent
3. Frame questions with concrete trade-offs

Example scenarios requiring AskUserQuestion:

| User Says | Use AskUserQuestion To |
|-----------|----------------------|
| "Make it faster" | Ask: Faster load time? Faster response? Faster build? |
| "Add better error handling" | Ask: Which errors? User-facing messages? Logging? Recovery? |
| "This feels too complex" | Ask: Simplify API? Reduce features? Split into phases? |
| "I'm not sure about this" | Ask: What concerns them? Present alternatives with trade-offs |

After each user message, determine the feedback type:

| User Says | Action |
|-----------|--------|
| "approve" / "looks good" / "LGTM" | Exit loop → Step 5 |
| Specific change request (e.g., "use sessions instead of JWT") | Apply change → re-present affected section |
| Question (e.g., "why did you choose PostgreSQL?") | Answer from design rationale, ask if they want to change it |
| "add X" (new requirement) | Add to spec, check if design needs updating |
| "remove X" | Remove from spec, check if design needs updating |
| "I'm not sure about X" | Discuss trade-offs, present alternatives if relevant |
| "start over" / "re-plan" | Suggest re-running `/spec-plan` |

#### Handling Changes That Affect Architecture

**CRITICAL: The orchestrator does NOT edit spec/design files directly. ALWAYS delegate.**

**If a change is small** (wording, adding an edge case, clarifying a requirement):

Delegate to product-manager:
```
Launch product-manager agent:
Task: Apply small change to spec/design during review
Change request: [user's feedback]
Spec file: [spec file path]
Design file: [design file path] (if applicable)
Constraint: Wording/clarification only, no architecture changes
Output: Summary of changes with before/after
```

Re-present the changed section using agent output.

**If a change requires re-architecture** (e.g., "use a different database", "change the auth approach"):
1. Inform the user: "This change affects the architecture design. I have two options:"
   - **Option A**: I'll delegate to code-architect for design analysis, then product-manager for edits (best-effort, no re-exploration)
   - **Option B**: Re-run `/spec-plan` with this new constraint for a thorough re-analysis
2. If Option A:
   - Delegate design revision analysis to code-architect agent
   - Delegate actual edits to product-manager agent using code-architect's output
   - Re-present the updated design, continue loop
3. If Option B: update progress file, exit, suggest `/spec-plan` command

#### After Each Change

After applying a change:
```
Updated [spec/design/both]. Here's what changed:

[Summary of change]

Anything else to change? (Or "approve" to finalize)
```

### Step 5: Approval and Handoff

When the user approves:

1. **Save final versions** of spec and design files
2. **Save review log** to `docs/specs/[feature-name]-review.md`:
   ```markdown
   ## Review Log: [Feature Name]

   ### Review Mode
   [Interactive / Auto + Interactive]

   ### Changes Made
   1. [Change description] (user requested)
   2. [Change description] (auto-review fix)
   ...

   ### Auto-Review Issues (if --auto was used)
   - Resolved: [N]
   - Deferred: [N]

   ### Verdict
   APPROVED by user
   ```

3. **Update progress file**:
   ```json
   {
     "currentPhase": "review-complete",
     "currentTask": "Review complete - approved by user",
     "resumptionContext": {
       "nextAction": "Run /spec-implement to begin implementation",
       "reviewVerdict": "APPROVED",
       "changesApplied": [N]
     }
   }
   ```

4. **Present next step:**
   ```
   Plan approved. Run `/spec-implement docs/specs/[feature-name].md` to start building.
   ```

## Usage Examples

```bash
# Interactive review (user feedback only)
/spec-review docs/specs/user-authentication.md

# Auto review first, then user feedback
/spec-review docs/specs/user-authentication.md --auto

# Review by feature name
/spec-review user-authentication

# Interactive - list and choose
/spec-review
```

---

## Rules (L1 - Hard)

- ALWAYS present guided review questions (don't just say "any feedback?")
- ALWAYS loop until user explicitly approves or exits
- NEVER auto-fix changes that affect architecture or user-approved requirements
- ALWAYS update progress file on completion
- ALWAYS save review log
- ALWAYS use AskUserQuestion when:
  - User feedback contains multiple possible interpretations
  - A decision requires choosing between trade-offs (e.g., "should we prioritize X or Y?")
  - Clarification is needed before making changes to spec or design
- NEVER guess user intent when feedback is ambiguous — ask first

## Defaults (L2 - Soft)

- Present full guided review on first pass; show only changed sections on subsequent passes
- For `--auto` mode, apply fixes with confidence >= 90 that don't change architecture
- Save review log to docs/specs/[feature-name]-review.md
- Boost auto-review confidence by 10 when multiple agents agree

## Guidelines (L3)

- Consider presenting alternatives when user is unsure
- For large spec/design documents, summarize sections rather than displaying everything
