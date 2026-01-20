---
description: "Launch the SDD (Specification-Driven Development) workflow - a guided 7-phase process from discovery to implementation with parallel agent execution"
argument-hint: "[optional: feature description]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task, TodoWrite
---

# /sdd - Specification-Driven Development Workflow

Launch a guided 7-phase development workflow that ensures disciplined, spec-first development with context-preserving subagent delegation.

## Official References

Based on:
- [Official feature-dev plugin](https://github.com/anthropics/claude-code/tree/main/plugins/feature-dev)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) - 6 Composable Patterns
- [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)

## Composable Patterns Applied

This workflow implements all 6 of Anthropic's composable patterns:

| Pattern | Application in /sdd |
|---------|---------------------|
| **Prompt Chaining** | 7 phases executed sequentially with gates |
| **Routing** | Model selection (Opus/Sonnet/Haiku), agent selection by task type |
| **Parallelization** | Multiple code-explorers, parallel reviewers in Phase 2, 4, 6 |
| **Orchestrator-Workers** | You (orchestrator) delegate to all subagents |
| **Evaluator-Optimizer** | Quality review with confidence scoring and iteration |
| **Augmented LLM** | Tools, progress files, retrieval for all agents |

See [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) for detailed pattern documentation.

## Phase Overview

This command orchestrates 7 phases:
1. **Discovery** - Understand what needs to be built
2. **Codebase Exploration** - Understand existing code and patterns (parallel agents)
3. **Clarifying Questions** - Fill gaps and resolve ambiguities
4. **Architecture Design** - Design multiple approaches (parallel agents)
5. **Implementation** - Build the feature
6. **Quality Review** - Ensure code meets standards (parallel agents)
7. **Summary** - Document what was accomplished

## Execution Instructions

---

## ⚠️ ORCHESTRATOR-ONLY RULES (NON-NEGOTIABLE)

**YOU ARE THE ORCHESTRATOR. YOU DO NOT DO THE WORK YOURSELF.**

### ABSOLUTE PROHIBITIONS for the Main Agent

1. **NEVER use Grep/Glob yourself** - Delegate to `code-explorer` or built-in `Explore`
2. **NEVER read more than 3 files directly** - Delegate bulk reading to subagents
3. **NEVER implement code yourself** - Delegate to `frontend-specialist` or `backend-specialist`
4. **NEVER write tests yourself** - Delegate to `qa-engineer`
5. **NEVER do security analysis yourself** - Delegate to `security-auditor`

### Your ONLY Responsibilities

1. **Orchestrate** - Launch and coordinate subagents
2. **Synthesize** - Combine subagent outputs into coherent summaries
3. **Communicate** - Present findings and ask user questions
4. **Track Progress** - Update TodoWrite and progress files
5. **Read Specific Files** - Only files identified by subagents (max 3 at a time)

### Why This Matters

From [Anthropic Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices):
> "Subagents use their own isolated context windows, and only send relevant information back to the orchestrator"

**Context consumption comparison**:
- Direct exploration: 10,000+ tokens consumed in main context
- Subagent exploration: ~500 token summary returned

**Long session enablement**:
- Clean main context = ability to work for hours
- Polluted main context = session ends prematurely

---

### Context Protection (The Most Important Rule)

**DO NOT explore code yourself. ALWAYS delegate to subagents.**

From [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices):

> "Subagents use their own isolated context windows, and only send relevant information back to the orchestrator, rather than their full context. This makes them ideal for tasks that require sifting through large amounts of information where most of it won't be useful."

The main orchestrator MUST:
- Remain focused on orchestration and coordination
- Never accumulate exploration results in main context
- Delegate ALL codebase exploration to `code-explorer` agents
- Delegate ALL implementation to specialist agents
- Only read specific files identified by subagents (max 3 at a time)

**Why This Matters (Quantified):**
```
Direct exploration by orchestrator: 10,000+ tokens consumed in main context
Subagent exploration:               ~500 token summary returned
Savings:                            95%+ context preservation
```

**Long Session Enablement:**
- Clean main context = ability to work for hours autonomously
- Polluted main context = session ends prematurely
- This is the key to completing complex, multi-day projects

| Agent | Model | Use For |
|-------|-------|---------|
| `code-explorer` | Sonnet | Deep codebase analysis (4-phase exploration) |
| Built-in `Explore` | Haiku | Quick lookups and simple searches |
| `product-manager` | **Opus** | Requirements gathering (deep reasoning for ambiguous requests) |
| `system-architect` | **Opus** | System-level design (ADRs, schemas, contracts) - deep reasoning |
| `code-architect` | Sonnet | Feature-level implementation blueprints |
| `frontend-specialist` | **inherit** | UI implementation (uses your session's model) |
| `backend-specialist` | **inherit** | API implementation (uses your session's model) |
| `qa-engineer` | Sonnet | Testing and quality review |
| `security-auditor` | Sonnet | Security review (read-only) |

**Model Selection Strategy**:
- **Opus**: Complex reasoning, architectural decisions, requirements elicitation (system-architect, product-manager)
- **Sonnet**: Balanced capability for analysis and implementation
- **Haiku**: Fast, lightweight exploration (built-in Explore)
- **inherit**: Match parent conversation model (implementation agents)

### Phase 1: Discovery

**Goal:** Understand what needs to be built and why.

If the user provided a feature description (`$ARGUMENTS`), analyze it first:
- What problem is being solved?
- Who are the target users?
- What are potential constraints?

If the request is vague or missing:
1. Ask clarifying questions using AskUserQuestion
2. Identify stakeholders and use cases
3. Document initial understanding

**Output:** Summary of understanding and confirmation from user.

### Phase 2: Codebase Exploration

**Goal:** Understand relevant existing code and patterns.

**LAUNCH 2-3 `code-explorer` AGENTS IN PARALLEL:**

```
Launch these code-explorer agents in parallel:

1. code-explorer (similar features)
   Task: Explore existing implementations of similar features
   Thoroughness: medium
   Output: Entry points, execution flow, key files

2. code-explorer (architecture)
   Task: Map the overall architecture and patterns used
   Thoroughness: medium
   Output: Layers, boundaries, conventions

3. code-explorer (UI patterns) - if frontend work
   Task: Trace UI component patterns and state management
   Thoroughness: medium
   Output: Component hierarchy, data flow
```

**Wait for all agents to complete.** Each returns:
- Entry points with file:line references
- Key components and responsibilities
- Architecture insights
- Files to read for deep understanding

**Read all identified key files** to build comprehensive understanding.

**Present comprehensive summary of findings to user.**

### Phase 3: Clarifying Questions

**Goal:** Fill in gaps and resolve all ambiguities.

Based on discovery and exploration, identify:
- Edge cases
- Error handling requirements
- Integration points
- Backward compatibility needs
- Performance requirements

**Ask clarifying questions using AskUserQuestion.**

**CRITICAL: Wait for user answers before proceeding.**

**Output:** Complete requirements with all ambiguities resolved.

### Phase 4: Architecture Design

**Goal:** Design the implementation approach based on codebase patterns.

**Design Philosophy (Intentional Difference from Official Pattern):**

The official `feature-dev` plugin presents 3 distinct approaches for user selection. This plugin instead uses multiple code-architect agents to **analyze from different angles, then synthesize into a single definitive recommendation**. This reduces decision fatigue while ensuring comprehensive analysis.

**LAUNCH 2-3 `code-architect` AGENTS IN PARALLEL with different analysis focuses:**

```
Launch these code-architect agents in parallel:

1. code-architect (reuse analysis)
   Analyze: How existing patterns and code can be reused
   Context: [Exploration findings], [Requirements]
   Output: Reuse opportunities with file:line evidence

2. code-architect (extensibility analysis)
   Analyze: Clean abstraction opportunities for future growth
   Context: [Exploration findings], [Requirements]
   Output: Abstraction recommendations with file:line evidence

3. code-architect (performance analysis) - if relevant
   Analyze: Performance implications and optimizations
   Context: [Exploration findings], [Requirements]
   Output: Performance considerations with file:line evidence
```

**Each agent contributes analysis from their focus area.**

**Synthesize all agent outputs into ONE definitive recommendation:**
```markdown
## Architecture Analysis

### Pattern Analysis from Codebase
Based on code-architect findings:
- Service pattern: [Pattern] (see `file:line`)
- Data access: [Pattern] (see `file:line`)
- API structure: [Pattern] (see `file:line`)

### Recommended Approach

**Architecture**: [Summary of recommended approach]

**Rationale**:
- Aligns with existing pattern at `file:line`
- Follows convention in `file:line`
- [Other evidence-based reasons]

**Implementation Map**:
| Component | File | Action |
|-----------|------|--------|
| [Name] | `src/...` | Create |
| [Name] | `src/...` | Modify |

**Build Sequence**:
- [ ] Step 1: [Task]
- [ ] Step 2: [Task]
- [ ] Step 3: [Task]

**Trade-offs Considered**:
- [Trade-off 1]: [Why this choice is best]
- [Trade-off 2]: [Why this choice is best]
```

**Ask user: "Does this approach work for you? Any concerns?"**

**Output:** Approved design saved to `docs/specs/[feature-name]-design.md`

### Phase 5: Implementation

**Goal:** Build the feature according to spec and design.

**IMPORTANT:** Wait for explicit user approval before starting implementation.

Ask user: "Ready to start implementation? This will modify files in your codebase."

---

#### Long-Running Autonomous Work Pattern

Based on [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

> "The agent tends to try to do too much at once—essentially attempting to one-shot the app."

**The Initializer + Coding Pattern:**

| Role | When | What to Do |
|------|------|------------|
| **INITIALIZER** | No progress file exists | Create progress files, break down work, set up state |
| **CODING** | Progress file exists | Read state, implement ONE feature, update state, commit |

**Workspace ID:**

Use the workspace ID shown in SessionStart hook output. Format: `{branch}_{path-hash}` (e.g., `main_a1b2c3d4`).

**Progress File Structure:**

Create `.claude/workspaces/{workspace-id}/claude-progress.json`:
```json
{
  "workspaceId": "[workspace-id]",
  "project": "[feature-name]",
  "status": "in_progress",
  "currentTask": "Implementing [component]",
  "startedAt": "[ISO timestamp]",
  "resumptionContext": {
    "position": "Phase 5 - Implementation",
    "nextAction": "Create [specific file]",
    "completedSteps": ["step1", "step2"],
    "blockers": []
  }
}
```

Create `.claude/workspaces/{workspace-id}/feature-list.json`:
```json
{
  "workspaceId": "[workspace-id]",
  "features": [
    {"id": "F001", "name": "[Component 1]", "status": "completed", "files": ["src/..."]},
    {"id": "F002", "name": "[Component 2]", "status": "in_progress", "files": []},
    {"id": "F003", "name": "[Component 3]", "status": "pending", "files": []}
  ]
}
```

**Workspace ID Format:** `{branch}_{path-hash}` (e.g., `main_a1b2c3d4`)

**Why JSON?** From Anthropic: "Models are less likely to inappropriately modify structured data."

---

#### CRITICAL: One Feature at a Time

**Solution**: Focus on ONE feature/component per iteration:
1. Identify next incomplete feature from `feature-list.json`
2. Delegate implementation to specialist agent
3. Wait for completion
4. Run tests (delegate to `qa-engineer`)
5. Update progress files (`claude-progress.json`, `feature-list.json`)
6. Commit working code with descriptive message
7. Move to next feature

**NEVER proceed to next feature until current one is:**
- Implemented
- Tested
- Committed
- Progress files updated

---

#### TDD Integration (Optional but Recommended)

For features with clear acceptance criteria, use Test-Driven Development:

```
TDD Cycle for Each Feature:

1. RED: Delegate to qa-engineer
   "Write failing tests for [feature] based on acceptance criteria"
   Output: Test file created, tests run and FAIL

2. GREEN: Delegate to frontend/backend-specialist
   "Implement minimal code to pass tests at [test-file]"
   Output: Implementation created, ALL tests PASS

3. REFACTOR: Delegate to code-architect (review) then specialist
   "Review implementation for quality, suggest improvements"
   Output: Clean code, tests still PASS
```

See `skills/workflows/tdd-workflow/SKILL.md` for complete TDD patterns.

**When to use TDD:**
- Features with clear input/output expectations
- Bug fixes (write test that reproduces bug first)
- Critical path functionality
- Refactoring existing code

---

#### Delegation to Specialist Agents

**REMEMBER: You are the orchestrator. You do NOT implement code yourself.**

Note: `frontend-specialist` and `backend-specialist` use `model: inherit`, so they will use whatever model the user's session is running (Opus for highest quality, Sonnet for balance).

For frontend work:
```
Launch the frontend-specialist agent to implement: [component/feature]
Following specification: docs/specs/[feature-name].md
Following design: docs/specs/[feature-name]-design.md
Key files from exploration: [list]
TDD mode: [yes/no] - If yes, reference test file
Expected output: Working component with tests
```

For backend work:
```
Launch the backend-specialist agent to implement: [service/API]
Following specification: docs/specs/[feature-name].md
Following design: docs/specs/[feature-name]-design.md
Key files from exploration: [list]
TDD mode: [yes/no] - If yes, reference test file
Expected output: Working service with tests
```

**After each specialist agent completes:**
1. Verify the agent's output summary
2. Update `feature-list.json` (mark feature as completed)
3. Update `claude-progress.json` (update currentTask, nextAction)
4. Run TodoWrite to update visible progress
5. Ask user if they want to review before committing

---

#### Progress Tracking Integration

**TodoWrite + JSON Files work together:**

```
TodoWrite: Real-time UI for user visibility
JSON Files: Persistent state for session resumption
```

Update BOTH after each milestone:
1. Mark TodoWrite item as completed
2. Update JSON files
3. Git commit with descriptive message

**Track progress** using TodoWrite tool. Update status as each component completes.

**Update progress file** after each significant milestone.

### Phase 6: Quality Review

**Goal:** Ensure code meets quality, security, and spec requirements.

**LAUNCH 3 PARALLEL REVIEW AGENTS (Sonnet):**

```
Launch these review agents in parallel:

1. qa-engineer agent
   Focus: Test coverage, edge cases, acceptance criteria
   Confidence threshold: 80
   Check: Tests exist, edge cases handled, acceptance criteria met
   Output: Test gaps, quality issues with file:line

2. security-auditor agent
   Focus: OWASP Top 10, auth/authz, data validation
   Confidence threshold: 80
   Check: Input validation, auth checks, sensitive data handling
   Output: Vulnerabilities with file:line and remediation

3. code-explorer agent (verification)
   Focus: Verify implementation matches design spec
   Thoroughness: quick
   Compare: Implementation vs docs/specs/[feature]-design.md
   Output: Deviations, missing pieces with file:line
```

**Score each issue with Haiku agents** (same pattern as /code-review):

```
For each issue, launch parallel Haiku agent:
- Issue description
- Context
- Score 0-100 based on rubric
```

**Consolidate findings with confidence weighting:**

| Scenario | Action |
|----------|--------|
| Score < 80 | Filter out |
| 1 agent reports (80+) | Report as-is |
| 2 agents agree | Boost confidence |
| 3 agents agree | Treat as confirmed |

**Present findings to user:**
```markdown
## Quality Review Results

### Critical Issues (Confidence >= 90)
1. **[Issue Title]** - [Category] (Score: [N])
   File: `file:line`
   [Description]
   **Fix:** [Remediation]

### Important Issues (Confidence 80-89)
1. **[Issue Title]** - [Category] (Score: [N])
   File: `file:line`
   [Description]
   **Fix:** [Remediation]

### Summary
- Critical: [N]
- Important: [N]
- Filtered (below 80): [N]

**Verdict:** [APPROVED / NEEDS CHANGES]
```

**Ask user:** "Found [N] issues. What would you like to do?"
1. Fix critical issues now
2. Fix all issues now
3. Proceed without changes
4. Get more details on specific issues

**Address issues based on user decision.**

#### Evaluator-Optimizer Loop (For Critical Issues)

If critical issues are found and user chooses to fix:

```
Iteration Loop (max 3):

1. GENERATOR: Delegate fix to specialist agent
   "Fix [issue] at [file:line]"
   Output: Modified code

2. EVALUATOR: Delegate re-check to original reviewer
   "Verify fix for [issue] at [file:line]"
   Output: Score 0-100

3. If score >= 80: Accept and move to next issue
   If score < 80: Provide feedback, loop back to GENERATOR
   If max iterations reached: Escalate to user
```

See `skills/workflows/evaluator-optimizer/SKILL.md` for detailed pattern.

#### Error Recovery During Review

If review agents encounter errors:

1. **Checkpoint current state** to progress file
2. **Document the error** with full context
3. **Attempt recovery** using error-recovery skill patterns
4. **If unrecoverable**: Present options to user
   - Retry with different approach
   - Skip this check
   - Abort and investigate

See `skills/workflows/error-recovery/SKILL.md` for recovery patterns.

### Phase 7: Summary

**Goal:** Document what was accomplished.

**Update progress file to completed status.**

Create summary including:
- What was built
- Key decisions made
- Files modified/created
- Test coverage achieved
- Security review status
- Suggested next steps

**Mark all todos complete.**

**Output:** Summary displayed to user.

```markdown
## Implementation Complete

### What Was Built
- [Feature description]

### Key Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

### Files Modified
| File | Changes |
|------|---------|
| `path/to/file.ts` | [Summary] |

### Quality Status
- Tests: [Passing/Failing]
- Security: [Approved/Issues]
- Coverage: [Percentage]

### Next Steps
1. [Suggested follow-up 1]
2. [Suggested follow-up 2]
```

## Usage Examples

```bash
# Start with a feature idea
/sdd Add user authentication with OAuth support

# Start from scratch (interactive)
/sdd

# Start with existing requirements
/sdd Implement the feature specified in docs/specs/user-dashboard.md
```

## Tips for Best Results

1. **Be patient with exploration** - Phase 2 prevents misunderstanding the codebase
2. **Answer clarifying questions thoughtfully** - Phase 3 prevents future confusion
3. **Choose architecture deliberately** - Phase 4 options exist for a reason
4. **Don't skip security review** - Phase 6 catches issues before production
5. **Read agent outputs carefully** - They contain important file:line references

## When NOT to Use

- Single-line bug fixes (just fix it directly)
- Trivial changes with clear scope
- Urgent hotfixes requiring immediate deployment
- Use `/quick-impl` for small, well-defined tasks

## Comparison with /quick-impl

| Aspect | /sdd | /quick-impl |
|--------|------|-------------|
| Phases | 7 | 1 |
| Exploration | Parallel agents | None |
| Design options | Multiple | Single |
| Review | Parallel agents | Basic |
| Best for | Complex features | Small tasks |
