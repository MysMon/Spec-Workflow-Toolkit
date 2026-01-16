# SDD Toolkit Plugin v8.0 - Developer Guide

> **Important**: This file is for **plugin developers** working on this repository.
> When users install the plugin in their project, context is delivered via the `SessionStart` hook (`hooks/sdd_context.sh`), not this file.

## What's New in v8.0

Based on thorough analysis of [Anthropic's official best practices](https://www.anthropic.com/engineering/claude-code-best-practices), [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), and [official plugins](https://github.com/anthropics/claude-plugins-official):

### Key Improvements

1. **code-architect Agent (NEW)** - Definitive implementation blueprints based on existing codebase patterns (aligned with official feature-dev pattern)
2. **5-Agent Parallel Code Review** - Now uses 5 parallel Sonnet agents + N parallel Haiku scorers (aligned with official code-review plugin)
3. **Enhanced code-explorer** - Added WebFetch, WebSearch, TodoWrite tools; `permissionMode: plan` for true read-only operation
4. **Detailed Confidence Rubric** - 0/25/50/75/100 scale with explicit criteria for each level
5. **Agent Role Clarification** - Clear distinction between `system-architect` (system-level) and `code-architect` (feature-level)

## Plugin Architecture

Based on [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices), [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), and [Official Plugin Guidelines](https://code.claude.com/docs/en/plugins).

### How Users Receive Context

When users install this plugin:

1. **SessionStart hook** (`hooks/sdd_context.sh`) injects SDD principles, detects progress files, and supports resumption
2. **Agents** become available for delegation via natural language
3. **Skills** auto-activate based on task descriptions
4. **Commands** are accessible via `/sdd`, `/code-review`, etc.

The user's own `CLAUDE.md` file (in their project) defines their project-specific conventions.

---

## Directory Structure

```
sdd-toolkit/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata (v7.0.0)
├── commands/                # Slash commands
│   ├── sdd.md              # /sdd - 7-phase workflow with parallel agents
│   ├── code-review.md      # /code-review - Parallel review (confidence >= 80)
│   ├── spec-review.md      # /spec-review - Spec validation
│   └── quick-impl.md       # /quick-impl - Fast implementation
├── agents/                  # Specialized subagents (12 roles)
│   ├── code-explorer.md    # Deep codebase analysis (read-only, permissionMode: plan)
│   ├── code-architect.md   # NEW: Feature implementation blueprints (definitive recommendations)
│   ├── product-manager.md  # Requirements (disallows Bash/Edit)
│   ├── system-architect.md # System-level design (ADRs, schemas, contracts)
│   ├── frontend-specialist.md
│   ├── backend-specialist.md
│   ├── qa-engineer.md      # Testing (confidence >= 80)
│   ├── security-auditor.md # Audit (permissionMode: plan, confidence >= 80)
│   ├── devops-sre.md
│   ├── ui-ux-designer.md
│   ├── technical-writer.md
│   └── legacy-modernizer.md
├── skills/
│   ├── core/               # Universal principles
│   │   ├── sdd-philosophy/
│   │   ├── interview/
│   │   └── security-fundamentals/
│   ├── detection/
│   │   └── stack-detector/
│   └── workflows/          # Cross-stack patterns
│       ├── code-quality/
│       ├── testing/
│       ├── git-mastery/
│       ├── api-design/
│       ├── migration/
│       ├── observability/
│       ├── long-running-tasks/
│       ├── parallel-execution/
│       └── progress-tracking/  # NEW: JSON-based state persistence
├── hooks/
│   ├── hooks.json
│   ├── sdd_context.sh      # SessionStart - Context + progress detection
│   ├── subagent_init.sh    # SubagentStart
│   ├── safety_check.py     # PreToolUse (Bash)
│   ├── prevent_secret_leak.py  # PreToolUse (Write/Edit)
│   ├── post_edit_quality.sh    # PostToolUse
│   ├── subagent_summary.sh # SubagentStop
│   └── session_summary.sh  # Stop
└── docs/
    └── specs/
        └── SPEC-TEMPLATE.md
```

---

## Design Philosophy: Why This Plugin Exists

### Plugin Purpose

This plugin exists to solve a specific problem: **enabling Claude to complete complex, long-running development tasks without losing context or focus**.

Key goals:
1. **Preserve main context** - Delegate exploration and analysis to subagents
2. **Ensure completeness** - Never implement without understanding the full picture
3. **Support resumption** - Allow sessions to be interrupted and continued
4. **Maintain quality** - Confidence-based filtering reduces noise

### Intentional Differences from Official Patterns

This plugin is **inspired by** but **not a copy of** official Anthropic plugins. Key intentional differences:

| Aspect | Official `feature-dev` | This Plugin (SDD) | Rationale |
|--------|----------------------|-------------------|-----------|
| **Architecture options** | Presents 3 approaches | Presents **single definitive recommendation** | Reduces decision fatigue; code-architect already considered alternatives internally |
| **Progress format** | `claude-progress.txt` (text) | `claude-progress.json` (JSON) | JSON is machine-readable and less prone to accidental corruption |
| **Agent specialization** | General-purpose explorers | **12 specialized agents** | Domain expertise improves quality (security auditor vs. generic reviewer) |
| **Confidence threshold** | 80% (code-review only) | **80% unified** across all reviews | Consistency reduces confusion |
| **Workflow phases** | 7 phases | 7 phases + **explicit progress tracking** | Better resumption support |

### Why "Definitive Recommendations" Instead of "Multiple Options"

The official `feature-dev` plugin launches 3 code-architect agents exploring:
- Minimal changes approach
- Clean architecture approach
- Pragmatic balance approach

This plugin's `code-architect` agent instead provides **a single, definitive recommendation**.

**Rationale:**
1. The code-architect agent has **already analyzed trade-offs internally**
2. Users typically want guidance, not more decisions to make
3. The agent cites evidence from codebase patterns with `file:line` references
4. Users can always ask for alternatives if needed

This is a deliberate design choice, not a limitation.

---

## Key Design Decisions

### 1. Context Protection via Subagents

The main orchestrator delegates to specialized agents to preserve tokens:
- Exploration happens in isolated context windows
- Only results/summaries return to main context
- Long sessions remain effective

### 2. 7-Phase Workflow (Official Pattern)

Based on [feature-dev plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/feature-dev):
1. Discovery
2. **Codebase Exploration** (parallel code-explorer agents)
3. Clarifying Questions
4. **Architecture Design** (parallel code-architect agents with definitive recommendations)
5. Implementation
6. **Quality Review** (parallel review agents + Haiku scorers)
7. Summary

### 3. code-explorer Agent

Deep codebase analysis specialist (aligned with official pattern):
- 4-phase analysis: Discovery → Flow Tracing → Architecture → Implementation Details
- **MUST** provide file:line references for ALL findings
- Tools: Glob, Grep, Read, WebFetch, WebSearch, TodoWrite
- `permissionMode: plan` for true read-only operation
- Returns key files list (5-10) for orchestrator to read
- Invoked with thoroughness levels: quick, medium, very thorough

### 4. code-architect Agent (NEW)

Feature implementation blueprint specialist (aligned with official pattern):
- **Provides definitive recommendations** (not multiple options)
- 3-phase design: Analysis → Design → Delivery
- Based recommendations on existing codebase patterns with file:line evidence
- Returns implementation map with specific file paths and build sequence
- `permissionMode: plan` for design-only operation (no implementation)

### 5. Long-Running Task Support (Initializer + Coding Pattern)

Based on [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

**The Problem:** Complex tasks cannot be completed in a single context window. Each new session starts with no memory of previous work.

**The Solution:** Two-role pattern:

| Role | When | What |
|------|------|------|
| **Initializer** | First session | Create progress files, break down features, initialize state |
| **Coding** | Each session | Read progress, implement ONE feature, test, update progress |

**Key Files:**
```
.claude/
├── claude-progress.json    # Progress log with resumption context
└── feature-list.json       # Feature/task status tracking
```

**Critical Insight:** "One Feature at a Time" - Avoid trying to do too much at once. Focus on completing and testing ONE feature before moving to the next.

**Why JSON over Markdown:** "Models are less likely to inappropriately modify JSON files compared to Markdown files."

**SessionStart Hook:** Automatically detects progress files and extracts resumption context.

### 6. Confidence Scoring (80% Threshold with Detailed Rubric)

Based on [official code-reviewer pattern](https://github.com/anthropics/claude-plugins-official):

| Score | Meaning | When to Use |
|-------|---------|-------------|
| **0** | Not confident at all | False positive, pre-existing issue |
| **25** | Somewhat confident | Might be real but unverified |
| **50** | Moderately confident | Real but minor/infrequent |
| **75** | Highly confident | Verified, significant impact |
| **100** | Absolutely certain | Definitely real, frequently occurring |

- Only report issues with confidence >= 80%
- Use Haiku agents to score each issue in parallel
- For CLAUDE.md issues, verify guideline explicitly mentions the issue

### 7. Resumable Sessions

SessionStart hook automatically:
- Detects `.claude/claude-progress.json` or `claude-progress.json`
- Extracts resumption context (position, next action, blockers)
- Reports feature progress from `feature-list.json`
- Provides clear resume instructions

### 8. Parallel Agent Execution

For independent work, launch multiple agents simultaneously:
- Phase 2: 2-3 code-explorer agents (different focuses)
- Phase 4: 2-3 code-architect agents (different priorities)
- Phase 6: 3 review agents (qa, security, verification) + N Haiku scorers
- /code-review: 5 parallel Sonnet agents + N parallel Haiku scorers

### 9. Read-Only Audit Mode

Agents using `permissionMode: plan`:
- `code-explorer` - Ensures thorough exploration without side effects
- `code-architect` - Design-only, no implementation
- `security-auditor` - Maintains audit integrity

---

## Development Guidelines

### Adding New Agents

Create `agents/[name].md` with YAML frontmatter:

```yaml
---
name: agent-name
description: |
  [Brief description]
  Use proactively when:
  - [Trigger condition 1]
  - [Trigger condition 2]
  Trigger phrases: keyword1, keyword2, keyword3
model: sonnet  # sonnet, opus, haiku, or inherit
tools: Read, Glob, Grep, Write, Edit, Bash
disallowedTools: [optional list]
permissionMode: default  # default, acceptEdits, plan, dontAsk, bypassPermissions
skills: skill1, skill2
---

# Role: [Title]

[Agent instructions...]
```

**Permission Modes**:
| Mode | Use Case |
|------|----------|
| `default` | Standard permission prompts |
| `acceptEdits` | Auto-accept file modifications |
| `plan` | Read-only mode (for audits) |
| `dontAsk` | Deny permission prompts silently |

### Adding New Skills

Create `skills/[category]/[name]/SKILL.md`:

```yaml
---
name: skill-name
description: |
  [What it does]
  Trigger phrases: keyword1, keyword2
allowed-tools: Read, Glob, Grep
model: sonnet
user-invocable: true
context: fork  # Optional: isolated execution
agent: general-purpose  # Optional: agent type
---

# Skill Name

[Instructions...]
```

### Adding New Commands

Create `commands/[name].md`:

```yaml
---
description: "[Command description]"
argument-hint: "[optional hint]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, Task
---

# /[command-name]

[Instructions...]
```

### Modifying Hooks

Edit `hooks/hooks.json`:

| Event | Purpose |
|-------|---------|
| `SessionStart` | Inject context + detect progress files |
| `SubagentStart` | Initialize subagent |
| `PreToolUse` | Validate/block tool calls |
| `PostToolUse` | Quality checks after tool use |
| `SubagentStop` | Log subagent completion |
| `Stop` | Session summary |

---

## Testing Changes

1. Run Claude Code in this directory
2. Test commands: `/sdd`, `/code-review`, etc.
3. Test agents: "Launch the code-explorer agent to trace..."
4. Test skills: Reference skill names in requests
5. Verify SessionStart hook output
6. Test progress file detection with sample `.claude/claude-progress.json`

---

## Operational Rules for This Repository

### Security (OPSEC)

- Never commit real API keys or secrets
- Hooks auto-detect and block secret leaks
- Run `security-auditor` before major changes

### Code Quality

- Write tests before implementation
- Use semantic commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Apply `code-quality` skill after edits
- Confidence threshold: 80% for all reviews

### Delegation in This Repo

When working on this plugin:
- Use `code-explorer` for understanding existing code
- Use `system-architect` for design decisions
- Use `qa-engineer` for testing new agents/skills
- Use `security-auditor` before releases

---

## Official Resources

- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)
- [Skills Documentation](https://code.claude.com/docs/en/skills)
- [Official Plugin Marketplace](https://github.com/anthropics/claude-plugins-official)
