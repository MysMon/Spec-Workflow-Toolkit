---
description: "Launch the SDD (Specification-Driven Development) workflow - a guided 7-phase process from discovery to implementation with parallel agent execution"
argument-hint: "[optional: feature description]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task, TodoWrite
---

# /sdd - Specification-Driven Development Workflow

Launch a guided 7-phase development workflow that ensures disciplined, spec-first development with context-preserving subagent delegation.

Based on [Anthropic's official feature-dev plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/feature-dev).

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

### CRITICAL: Context Protection (The Most Important Rule)

**DO NOT explore code yourself. ALWAYS delegate to subagents.**

The main orchestrator MUST:
- Remain focused on orchestration and coordination
- Never accumulate exploration results in main context
- Delegate ALL codebase exploration to `code-explorer` agents
- Delegate ALL implementation to specialist agents
- Only read specific files identified by subagents

Why this matters:
- Context windows are limited
- Long autonomous sessions require clean context
- Subagents run in isolated windows, protecting main context
- Only summaries return, not full exploration data

| Agent | Model | Use For |
|-------|-------|---------|
| `code-explorer` | Sonnet | Deep codebase analysis (4-phase exploration) |
| Built-in `Explore` | Haiku | Quick lookups and simple searches |
| `product-manager` | Sonnet | Requirements gathering |
| `system-architect` | **Opus** | System-level design (ADRs, schemas, contracts) - deep reasoning |
| `code-architect` | Sonnet | Feature-level implementation blueprints |
| `frontend-specialist` | **inherit** | UI implementation (uses your session's model) |
| `backend-specialist` | **inherit** | API implementation (uses your session's model) |
| `qa-engineer` | Sonnet | Testing and quality review |
| `security-auditor` | Sonnet | Security review (read-only) |

**Model Selection Strategy**:
- **Opus**: Complex reasoning, architectural decisions (system-architect)
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

**CRITICAL: One Feature at a Time**

Based on [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):
> "The agent tends to try to do too much at once—essentially attempting to one-shot the app."

**Solution**: Focus on ONE feature/component per iteration:
1. Implement one component
2. Test it thoroughly
3. Update progress file
4. Commit working code
5. Move to next component

**Initialize Progress Tracking:**
```
Create .claude/claude-progress.json with:
- Project: [feature name]
- Status: in_progress
- Features to implement
- Resumption context
```

**DELEGATE TO specialist agents:**

Note: `frontend-specialist` and `backend-specialist` use `model: inherit`, so they will use whatever model the user's session is running (Opus for highest quality, Sonnet for balance).

For frontend work:
```
Launch the frontend-specialist agent to implement: [component/feature]
Following specification: docs/specs/[feature-name].md
Following design: docs/specs/[feature-name]-design.md
Key files from exploration: [list]
```

For backend work:
```
Launch the backend-specialist agent to implement: [service/API]
Following specification: docs/specs/[feature-name].md
Following design: docs/specs/[feature-name]-design.md
Key files from exploration: [list]
```

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
