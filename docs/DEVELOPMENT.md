# SDD Toolkit Plugin - Development Guide

Detailed development guidelines for plugin contributors.

## Official References

This plugin is based on Anthropic's official documentation and engineering blog posts:

### Core References
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) - Context management, subagent usage
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) - Initializer+Coding pattern
- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) - 6 Composable Patterns
- [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk) - Agent orchestration patterns
- [Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) - Orchestrator-worker patterns

### Plugin & Subagent Documentation
- [Create Custom Subagents](https://code.claude.com/docs/en/sub-agents) - Agent definition format, YAML frontmatter
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference) - plugin.json schema, directory structure
- [Hooks Reference](https://code.claude.com/docs/en/hooks) - Event handlers, hook configuration

### Official Examples
- [Official Plugin Repository](https://github.com/anthropics/claude-code/tree/main/plugins) - feature-dev, code-review examples
- [Official Skills Repository](https://github.com/anthropics/skills) - Skill definition patterns

---

## Anthropic's 6 Composable Patterns

This plugin implements all 6 patterns from [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents):

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
│   └── plugin.json          # Plugin metadata (v8.2.0)
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
│   │   └── composable-patterns/ # Anthropic's 6 patterns
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
| `code-explorer` | Glob, Grep, LS, Read, NotebookRead, WebFetch, WebSearch, TodoWrite | `NotebookRead` for Jupyter |
| `code-architect` | Glob, Grep, LS, Read, NotebookRead, WebFetch, WebSearch, TodoWrite | Design-only |
| `security-auditor` | Read, Glob, Grep, Bash (validated) | Bash restricted via hook |

**Note**: `KillShell` and `BashOutput` excluded - not needed for analysis-focused agents.

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
  Trigger phrases: keyword1, keyword2
model: sonnet  # sonnet, opus, haiku, inherit
tools: Read, Glob, Grep, Write, Edit, Bash
permissionMode: default  # default, acceptEdits, plan, dontAsk
skills: skill1, skill2
---

# Role: [Title]

[Instructions...]
```

### Key Skills Overview

| Skill | Purpose | Key Features |
|-------|---------|--------------|
| `composable-patterns` | Documents Anthropic's 6 patterns | Pattern selection guide, composition examples |
| `tdd-workflow` | Test-driven development | Red-Green-Refactor cycle, qa-engineer integration |
| `evaluator-optimizer` | Iterative improvement | Generator-Evaluator loop, quality thresholds |
| `error-recovery` | Resilient workflows | Checkpoints, graceful degradation, recovery paths |
| `subagent-contract` | Standardized outputs | Result format spec, confidence scoring |
| `progress-tracking` | State persistence | JSON schemas, resumption context |

### New Skill

Create `skills/[category]/[name]/SKILL.md`:

```yaml
---
name: skill-name
description: |
  What it does.
  Trigger phrases: keyword1, keyword2
allowed-tools: Read, Glob, Grep
model: sonnet
user-invocable: true
---

# Skill Name

[Instructions...]
```

### New Command

Create `commands/[name].md`:

```yaml
---
description: "Command description"
argument-hint: "[optional hint]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, Task
---

# /[command-name]

[Instructions...]
```

---

## Hooks

| Event | Purpose |
|-------|---------|
| `SessionStart` | Inject context + detect progress files |
| `SubagentStart` | Initialize subagent |
| `PreToolUse` | Validate/block tool calls |
| `PostToolUse` | Quality checks |
| `SubagentStop` | Log completion |
| `Stop` | Session summary |

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
