# Spec-Workflow Toolkit - Development Guide

Detailed specifications for plugin contributors. For user documentation, see `README.md`.

---

## Design Philosophy

### Why This Plugin Exists

**Problem**: Claude struggles with complex, long-running development tasks due to context exhaustion.

**Solution**: Orchestrator pattern with specialized subagents that isolate exploration and return only summaries.

### Intentional Differences from Official Patterns

| Aspect | Official `feature-dev` | This Plugin | Rationale |
|--------|------------------------|-------------|-----------|
| Architecture options | 3 approaches | Single definitive | Reduces decision fatigue |
| Progress format | `.txt` | `.json` | Machine-readable, less prone to corruption |
| Progress isolation | Project-level | Workspace-level | Supports git worktrees, concurrent projects |
| Agent specialization | 3 general | 13 specialized | Domain expertise improves quality |

### Context Management

From Claude Code Best Practices:

> "Subagents use their own isolated context windows, and only send relevant information back to the orchestrator."

| Approach | Context Cost | Result |
|----------|-------------|--------|
| Direct exploration | 10,000+ tokens | Context exhaustion |
| Subagent exploration | ~500 token summary | Clean main context |

#### Command Delegation Guidelines

Commands should delegate to subagents to preserve the orchestrator's context window. However, not everything needs delegation.

**MUST delegate (context-heavy):**

| Task | Delegate To |
|------|-------------|
| Spec/design file reading and analysis | `product-manager` |
| Codebase exploration and context gathering | `code-explorer` |
| Multi-file changes or complex logic | Appropriate specialist |
| CI log analysis | `code-explorer` |
| Documentation discovery | `code-explorer` |

**Direct execution OK (minimal context):**

| Task | Why Direct is OK |
|------|------------------|
| SMALL changes (minor edits to spec/design) | Single Edit tool call, minimal tokens |
| Single config value changes | One-line modification |
| File existence checks | Glob returns paths only, not content |
| Presenting summaries from agent output | Already summarized |

**Metadata Files Exception (progress files, feature-list.json):**

Progress files and other orchestrator metadata are exceptions to the delegation rule. When reading these files directly, include a justification block:

```markdown
**Why progress file reading is acceptable (not delegated):**
- Progress files are orchestrator state metadata (not project content)
- Status checking is quick validation (typically <20 lines of JSON)
- Essential to [specific purpose: avoid duplicate work / determine review status / etc.]
- Minimal context consumption compared to spec/design content analysis
- Consistent with resume.md Phase 3 pattern
```

**Key distinction:**
- **Spec/design files** → MUST delegate (content analysis)
- **Progress/metadata files** → Direct read OK with justification (state validation)

**Anti-pattern: Over-delegation**

Delegating trivial tasks wastes subagent resources and adds latency:

```markdown
# BAD: Delegating a one-line edit
Launch product-manager agent:
Task: Edit spec to change "1 hour" to "24 hours"

# GOOD: Direct edit for minor changes
Use Edit tool to change "1 hour" to "24 hours" in spec file
```

### Phase Consistency Rule

Commands with multiple phases must ensure routing instructions and execution instructions are consistent. This is a common source of contradictions.

**Anti-pattern: Phase Contradiction**

```markdown
# Phase 4: Routing (what user sees)
TRIVIAL changes: "I can apply this directly."
If yes: Apply fix directly using Edit tool.

# Phase 5: Execution (what orchestrator does)
CRITICAL: Even for TRIVIAL changes, delegate to product-manager agent.
```

The user message promises "direct" action, but execution delegates. This confuses both the user and the orchestrator.

**Correct Pattern:**

```markdown
# Phase 4: Routing (aligned with execution)
TRIVIAL changes: "I'll delegate to product-manager to apply it."
If yes: Proceed to Phase 5 (via product-manager delegation).

# Phase 5: Execution (consistent with routing)
Delegate to product-manager agent...
```

**Verification checklist:**
1. User-facing messages in routing phase match actual execution behavior
2. "Direct" vs "delegate" language is consistent across phases
3. If delegation is required in execution, routing should mention delegation

### Agent Failure Handling Pattern

When delegating to subagents, commands MUST include error handling for agent failures (timeout, crash, incomplete output).

**Standard Pattern:**

```markdown
**Error Handling for [agent-name]:**
If [agent-name] fails or times out:
1. Check the agent's partial output for usable findings
2. Retry once with reduced scope (if critical)
3. Proceed with available results (if non-critical), documenting the gap
4. Escalate to user if critical agent fails after retry
```

**Multiple Parallel Agents Pattern:**

When launching multiple agents in parallel (e.g., 5 review agents in spec-review), handle failures individually and collectively:

```markdown
**Error Handling for parallel agents:**

For each agent individually:
If [agent] fails or times out:
1. Check partial output for usable findings
2. Retry once with reduced scope
3. If retry fails, proceed with available results and note gap
4. Add warning: "[Agent] review incomplete"

**CRITICAL: [critical-agent] failure handling:**
If [critical-agent] fails after retry:
1. Warn user prominently
2. Require explicit acknowledgment before proceeding

If ALL agents fail:
1. Inform user: "Cannot proceed without any successful results."
2. Offer options: Retry / Skip / Cancel
3. Do NOT auto-proceed without user decision
```

**User-Choice Fallback Pattern:**

When the orchestrator cannot make a classification or decision due to agent failure, delegate the decision to the user instead of attempting manual classification:

```markdown
**Error Handling for consolidation failure:**
If verification-specialist fails or times out:
1. Present raw findings from available agents
2. Warn user about consolidation failure
3. Present classification options to user:
   "Based on available analysis, please help me classify:"
   1. Option A
   2. Option B
   3. Option C
4. Proceed with user-selected option

**CRITICAL:** Do NOT attempt manual classification. Let the user decide.
```

**Why this matters:** If the orchestrator is prohibited from reading spec/design files directly, it cannot perform "manual classification" or "best-effort analysis" when consolidation agents fail. The user must make the decision.

**Implementation by Command Type:**

| Command Type | On Agent Failure |
|--------------|------------------|
| **Exploration** (spec-plan, code-review) | Use partial output, note gaps in report |
| **Implementation** (quick-impl, spec-implement) | Retry with single-file focus, then ask user |
| **Time-Critical** (hotfix) | Emergency override with user confirmation |
| **Verification** (spec-review, ci-fix) | Continue with successful agents, note coverage gaps |

**Example from quick-impl.md:**

```markdown
**Error Handling for specialist agent:**
If specialist agent fails or times out:
1. Check the agent's partial output for usable code
2. Retry once with simplified scope (single file focus)
3. If retry fails, inform user with specific error and offer options:
   - "Try again with different approach"
   - "Switch to /spec-plan for proper planning"
   - "I'll handle manually (understanding the risks)"
```

### Parallel Verification Pattern

When high confidence is required for verifying complex changes (delegation patterns, feature completeness), use multiple independent agents to validate the same criteria.

**When to Use:**
- Cross-cutting concerns affecting multiple commands/agents
- Verifying adherence to core patterns (delegation rules, error handling)
- Pre-release quality checks
- After large refactoring

**Pattern:**

1. Define verification criteria clearly (same prompt for all agents)
2. Launch N agents (typically 3-5) with identical instructions
3. Collect findings independently (no cross-contamination)
4. Prioritize issues by consensus

**Consensus-Based Prioritization:**

| Agents Reporting | Priority | Action |
|------------------|----------|--------|
| Majority (3+ of 5) | High | Fix immediately |
| Multiple (2 of 5) | Medium | Review carefully, likely fix |
| Single (1 of 5) | Low | May be false positive, review manually |

**Example: Delegation Pattern Verification**

```markdown
Launch 5 verification agents in parallel:
Task: Review all commands for delegation pattern consistency.
Criteria:
1. Do commands delegate context-heavy tasks to subagents?
2. Are exceptions (progress file reads) justified?
3. Is error handling present for all agent calls?

Results:
- 5/5 identified: Missing error handling in spec-plan Self-Review → HIGH
- 2/5 identified: spec-implement context loading needs error handling → MEDIUM
- 1/5 identified: Minor terminology inconsistency → LOW (review manually)
```

**Benefits:**
- Reduces false positives (single-agent may over-flag)
- Increases coverage (different agents notice different issues)
- Provides confidence scoring through agreement

**Constraints:**
- Higher token cost (N agents × task tokens)
- Use for high-impact verification only, not trivial checks
- Requires clear, reproducible criteria

### Emergency Override Pattern (Time-Critical Commands)

For time-critical commands like `/hotfix`, strict delegation rules can be relaxed when agents are unresponsive. This pattern balances safety with urgency.

**When to Apply:**

- Production outages requiring immediate fixes
- Agent timeouts exceeding defined thresholds
- User has confirmed the emergency nature

**Threshold Guidelines:**

| Phase | Timeout Threshold | Override Action |
|-------|-------------------|-----------------|
| Context gathering | 60 seconds | Manual minimal check (single git command) |
| Issue localization | 90 seconds | Emergency direct search (single Grep) |
| Implementation | 2 minutes | User-confirmed manual fix with documentation |

**Required Safeguards:**

1. **User confirmation**: Always ask before manual override
2. **Documentation**: Record "emergency manual fix" or "agent timeout" in commit message
3. **Minimal scope**: Only the absolute minimum direct action needed
4. **Post-fix verification**: Still run tests before pushing

**Example from hotfix.md:**

```markdown
**Error Handling (Emergency Override):**
If specialist agent fails or takes more than 2 minutes:
1. Check agent's partial output for usable fix
2. Retry once with explicit single-file focus
3. If retry fails: inform user and offer emergency manual fix option:
   ```
   Question: "Agent timed out. This is an emergency - can I apply the fix manually?"
   Header: "Emergency Override"
   Options:
   - "Yes, apply minimal fix directly" (understand the risks)
   - "No, wait and retry with agent"
   - "Abort hotfix and try /debug instead"
   ```
4. If user approves manual fix: apply minimal change, document "emergency manual fix" in commit
```

### Agent Tool Constraints

Some agents are intentionally READ-ONLY to ensure analysis integrity. Commands must respect these constraints when delegating.

**READ-ONLY Agents (cannot modify files):**

| Agent | disallowedTools | Role |
|-------|-----------------|------|
| code-explorer | Write, Edit, Bash | Codebase analysis |
| code-architect | Write, Edit, Bash | Architecture design |
| verification-specialist | Write, Edit, Bash | Fact-checking findings |
| security-auditor | Write, Edit | Security audit |
| ui-ux-designer | Bash, Edit | Design specification |

**Common Mistake:**

```markdown
# BAD: Delegating implementation to read-only agent
Launch code-architect agent:
Task: Implement the merge conflict resolution
```

**Correct Approach:**

```markdown
# GOOD: Use read-only agent for analysis, delegate implementation to specialist
Launch code-architect agent:
Task: Analyze both versions and recommend merge strategy

# Then delegate implementation to appropriate specialist
Launch frontend-specialist agent:
Task: Implement the merge based on code-architect's recommendation
```

**Split Verification Pattern:**

When verification requires both analysis (read-only) and execution (Bash):

```markdown
**Step 1: Launch verification-specialist for analysis (Read-only):**
Task: Check for conflict markers, validate syntax

**Step 2: Launch qa-engineer for execution (has Bash):**
Task: Run linter, type check, and tests
```

---

## Instruction Design Guidelines

Based on Anthropic's research and community best practices for balancing accuracy with creative problem-solving.

### The Bounded Autonomy Principle

From Claude Code Best Practices:

> "Claude often performs better with high level instructions to just think deeply about a task rather than step-by-step prescriptive guidance. The model's creativity in approaching problems may exceed a human's ability to prescribe the optimal thinking process."

**Key insight**: Be prescriptive about goals, constraints, and verification—but allow flexibility in execution.

### Rule Hierarchy

Not all rules are equal. Classify instructions by enforcement level:

| Level | Name | Enforcement | Examples |
|-------|------|-------------|----------|
| **L1** | Hard Rules | Absolute, no exceptions | Security constraints, secret protection, safety |
| **L2** | Soft Rules | Default behavior, override with reasoning | Code style, commit format, review thresholds |
| **L3** | Guidelines | Recommendations, adapt to context | Implementation approach, tool selection |

**Syntax convention for this plugin:**

```markdown
## Rules (L1 - Hard)
- NEVER commit secrets
- ALWAYS validate user input

## Defaults (L2 - Soft)
- Use conventional commit format (unless project specifies otherwise)
- Confidence threshold >= 80% (adjust based on task criticality)

## Guidelines (L3)
- Consider using subagents for exploration
- Prefer JSON for state files
```

### Goal-Oriented vs Step-by-Step Instructions

| Approach | When to Use | Example |
|----------|-------------|---------|
| **Goal-Oriented** | Creative tasks, problem-solving, design | "Design a solution that handles X while respecting constraints Y and Z" |
| **Step-by-Step** | Safety-critical, compliance, verification | "1. Check X, 2. Validate Y, 3. Confirm Z before proceeding" |

**Pattern for commands and skills:**

```markdown
## Goal
[What success looks like - end state description]

## Constraints (L1/L2)
[Non-negotiable requirements]

## Approach (L3)
[Recommended strategy - Claude may adapt based on situation]

## Verification
[How to confirm success]
```

### Avoiding Over-Specification

Research note:

> "Explicit constraints may lead to over-control problems that suppress emergent behaviors."

**Signs of over-specification:**
- Every step is numbered and prescribed
- No room for judgment or adaptation
- Instructions longer than 500 lines
- Same outcome regardless of context

**Remedies:**
- Replace prescriptive steps with success criteria
- Add "Claude may adapt this approach based on the specific situation"
- Use thinking prompts: "Before implementing, consider alternatives"

### Encouraging Appropriate Initiative

From Claude Code Best Practices:

Claude 4.x follows instructions precisely. To encourage creative problem-solving:

```markdown
## Flexibility Clause

These guidelines are starting points, not rigid rules.
If you identify a better approach that achieves the same goals:
1. Explain your reasoning
2. Confirm the approach still meets all L1 (Hard) constraints
3. Proceed with the improved approach
```

### Thinking Prompts for Complex Decisions

For tasks requiring judgment, add thinking prompts:

```markdown
## Before Implementation

Think deeply about:
- What are the tradeoffs of different approaches?
- What would a senior engineer consider?
- Are there better solutions I haven't explored?
- Does this approach satisfy all constraints?

Use your judgment rather than following steps mechanically.
```

### Progressive Disclosure for Instructions

Keep main instructions concise; put details in reference files:

```
my-skill/
├── SKILL.md           # Core instructions (<300 lines)
│   └── [Goal + Constraints + High-level approach]
├── reference.md       # Detailed patterns (loaded on demand)
│   └── [Step-by-step procedures for specific scenarios]
└── examples.md        # Concrete examples
    └── [Show, don't tell]
```

### Measuring Instruction Effectiveness

When iterating on instructions:

1. **Test with varied contexts** - Same instruction, different situations
2. **Check for brittleness** - Does minor rephrasing break behavior?
3. **Verify creative latitude** - Can Claude find better solutions?
4. **Confirm constraint adherence** - Are L1 rules always followed?

---

## Component Templates

### Agent Template

Create `agents/[name].md`:

```yaml
---
name: agent-name
description: |
  Brief description.

  Use proactively when:
  - Condition 1
  - Condition 2

  Trigger phrases: keyword1, keyword2
model: sonnet
tools: Read, Glob, Grep, Write, Edit, Bash
disallowedTools: Write, Edit
permissionMode: acceptEdits
skills: skill1, skill2
---

# Role: [Title]

[Instructions...]
```

#### Agent Field Reference

| Field | Required | Values |
|-------|----------|--------|
| `name` | Yes | kebab-case identifier |
| `description` | Yes | Summary + "Use proactively when:" + "Trigger phrases:" |
| `model` | No | `sonnet` (default), `opus`, `haiku`, `inherit` |
| `tools` | No | Comma-separated tool names |
| `disallowedTools` | No | Explicitly prohibited tools |
| `permissionMode` | No | `default`, `acceptEdits`, `plan`, `dontAsk` |
| `skills` | No | Comma-separated skill names |
| `hooks` | No | Agent-scoped lifecycle hooks (PreToolUse, PostToolUse, Stop) |

#### permissionMode Options

| Mode | Behavior | Use Case |
|------|----------|----------|
| `default` | Standard prompts | General agents |
| `acceptEdits` | Auto-approve edits | Implementation agents |
| `plan` | Read-only | Analysis agents |
| `dontAsk` | Full automation | Batch operations |

#### Model Selection Strategy

| Model | Use Case | Example Agents |
|-------|----------|----------------|
| **Opus** | Complex reasoning, high-impact | system-architect, product-manager |
| **Sonnet** | Balanced cost/capability | code-explorer, qa-engineer, security-auditor, verification-specialist |
| **Haiku** | Fast, cheap operations | Scoring in /code-review |
| **inherit** | User controls tradeoff | frontend-specialist, backend-specialist |

#### Skill Assignment Guidelines

Skills are fully injected into agent context. Each skill consumes ~2,500-3,000 tokens.

**Include only skills the agent actually uses:**

| Skill Type | Include For | Don't Include For |
|------------|-------------|-------------------|
| `stack-detector` | Agents that need to understand project tech | Agents working with known context |
| `progress-tracking` | Orchestrator commands only | Specialist agents (orchestrator handles) |
| `parallel-execution` | Orchestrator commands only | Individual agents |
| `long-running-tasks` | Orchestrator commands only | Short-lived specialists |
| `insight-recording` | Agents that discover patterns | Non-technical agents |

**Common over-assignment anti-patterns:**

```yaml
# BAD: Specialist with orchestrator skills (wastes ~8,000 tokens)
skills: stack-detector, subagent-contract, progress-tracking, parallel-execution, long-running-tasks

# GOOD: Specialist with essential skills only
skills: stack-detector, subagent-contract, insight-recording, language-enforcement
```

**Skills Order Convention:**

Skills should be listed in a consistent order for maintainability:

```yaml
# Order: Domain-specific → Core framework → Insight → Language (always last)
skills: stack-detector, testing, code-quality, subagent-contract, insight-recording, language-enforcement
```

| Position | Skill Type | Examples |
|----------|------------|----------|
| 1st | Domain-specific | stack-detector, testing, security-fundamentals, api-design |
| 2nd | Core framework | subagent-contract |
| 3rd | Insight capture | insight-recording |
| Last | Language | language-enforcement (always last) |

**When removing skills, check for orphaned references:**

If you remove a skill from the `skills:` list, grep the agent file for references to that skill:

```bash
grep -n "skill-name" agents/agent-name.md
```

Remove any instructions that reference the removed skill.

---

### Skill Template

Create `skills/[category]/[name]/SKILL.md`:

```yaml
---
name: skill-name
description: |
  What it does.

  Use when:
  - Condition 1
  - Condition 2

  Trigger phrases: keyword1, keyword2
allowed-tools: Read, Glob, Grep
model: sonnet
user-invocable: false
---

# Skill Name

[Instructions...]
```

#### Skill Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | kebab-case identifier |
| `description` | Yes | Summary + "Use when:" + "Trigger phrases:" |
| `allowed-tools` | No | Tools available when skill is active |
| `model` | No | Model to use |
| `user-invocable` | No | `true` = user can run `/skill-name` |
| `context` | No | `fork` = run in isolated sub-agent context |
| `agent` | No | Agent type when `context: fork` (e.g., `Explore`, `Plan`, `general-purpose`) |
| `hooks` | No | Skill-scoped lifecycle hooks (PreToolUse, PostToolUse, Stop) |

#### Progressive Disclosure Guidelines

Skills are fully injected into context. Keep them lean:

| Limit | Recommendation |
|-------|----------------|
| SKILL.md lines | ≤ 500 |
| SKILL.md tokens | ≤ 5,000 |
| Supporting files | Use `reference.md`, `examples.md` |

```
my-skill/
├── SKILL.md        # Main instructions (≤500 lines)
├── reference.md    # Detailed docs (loaded on demand)
├── examples.md     # Usage examples (loaded on demand)
└── scripts/
    └── helper.py   # Executed, not loaded into context
```

#### Skill Content Guidelines

| Do | Don't |
|----|-------|
| `From Claude Code Best Practices:` | `[Claude Code Best Practices](https://...)` |
| Plain text attribution | `## Sources` or `## References` sections |

#### Skill Design Principles

Skills should define **processes and frameworks**, not static knowledge that can become outdated.

| Principle | Implementation |
|-----------|----------------|
| **No hardcoded technologies** | Use WebSearch to discover current options |
| **Requirements-first** | Ask what the user needs before suggesting solutions |
| **Domain-agnostic** | Avoid technology-category questions (e.g., "Web or Mobile?") |
| **Dynamic discovery** | RAG (WebSearch + WebFetch) for current information |
| **Evaluation frameworks** | Define how to compare, not what to compare |

**Good skill content:**
- Research methodologies
- Evaluation frameworks and criteria
- Query construction patterns
- Decision-making processes

**Avoid in skills:**
- Specific technology names/versions
- Comparison tables with hardcoded options
- Setup commands for specific tools
- Recommendations that can become outdated

---

### Command Template

Create `commands/[name].md`:

```yaml
---
description: "Command description for /help"
argument-hint: "[arg]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, Task
---

# /command-name

## Purpose
[What this command does]

## Workflow
[Step-by-step phases]

## Output
[Expected deliverables]

## Rules
[Command-specific constraints]
```

#### Command Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `description` | Yes | Shown in `/help` |
| `argument-hint` | No | e.g., `[file]`, `[PR number]` |
| `allowed-tools` | No | Tools during execution |

---

### Command and Agent Content Guidelines

Commands and agents may include concrete examples for clarity, but should be resilient to change.

#### Acceptable (Examples)

```markdown
**Example linter commands:**
npm run lint -- --fix
python -m black .
```

The general pattern (auto-fix linters) is stable; specific tools are examples.

#### Risky (Prescriptive)

```markdown
**Required:** Run `eslint --fix` before committing.
```

This breaks if eslint is replaced by biome or another tool.

#### Guidelines

| Content Type | Guidance |
|--------------|----------|
| **CLI examples** | Use widely-adopted tools (gh, npm, git) as examples |
| **Tool names** | Frame as examples, not requirements |
| **API/SDK calls** | Use conceptual descriptions, not specific method names |
| **Version numbers** | Avoid; use "current version" or "when available" |
| **File paths** | Use patterns (`*lint*`) over specific names (`eslint.config.js`) |

#### Stability Spectrum

| Stable (OK to hardcode) | Moderate (example only) | Unstable (avoid) |
|------------------------|-------------------------|------------------|
| OWASP Top 10, CVSS, CWE | eslint, prettier, black | Specific versions |
| git commands | gh CLI, glab CLI | API method names |
| HTTP methods | npm audit, pip-audit | Library internals |

---

## Hook Specification

### Supported Events

| Event | Purpose | This Plugin Uses |
|-------|---------|------------------|
| `SessionStart` | Inject context | `spec_context.sh` |
| `PreToolUse` | Validate/block tools | `safety_check.py`, `prevent_secret_leak.py` |
| `PostToolUse` | Post-execution actions | `audit_log.sh` |
| `PreCompact` | Save state before compaction | `pre_compact_save.sh` |
| `SubagentStop` | Log completion, capture insights, validate references | `subagent_summary.sh`, `insight_capture.sh`, `verify_references.py` |
| `Stop` | Session summary | `session_summary.sh` |
| `SessionEnd` | Cleanup resources | `session_cleanup.sh` |
| `PermissionRequest` | Custom permission handling | - |
| `Notification` | External notifications | - |
| `UserPromptSubmit` | Input preprocessing | - |

### SessionStart Hook Output Guidelines

SessionStart output is injected at the beginning of every session, consuming main context tokens.

**Keep output minimal (~500 tokens or less):**

| Include | Exclude |
|---------|---------|
| Workspace ID | Detailed rule explanations |
| Current branch | Command lists (already in /help) |
| Role (CODING/INITIALIZER) | Pattern descriptions (in skills) |
| Resumable work summary | Reference tables |
| Pending insights count | Available agent lists |

**Rationale:** Detailed context belongs in skills that are loaded on-demand. SessionStart should provide just enough to orient the session.

**Example minimal output:**

```
Workspace: main_a1b2c3d4
Branch: feature/auth
Role: CODING
Resumable: docs/specs/auth.md (Step 3/5)
Pending insights: 2
```

**Anti-pattern: Verbose SessionStart**

```markdown
# BAD: Full context dump (2,000+ tokens)
## Orchestrator Rules
- Rule 1...
- Rule 2...

## Available Commands
- /spec-plan: ...
- /spec-review: ...

## Agent Delegation Matrix
...

# GOOD: Minimal context with skill references
Role: CODING. See `subagent-contract` skill for delegation rules.
Resumable: docs/specs/auth.md
```

**Emoji guideline:** Avoid emojis in hook output per CLAUDE.md content guidelines.

### Hook Scripting Security

**Shell Variable Injection Risk:**

Never interpolate shell variables directly into Python code:

```bash
# DANGEROUS - shell variable injection vulnerability
python3 -c "
with open('$FILE_PATH', 'r') as f:  # If FILE_PATH contains quotes, breaks/injects
    data = json.load(f)
"

# SAFE - use environment variables
FILE_PATH="$FILE_PATH" python3 -c "
import os
file_path = os.environ.get('FILE_PATH', '')
with open(file_path, 'r') as f:
    data = json.load(f)
"
```

**Fail-Safe Error Handling:**

Hooks that validate commands should fail-safe (deny on error):

```python
try:
    data = json.loads(sys.stdin.read())
    # ... validation logic
except Exception as e:
    # WRONG: exit 1 is non-blocking, command may still execute
    # sys.exit(1)

    # CORRECT: Use JSON decision control to deny
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"Validation error: {e}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)
```

### PreToolUse Hook Implementation

**Exit Code Behavior:**

| Exit Code | Behavior | Output |
|-----------|----------|--------|
| **0** | Success | stdout parsed for JSON |
| **2** | Blocking error | stderr as error message |
| **1, 3, etc.** | Non-blocking error | Tool may still execute! |

**JSON Decision Control (Recommended):**

```python
#!/usr/bin/env python3
import json
import sys

data = json.loads(sys.stdin.read())
tool_input = data.get("tool_input", {})
command = tool_input.get("command", "")

if is_dangerous(command):
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "Blocked: dangerous command"
        }
    }
    print(json.dumps(output))
    sys.exit(0)  # Exit 0 with JSON decision control
else:
    sys.exit(0)
```

**Decision Options:**

| Decision | Behavior |
|----------|----------|
| `"allow"` | Bypass permission, execute immediately |
| `"deny"` | Prevent execution, show reason |
| `"ask"` | Show UI confirmation |

**Tool Input Modification (v2.0.10+):**

Instead of blocking dangerous operations, hooks can now modify tool inputs to make them safe:

```python
#!/usr/bin/env python3
import json
import sys

data = json.loads(sys.stdin.read())
tool_input = data.get("tool_input", {})
command = tool_input.get("command", "")

# Example: Add timeout to potentially long-running commands
if command.startswith("npm install"):
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": {
                "command": f"timeout 300 {command}"  # 5 minute timeout
            }
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# Example: Redirect destructive commands to dry-run
if "rm -rf" in command:
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": {
                "command": f"echo '[DRY RUN] Would execute: {command}'"
            }
        }
    }
    print(json.dumps(output))
    sys.exit(0)

sys.exit(0)  # Allow unmodified
```

**Use Cases for Input Modification:**

| Scenario | Original Input | Modified Input |
|----------|---------------|----------------|
| Add safety wrapper | `rm -rf temp/` | `trash temp/` (safer delete) |
| Add timeout | `npm install` | `timeout 300 npm install` |
| Add verbosity | `git push` | `git push -v` |
| Redirect output | `command` | `command \| tee log.txt` |

**When to Modify vs Block:**

| Situation | Recommendation |
|-----------|----------------|
| Can make safe with wrapper | Modify |
| Fundamentally dangerous | Block (deny) |
| Needs user awareness | Ask |
| Always safe | Allow without modification |

**Input Schema:**

```json
{
  "tool_name": "Bash|Write|Edit|Read|...",
  "tool_input": {
    "command": "...",
    "file_path": "...",
    "content": "...",
    "new_string": "..."
  }
}
```

### PreCompact Hook

Fires before context compaction. Use to preserve state:

```bash
#!/bin/bash
# See hooks/pre_compact_save.sh for workspace-isolated implementation
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('trigger','unknown'))")

# Source workspace utilities for workspace-isolated paths
source "$(dirname "$0")/workspace_utils.sh"
PROGRESS_FILE=$(get_progress_file)

if [ -f "$PROGRESS_FILE" ]; then
    # Use environment variables to safely pass data to Python (see Hook Scripting Security)
    PROGRESS_FILE_PATH="$PROGRESS_FILE" python3 << 'PYEOF'
import os
progress_file = os.environ.get('PROGRESS_FILE_PATH', '')
# ... update progress file
PYEOF
fi

echo "## Pre-Compaction State Saved"
exit 0
```

**Input Schema:**

```json
{
  "trigger": "manual|auto",
  "custom_instructions": "user's /compact message"
}
```

### SessionEnd Hook

Fires when the Claude Code session terminates. Use for cleanup operations:

```bash
#!/bin/bash
# session_cleanup.sh - Clean up resources at session end

# Rotate old logs
find ".claude/workspaces/$WORKSPACE_ID/logs/sessions" -name "*.log" -mtime +30 -exec gzip {} \;

# Remove temporary files
find ".claude/workspaces/$WORKSPACE_ID" -name "*.tmp" -delete

# Archive completed workspaces older than 30 days
# (See hooks/session_cleanup.sh for full implementation)

exit 0
```

**Use Cases:**
- Log rotation and compression
- Temporary file cleanup
- Stale workspace archival
- Resource deallocation

**Note:** SessionEnd runs after Stop hook. Use Stop for session summary, SessionEnd for cleanup.

### Prompt-Based Hooks

Instead of shell commands, hooks can use LLM evaluation for context-aware decisions:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if this command is safe to run in a production environment. Command: $ARGUMENTS. Return JSON: {\"ok\": true/false, \"reason\": \"explanation\"}",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Supported Events for Prompt Hooks:**
- `PreToolUse` - Evaluate tool calls
- `PermissionRequest` - Custom permission logic
- `UserPromptSubmit` - Input validation
- `Stop` / `SubagentStop` - Output verification

**When to Use Prompt vs Command Hooks:**

| Scenario | Recommended |
|----------|-------------|
| Pattern matching (regex, keywords) | Command |
| Context-aware evaluation | Prompt |
| Complex business logic | Command |
| Natural language assessment | Prompt |
| Performance-critical | Command |

### Component-Scoped Hooks

Hooks can be defined in agent/skill frontmatter for component-specific behavior:

**Agent Frontmatter Example:**

```yaml
---
name: security-auditor
description: Security review specialist
model: sonnet
tools: Read, Glob, Grep, Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./hooks/security_audit_bash_validator.py"
---
```

**Skill Frontmatter Example:**

```yaml
---
name: code-quality
description: Code quality analysis
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/lint-check.sh"
          once: true
---
```

**Key Differences from Global Hooks:**

| Aspect | Global Hooks | Component-Scoped |
|--------|--------------|------------------|
| Scope | All sessions | While component is active |
| Location | `hooks/hooks.json` | Agent/Skill frontmatter |
| Events | All | PreToolUse, PostToolUse, Stop |
| `once` flag | Not applicable | Supported for skills |

**Use Cases:**
- Agent-specific validation (security-auditor Bash validation)
- Skill-specific post-processing
- Temporary hooks during specific workflows

**Current Implementation:**
Currently, only `security-auditor` uses component-scoped hooks (PreToolUse for Bash validation). Other agents use global hooks defined in `hooks/hooks.json`. Consider adding component-scoped hooks to other agents when specific validation needs arise.

### Insight Tracking System

The insight tracking system automatically captures valuable discoveries during development and allows users to review and apply them. It uses a folder-based architecture where each insight is stored as a separate file, eliminating the need for file locking and enabling concurrent capture and review.

**Architecture:**

```
SubagentStop
    ↓ (metadata with transcript_path)
insight_capture.sh
    ↓ (code block filtering, state machine parsing)
    ↓ (atomic file creation, deduplication)
.claude/workspaces/{id}/insights/pending/INS-*.json
    ↓ (/review-insights command)
User Decision
    ├─► applied/    (CLAUDE.md or .claude/rules/)
    ├─► rejected/   (rejected by user)
    └─► archive/    (old insights for reference)
```

**Directory Structure:**

```
.claude/workspaces/{id}/insights/
├── pending/       # New insights awaiting review
│   ├── INS-20250121143000-a1b2c3d4.json
│   └── INS-20250121143500-e5f6g7h8.json
├── applied/       # Applied to CLAUDE.md or rules
├── rejected/      # Rejected by user
└── archive/       # Old insights for reference
```

**Skill Reference:**

The `insight-recording` skill (`skills/workflows/insight-recording/SKILL.md`) provides the standardized protocol that agents follow. Agents with this skill in their `skills:` frontmatter will output markers when they discover valuable insights.

**Insight Markers:**

Subagents output these markers when they discover something worth recording:

| Marker | Purpose | Example |
|--------|---------|---------|
| `INSIGHT:` | General learning | `INSIGHT: This codebase uses Repository pattern for all DB access` |
| `LEARNED:` | Experience-based learning | `LEARNED: PreToolUse exit 1 is non-blocking - use JSON decision control` |
| `DECISION:` | Important decision with rationale | `DECISION: Using event-driven architecture due to existing async patterns` |
| `PATTERN:` | Reusable pattern discovered | `PATTERN: Error handling always uses AppError class - see src/errors/` |
| `ANTIPATTERN:` | Approach to avoid | `ANTIPATTERN: Direct database queries in controllers - use services` |

**insight_capture.sh Implementation:**

```bash
#!/bin/bash
# SubagentStop hook - extracts markers from subagent transcript
# Folder-based architecture (no file locking needed)

# Key features:
# - Each insight saved as separate file (no locking)
# - Code block filtering (prevents false matches in ```...```)
# - Inline code filtering (prevents false matches in `...`)
# - State machine parsing (ReDoS-safe, O(n) time)
# - Content length limits (10,000 chars max)
# - Rate limiting (100 insights per capture)
# - Deduplication by content hash (SHA256)
# - Path validation for security (TOCTOU prevention)
# - Atomic writes (temp + fsync + os.replace)
# - Transcript size limits (100MB max)

# Processing flow:
# 1. Validate transcript_path (security check, returns resolved path)
# 2. Stream JSONL, extract assistant messages
# 3. Filter code blocks and inline code
# 4. Parse with state machine (not regex)
# 5. Deduplicate by content hash
# 6. Create individual JSON file per insight (atomic)
```

**Constraints:**

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Min content length | 11 chars | Filters noise |
| Max content length | 10,000 chars | Prevents storage bloat |
| Max transcript size | 100MB | Memory protection |
| Max insights per capture | 100 | Rate limiting |
| Deduplication | By SHA256 hash | Identical insights captured once |

**Individual Insight File Schema:**

```json
{
  "id": "INS-20250121143000-a1b2c3d4",
  "timestamp": "2025-01-21T14:30:00Z",
  "category": "pattern",
  "content": "Error handling uses AppError class with error codes",
  "source": "code-explorer",
  "status": "pending",
  "contentHash": "a1b2c3d4e5f6g7h8",
  "workspaceId": "main_a1b2c3d4"
}
```

**Directory-Based Status:**

| Directory | Meaning |
|-----------|---------|
| `pending/` | Awaiting user review |
| `applied/` | Applied to CLAUDE.md or .claude/rules/ |
| `rejected/` | Rejected by user |
| `archive/` | Old insights for reference |

**Design Principles:**

1. **Explicit markers only**: No automatic inference - subagents must explicitly mark insights
2. **Workspace isolation**: Each workspace has its own insights directory
3. **Folder-based storage**: Each insight is a separate file (no locking needed)
4. **User-driven evaluation**: `/review-insights` processes one insight at a time with AskUserQuestion
5. **Graduated destinations**: workspace → .claude/rules/ → CLAUDE.md
6. **Code block safety**: Markers inside code blocks are ignored
7. **Defense in depth**: Path validation, size limits, timeout protection

**Adding Insight Recording to Agents:**

To enable insight recording, add `insight-recording` to the agent's `skills:` frontmatter and add a brief "Recording Insights" section referencing the skill:

```yaml
skills: stack-detector, subagent-contract, insight-recording
```

```markdown
## Recording Insights

Use `insight-recording` skill markers (PATTERN:, LEARNED:, INSIGHT:) when discovering patterns. Insights are automatically captured for later review.
```

**Agent Insight Recording Coverage:**

| Agent | Has Insight Recording | Rationale |
|-------|----------------------|-----------|
| **Exploration & Architecture** |||
| code-explorer | Yes | Primary exploration role, discovers patterns frequently |
| code-architect | Yes | Design decisions and pattern analysis |
| system-architect | Yes | High-level architectural decisions (ADRs) |
| **Review & Audit** |||
| security-auditor | Yes | Security patterns and vulnerabilities |
| qa-engineer | Yes | Testing patterns and quality insights |
| verification-specialist | Yes | Reference validation, fact-checking other agent outputs |
| **Modernization & Operations** |||
| legacy-modernizer | Yes | Legacy patterns, modernization decisions |
| devops-sre | Yes | Infrastructure patterns, operational insights |
| **Implementation** |||
| frontend-specialist | Yes | Component patterns, a11y solutions, framework conventions |
| backend-specialist | Yes | Service patterns, API conventions, performance optimizations |
| **Non-Technical** |||
| technical-writer | Yes | Documentation patterns, API doc conventions, diagram choices |
| ui-ux-designer | Yes | Design patterns, accessibility solutions, component specifications |
| product-manager | No | Requirements focus, not code-level |

**Why Some Agents Don't Have Insight Recording:**

Non-technical agents (product-manager) operate at a different abstraction level and don't typically produce insights about code patterns. Note: ui-ux-designer and technical-writer are exceptions as they discover reusable design patterns, accessibility solutions, and documentation conventions.

---

## Agent Configuration

### Tool Configuration

| Agent | Tools | Notes |
|-------|-------|-------|
| `code-explorer` | Glob, Grep, Read, WebFetch, WebSearch, TodoWrite | Read supports .ipynb |
| `code-architect` | Glob, Grep, Read, WebFetch, WebSearch, TodoWrite | Design-only |
| `security-auditor` | Read, Glob, Grep, Bash (validated) | Bash via PreToolUse hook |

### Confidence Scoring

Used in `/code-review` and agent outputs:

| Score | Meaning |
|-------|---------|
| **0** | False positive, pre-existing |
| **25** | Might be real but unverified |
| **50** | Real but minor |
| **75** | Verified, significant |
| **100** | Definitely real, frequent |

**Threshold**: Only report issues with confidence >= 80%.

---

## Integration & Environment

### MCP Integration

Model Context Protocol (MCP) servers extend Claude Code's capabilities. This plugin can work alongside MCP servers.

#### MCP Tool Naming Convention

MCP tools follow the pattern: `mcp__<server>__<tool>`

Examples:
- `mcp__memory__create_entities`
- `mcp__filesystem__read_file`
- `mcp__github__search_repositories`

#### Hook Considerations for MCP Tools

When writing PreToolUse hooks, consider MCP tools:

```python
# Check for MCP tools
tool_name = data.get("tool_name", "")

if tool_name.startswith("mcp__"):
    # MCP tool - extract server and tool name
    parts = tool_name.split("__")
    if len(parts) >= 3:
        server_name = parts[1]
        actual_tool = parts[2]
```

#### Security: MCP Tools That Execute Commands

Some MCP tools can execute shell commands (e.g., `mcp__shell__exec`, `mcp__terminal__run`). These should be validated like the Bash tool.

**Matching MCP command tools in hooks.json:**

```json
{
  "matcher": "Bash|mcp__.*__(exec|run|shell|command|bash|terminal)",
  "hooks": [
    {
      "type": "command",
      "command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/safety_check.py"
    }
  ]
}
```

**Extracting commands from MCP tool inputs:**

MCP tools may use different field names for commands. A robust validator should check multiple fields:

```python
def extract_command_from_mcp_input(tool_input: dict) -> str:
    """Extract command from MCP tool input with varying schemas."""
    command_fields = [
        "command", "cmd", "script", "shell_command",
        "bash_command", "exec", "run", "code", "input"
    ]
    for field in command_fields:
        if field in tool_input and isinstance(tool_input[field], str):
            return tool_input[field]
    return ""
```

#### Best Practices for MCP Hook Validation

| Consideration | Recommendation |
|--------------|----------------|
| **Unknown schemas** | Only block dangerous patterns; avoid transformations |
| **Fail-safe default** | When in doubt, deny (MCP tools may have elevated permissions) |
| **Audit logging** | Log all MCP tool invocations for security review |
| **Input extraction** | Try multiple common field names for command extraction |

#### Recommended MCP Servers for Spec-Workflows

| MCP Server | Use Case | Spec-Workflow Integration |
|------------|----------|-----------------|
| `@anthropic/mcp-server-memory` | Persistent memory | Complements progress-tracking |
| `@anthropic/mcp-server-github` | GitHub operations | PRレビュー対応フロー |
| `@anthropic/mcp-server-puppeteer` | Browser automation | E2E testing in qa-engineer |
| `@anthropic/mcp-server-filesystem` | File operations | Alternative to built-in tools |

#### Configuration Example

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-memory"]
    }
  }
}
```

#### Spec-Workflow Toolkit + MCP Best Practices

| Pattern | Recommendation |
|---------|----------------|
| **Progress tracking** | Use JSON files (this plugin) for workflow state, MCP memory for persistent knowledge |
| **Code exploration** | Use built-in `code-explorer` agent; MCP filesystem for specialized access |
| **GitHub operations** | MCP GitHub server for PR/Issue operations; `/code-review` for review workflow |
| **E2E testing** | MCP Puppeteer + `qa-engineer` agent for comprehensive testing |

### Web Environment (Claude Code on Web)

When running Claude Code on the web (`CLAUDE_CODE_REMOTE=true`), some capabilities differ from CLI usage.

#### Environment Detection

Hooks can detect the web environment:

```bash
#!/bin/bash
if [ "$CLAUDE_CODE_REMOTE" = "true" ]; then
    # Web-specific behavior
    echo "Running in Claude Code on Web"
fi
```

#### Known Differences

| Feature | CLI | Web | Notes |
|---------|-----|-----|-------|
| **File system** | Full local access | Sandboxed workspace | Web has restricted paths |
| **Git operations** | Full git access | Limited | Some operations may require workarounds |
| **Shell commands** | User's shell | Containerized | Different env vars, paths |
| **Interactive prompts** | Supported | Limited | Prefer non-interactive flags |
| **Long-running processes** | Supported | May timeout | Use timeouts, checkpointing |
| **MCP servers** | Configurable | Pre-configured | Limited customization |

#### Best Practices for Web Compatibility

| Practice | Recommendation |
|----------|----------------|
| **Use non-interactive flags** | `git commit -m "msg"` not `-i`, `rm -f` not `-i` |
| **Avoid absolute paths** | Use `$CLAUDE_PROJECT_DIR` or relative paths |
| **Handle missing commands** | Check `command -v` before using |
| **Use progress files** | Essential for session resumption in web |
| **Set explicit timeouts** | Web sessions may have shorter limits |

#### Hook Compatibility

Hooks in this plugin are designed to work in both environments:

- `CLAUDE_CODE_REMOTE` check in `spec_context.sh`
- Fallback behaviors when commands unavailable
- Progress files use relative paths within `.claude/`

#### Testing for Web Compatibility

When modifying hooks or scripts:

1. Test with `CLAUDE_CODE_REMOTE=true` environment variable
2. Verify behavior when typical CLI commands are unavailable
3. Ensure progress files are written to `.claude/workspaces/`
4. Test with restricted filesystem access

---

## Operational Rules

### Before Committing

- Semantic commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Never commit API keys or secrets
- Test hook scripts on bash and zsh

### Before Release

- Verify all agent definitions have valid YAML frontmatter
- Test SessionStart hook output
- Run `/plugin validate`
- Ensure documentation counts match actual files

---

## Official References

All URLs are centralized here. Skill and agent files should use plain text attribution only.

### Anthropic Engineering Blog

| Article | Key Concepts |
|---------|--------------|
| [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) | 6 Composable Patterns |
| [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Initializer + Coding pattern |
| [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) | Subagent context management |
| [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Context rot, compaction |
| [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk) | Verification approaches |
| [Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) | Orchestrator-worker patterns |
| [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | Skill patterns |
| [The "think" tool](https://www.anthropic.com/engineering/claude-think-tool) | Structured reasoning |
| [Demystifying evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) | pass@k metrics |

### Claude Code Documentation

| Page | Content |
|------|---------|
| [Subagents](https://code.claude.com/docs/en/sub-agents) | Agent definition format |
| [Skills](https://code.claude.com/docs/en/skills) | Skill format, Progressive Disclosure |
| [Hooks](https://code.claude.com/docs/en/hooks) | Event handlers |
| [Plugins](https://code.claude.com/docs/en/plugins-reference) | plugin.json schema |
| [Memory](https://code.claude.com/docs/en/memory) | .claude/rules/ |

### Official Examples

| Repository | Content |
|------------|---------|
| [anthropics/claude-code/plugins](https://github.com/anthropics/claude-code/tree/main/plugins) | feature-dev, code-review |
| [anthropics/skills](https://github.com/anthropics/skills) | Skill examples |
