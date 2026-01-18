# SDD Toolkit Plugin - Development Guide

Detailed development guidelines for plugin contributors.

## Official References

This plugin is based on Anthropic's official documentation and engineering blog posts:

### Core References
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) - Context management, subagent usage
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) - Initializer+Coding pattern
- [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) - 6 Composable Patterns
- [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk) - Agent orchestration patterns, verification approaches
- [Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) - Orchestrator-worker patterns
- [The "think" tool](https://www.anthropic.com/engineering/claude-think-tool) - Structured reasoning during tool chains
- [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) - Evaluation metrics (pass@k, graders)

### Plugin & Subagent Documentation
- [Create Custom Subagents](https://code.claude.com/docs/en/sub-agents) - Agent definition format, YAML frontmatter
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference) - plugin.json schema, directory structure
- [Hooks Reference](https://code.claude.com/docs/en/hooks) - Event handlers, hook configuration

### Official Examples
- [Official Plugin Repository](https://github.com/anthropics/claude-code/tree/main/plugins) - feature-dev, code-review examples
- [Official Skills Repository](https://github.com/anthropics/skills) - Skill definition patterns

---

## Anthropic's 6 Composable Patterns

This plugin implements all 6 patterns from [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents):

| Pattern | Implementation in This Plugin |
|---------|------------------------------|
| **Prompt Chaining** | 7-phase SDD workflow, TDD Red-Green-Refactor cycle |
| **Routing** | Model selection (Opus/Sonnet/Haiku), agent selection by domain |
| **Parallelization** | Multiple code-explorers, parallel reviewers |
| **Orchestrator-Workers** | Main agent coordinates 12 specialized subagents |
| **Evaluator-Optimizer** | Quality review with iteration loop |
| **Augmented LLM** | Tools, progress files (memory), retrieval |

See `skills/core/composable-patterns/SKILL.md` for detailed pattern documentation.

## Intentional Differences from Official Patterns

| Aspect | Official `feature-dev` | This Plugin | Rationale |
|--------|------------------------|-------------|-----------|
| Architecture options | 3 approaches | **Single definitive** | Reduces decision fatigue |
| Progress format | `.txt` | `.json` | Machine-readable, less prone to corruption |
| Agent specialization | 3 general | **12 specialized** | Domain expertise improves quality |
| Confidence threshold | 80% (code-review) | **80% unified** | Consistency |

---

## Directory Structure

```
sdd-toolkit/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata (v9.0.0)
├── commands/                 # Slash commands
│   ├── sdd.md               # 7-phase workflow
│   ├── code-review.md       # Parallel review (confidence >= 80)
│   ├── spec-review.md       # Spec validation
│   └── quick-impl.md        # Fast implementation
├── agents/                   # Specialized subagents (12 roles)
│   ├── code-explorer.md     # Deep analysis (permissionMode: plan)
│   ├── code-architect.md    # Implementation blueprints
│   ├── system-architect.md  # System design (model: opus)
│   ├── frontend-specialist.md   # UI (model: inherit)
│   ├── backend-specialist.md    # API (model: inherit)
│   ├── qa-engineer.md       # Testing (confidence >= 80)
│   ├── security-auditor.md  # Audit (permissionMode: plan)
│   └── ...
├── skills/
│   ├── core/                # Universal principles
│   │   ├── sdd-philosophy/     # Spec-first development
│   │   ├── interview/          # Requirements gathering
│   │   ├── security-fundamentals/ # Security principles
│   │   ├── subagent-contract/  # Standardized result formats
│   │   ├── composable-patterns/ # Anthropic's 6 patterns
│   │   └── context-engineering/ # Context management principles
│   ├── detection/           # Stack detection
│   │   └── stack-detector/     # Technology detection
│   └── workflows/           # Cross-stack patterns
│       ├── tdd-workflow/       # Test-driven development
│       ├── evaluator-optimizer/ # Iterative improvement
│       ├── error-recovery/     # Checkpoint and recovery
│       ├── progress-tracking/  # JSON-based state
│       ├── parallel-execution/ # Concurrent agents
│       └── long-running-tasks/ # Multi-session work
├── hooks/
│   ├── hooks.json
│   ├── sdd_context.sh       # SessionStart
│   └── ...
└── docs/
    ├── DEVELOPMENT.md       # This file
    └── specs/
        └── SPEC-TEMPLATE.md
```

---

## Design Philosophy

### Why This Plugin Exists

This plugin solves: **Enabling Claude to complete complex, long-running development tasks without losing context or focus.**

### The 7-Phase Workflow

Based on [feature-dev plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/feature-dev):

1. **Discovery** - Understand requirements
2. **Codebase Exploration** - Parallel `code-explorer` agents
3. **Clarifying Questions** - Resolve ambiguities
4. **Architecture Design** - Parallel `code-architect` agents → single recommendation
5. **Implementation** - Delegate to specialist agents, one feature at a time
6. **Quality Review** - Parallel review agents + Haiku scorers
7. **Summary** - Document what was accomplished

### Initializer + Coding Pattern

Based on [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

| Role | When | What |
|------|------|------|
| **Initializer** | First session | Create progress files, break down features |
| **Coding** | Each session | Read progress, implement ONE feature, test, update |

**Key Insight**: "One Feature at a Time" - Avoid trying to do too much at once.

### Context Management via Subagents

From [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices):

> "Subagents use their own isolated context windows, and only send relevant information back to the orchestrator, rather than their full context."

**Why this matters:**

| Approach | Context Cost | Result |
|----------|-------------|--------|
| Direct exploration by orchestrator | 10,000+ tokens | Context exhaustion |
| Subagent exploration | ~500 token summary | Clean main context |

**Benefits:**
- Main orchestrator stays focused on coordination
- Long autonomous work sessions become possible (hours, not minutes)
- Multiple subagents can run in parallel for different analysis focuses
- Only essential findings return to main context

### Progress Files

```
.claude/
├── claude-progress.json    # Resumption context
└── feature-list.json       # Feature status tracking
```

Why JSON? "Models are less likely to inappropriately modify JSON files compared to Markdown files."

---

## Model Selection Strategy

| Model | Use Case |
|-------|----------|
| **Opus** | Complex reasoning, multi-step operations, high-impact decisions |
| **Sonnet** | Default for most tasks, balanced cost/capability |
| **Haiku** | Fast read-only exploration, simple scoring |
| **inherit** | Match parent model (for implementation agents) |

### This Plugin's Assignments

| Agent Type | Model | Rationale |
|------------|-------|-----------|
| `system-architect` | **Opus** | ADRs require deep reasoning |
| Analysis (`code-explorer`, `code-architect`) | Sonnet | Analysis needs reasoning |
| Implementation (`frontend/backend-specialist`) | **inherit** | User controls tradeoff |
| Scoring (Haiku in /code-review) | Haiku | Fast, cheap, sufficient |

---

## Tool Configuration

| Agent | Tools | Notes |
|-------|-------|-------|
| `code-explorer` | Glob, Grep, Read, WebFetch, WebSearch, TodoWrite | Read supports Jupyter notebooks (.ipynb) |
| `code-architect` | Glob, Grep, Read, WebFetch, WebSearch, TodoWrite | Design-only, read-only |
| `security-auditor` | Read, Glob, Grep, Bash (validated) | Bash restricted via PreToolUse hook |

**Note**:
- `Read` tool natively supports Jupyter notebooks (.ipynb files) - no separate NotebookRead needed
- Directory listing is done via `Bash` with `ls` command when needed
- Analysis agents intentionally exclude Write/Edit for safety

---

## Confidence Scoring

| Score | Meaning | When to Use |
|-------|---------|-------------|
| **0** | Not confident | False positive, pre-existing |
| **25** | Somewhat | Might be real but unverified |
| **50** | Moderate | Real but minor/infrequent |
| **75** | High | Verified, significant impact |
| **100** | Certain | Definitely real, frequent |

Only report issues with confidence >= 80%.

---

## Adding New Components

### New Agent

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
model: sonnet  # sonnet, opus, haiku, inherit
tools: Read, Glob, Grep, Write, Edit, Bash
disallowedTools: Write, Edit  # Optional: explicitly prohibit tools
permissionMode: acceptEdits
skills: skill1, skill2
---

# Role: [Title]

[Instructions...]
```

**Agent Field Reference:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier (kebab-case) |
| `description` | Yes | Multi-line: summary, "Use proactively when:", "Trigger phrases:" |
| `model` | No | `sonnet` (default), `opus` (complex reasoning), `haiku` (fast/cheap), `inherit` (match parent) |
| `tools` | No | Available tools for the agent |
| `disallowedTools` | No | Explicitly prohibited tools (for read-only agents like `code-explorer`) |
| `permissionMode` | No | See below |
| `skills` | No | Comma-separated skill names (minimize - see guidelines) |

**permissionMode Options:**

| Mode | Behavior | Use Case |
|------|----------|----------|
| `default` | Standard confirmation prompts | General agents |
| `acceptEdits` | Auto-approve file edits | Implementation agents (`frontend-specialist`, `backend-specialist`) |
| `plan` | Read-only, no modifications | Analysis agents (`code-explorer`, `security-auditor`) |
| `dontAsk` | Full automation, no prompts | Batch operations (use carefully) |

### Key Skills Overview

This plugin includes **20 skills** across 3 categories. Key skills for long-running autonomous work:

| Skill | Purpose | Key Features |
|-------|---------|--------------|
| `composable-patterns` | Documents Anthropic's 6 patterns | Pattern selection guide, composition examples |
| `context-engineering` | Context management principles | Context rot prevention, subagent isolation, progressive disclosure |
| `tdd-workflow` | Test-driven development | Red-Green-Refactor cycle, qa-engineer integration |
| `evaluator-optimizer` | Iterative improvement | Generator-Evaluator loop, quality thresholds |
| `error-recovery` | Resilient workflows | Checkpoints, graceful degradation, recovery paths |
| `subagent-contract` | Standardized outputs | Result format spec, confidence scoring |
| `progress-tracking` | State persistence | JSON schemas, resumption context |
| `long-running-tasks` | Multi-session work | Initializer+Coding pattern, PreCompact integration |
| `stack-detector` | Technology detection | Auto-detect languages, frameworks, tools |

See `CLAUDE.md` for complete skill list (20 skills in core/, detection/, workflows/).

**Skill Reference Guidelines:**

Skills are **fully injected** into subagent context (not loaded on demand). Minimize skill references to preserve context:

| Principle | Rationale |
|-----------|-----------|
| **Essential only** | Each skill consumes context budget |
| **Avoid redundancy** | Don't include skills whose content is already in agent instructions |
| **Prefer inline** | Simple guidance can be in agent body, not a separate skill |

Example: `frontend-specialist` only needs `subagent-contract` (not `code-quality`, `tdd-workflow`, etc. - those are used by qa-engineer when appropriate).

**Skill Content Guidelines:**

Skills should follow official Anthropic patterns. Avoid adding reference sections or URL links:

| Do | Don't |
|----|-------|
| `From Claude Code Best Practices:` | `From [Claude Code Best Practices](https://...):` |
| Plain text source attribution | `## Sources` or `## References` sections |
| Keep URLs in DEVELOPMENT.md/README.md | Scatter URLs across skill files |

**Rationale**: Skills are fully injected into context. URLs consume tokens without adding actionable value. Centralize references in documentation files where developers can find them.

### New Skill

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
user-invocable: true
---

# Skill Name

[Instructions...]
```

**Skill Field Reference:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier (kebab-case) |
| `description` | Yes | Multi-line: summary, "Use when:", "Trigger phrases:" |
| `allowed-tools` | No | Tools available when skill is active |
| `model` | No | Model to use (`sonnet`, `opus`, `haiku`) |
| `user-invocable` | No | `true`: user can run `/skill-name` directly; `false`: internal use only |

**Progressive Disclosure Guidelines** (from [Agent Skills](https://code.claude.com/docs/en/skills)):

| Limit | Recommendation |
|-------|----------------|
| **SKILL.md lines** | ≤ 500 lines |
| **SKILL.md tokens** | ≤ 5,000 tokens |
| **Supporting files** | Use `reference.md`, `examples.md` for detailed content |

```
my-skill/
├── SKILL.md        # Main instructions (≤500 lines)
├── reference.md    # Detailed docs (loaded on demand)
├── examples.md     # Usage examples (loaded on demand)
└── scripts/
    └── helper.py   # Executed, not loaded into context
```

Claude loads supporting files only when needed, preserving context.

### New Command

Create `commands/[name].md`:

```yaml
---
description: "Command description shown in /help"
argument-hint: "[arg]"  # Optional: hint for required argument
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, Task
---

# /[command-name]

## Purpose
[What this command does]

## Workflow
[Step-by-step phases if applicable]

## Output
[Expected deliverables]
```

**Command Field Reference:**

| Field | Required | Description |
|-------|----------|-------------|
| `description` | Yes | Shown in `/help` output |
| `argument-hint` | No | Placeholder for required argument (e.g., `[file]`, `[PR number]`) |
| `allowed-tools` | No | Tools available during command execution |

**Command Body Structure:**

| Section | Purpose |
|---------|---------|
| `## Purpose` | Clear statement of what the command accomplishes |
| `## Workflow` | Numbered phases for multi-step commands (like `/sdd`) |
| `## Output` | Expected deliverables or artifacts |
| `## Rules` | Command-specific constraints |

---

## Hooks

| Event | Purpose |
|-------|---------|
| `SessionStart` | Inject context + detect progress files |
| `SubagentStart` | Initialize subagent |
| `PreToolUse` | Validate/block tool calls (security) |
| `PreCompact` | Save state before context compaction |
| `SubagentStop` | Log completion |
| `Stop` | Session summary |

### PreCompact Hook (Long-Running Session Support)

The `PreCompact` hook fires before context compaction (manual or auto). Use it to preserve critical state:

```bash
#!/bin/bash
# pre_compact_save.sh - Save progress before compaction

INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('trigger','unknown'))")

# Update progress file with compaction timestamp
if [ -f ".claude/claude-progress.json" ]; then
    # Add compaction event to history (see hooks/pre_compact_save.sh for full implementation)
fi

# Output context that will be included in compaction summary
echo "## Pre-Compaction State Saved"
echo "Progress file updated. Remember to read it after compaction."
exit 0
```

**Input Schema:**
```json
{
  "trigger": "manual|auto",
  "custom_instructions": "user's /compact message (if manual)"
}
```

### PreToolUse Hook Implementation (CRITICAL)

Based on [Hooks Reference](https://code.claude.com/docs/en/hooks), PreToolUse hooks must follow this specification:

**Exit Code Behavior:**

| Exit Code | Behavior | Output Used |
|-----------|----------|-------------|
| **0** | Success | stdout parsed for JSON decision control |
| **2** | Blocking error | stderr shown as error message |
| **Other** | Non-blocking error | stderr shown to user |

**JSON Decision Control (Recommended):**

Use exit code 0 + JSON output with `hookSpecificOutput.permissionDecision`:

```python
#!/usr/bin/env python3
import json
import sys

data = json.loads(sys.stdin.read())
tool_input = data.get("tool_input", {})
command = tool_input.get("command", "")

if is_dangerous(command):
    # BLOCK the operation
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
    # ALLOW the operation
    sys.exit(0)
```

**Decision Options:**

| Decision | Behavior |
|----------|----------|
| `"allow"` | Bypasses permission system, tool executes immediately |
| `"deny"` | Prevents tool execution, reason shown to Claude |
| `"ask"` | Shows UI confirmation to user |

**Common Mistake to Avoid:**

```python
# WRONG: Exit code 1 is a non-blocking error (tool will still execute!)
sys.exit(1)

# CORRECT: Use JSON decision control with exit 0
print(json.dumps({"hookSpecificOutput": {"permissionDecision": "deny", ...}}))
sys.exit(0)

# ALTERNATIVE: Exit code 2 + stderr for simple blocking
print("Blocked: reason here", file=sys.stderr)
sys.exit(2)
```

**Input Schema:**

```json
{
  "tool_name": "Bash|Write|Edit|Read|...",
  "tool_input": {
    "command": "...",     // for Bash
    "file_path": "...",   // for Write/Edit/Read
    "content": "...",     // for Write
    "new_string": "..."   // for Edit
  }
}
```

**Tool Input Modification (Advanced):**

PreToolUse hooks can modify tool inputs before execution using `updatedInput`:

```python
#!/usr/bin/env python3
import json
import sys

data = json.loads(sys.stdin.read())
tool_input = data.get("tool_input", {})
command = tool_input.get("command", "")

# Example: Add safety prefix to commands
if needs_modification(command):
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": {
                "command": f"safe_wrapper {command}"  # Modified input
            }
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# Allow original command
sys.exit(0)
```

Use cases:
- Adding safety wrappers to commands
- Normalizing file paths
- Injecting environment variables
- Transforming API parameters

---

## Operational Rules

### Security
- Never commit real API keys or secrets
- Review changes for hardcoded credentials before committing

### Code Quality
- Semantic commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Test changes manually before pushing

### Before Release
- Verify all agent definitions have valid YAML frontmatter
- Test SessionStart hook output is correct
- Ensure command instructions are clear and complete
