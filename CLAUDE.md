# SDD Toolkit Plugin v7.0 - Developer Guide

> **Important**: This file is for **plugin developers** working on this repository.
> When users install the plugin in their project, context is delivered via the `SessionStart` hook (`hooks/sdd_context.sh`), not this file.

## What's New in v7.0

Based on thorough analysis of [Anthropic's official best practices](https://www.anthropic.com/engineering/claude-code-best-practices) and [official plugins](https://github.com/anthropics/claude-plugins-official):

1. **7-Phase Workflow** - Aligned with official feature-dev plugin pattern
2. **code-explorer Agent** - Deep codebase analysis with file:line references
3. **JSON Progress Tracking** - `claude-progress.json` and `feature-list.json` patterns
4. **Resumable Sessions** - SessionStart hook auto-detects and reports progress files
5. **Confidence Threshold 80%** - Aligned with official code-reviewer pattern

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
├── agents/                  # Specialized subagents (11 roles)
│   ├── code-explorer.md    # NEW: Deep codebase analysis (read-only)
│   ├── product-manager.md  # Requirements (disallows Bash/Edit)
│   ├── architect.md        # System design
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
4. **Architecture Design** (parallel architect agents with different approaches)
5. Implementation
6. **Quality Review** (parallel review agents)
7. Summary

### 3. code-explorer Agent

Deep codebase analysis specialist:
- Traces execution paths with file:line references
- Maps dependencies and call chains
- READ-ONLY to ensure thorough exploration without side effects
- Invoked with thoroughness levels: quick, medium, very thorough

### 4. JSON-Based Progress Tracking

Based on [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

```
.claude/
├── claude-progress.json    # Progress log with resumption context
└── feature-list.json       # Feature/task status tracking
```

Why JSON over Markdown: "Models are less likely to inappropriately modify JSON files compared to Markdown files."

### 5. Confidence Scoring (80% Threshold)

Based on [official code-reviewer pattern](https://github.com/anthropics/claude-plugins-official):
- Only report issues with confidence >= 80%
- Reduces false positives
- Prioritizes actionable findings

### 6. Resumable Sessions

SessionStart hook automatically:
- Detects `.claude/claude-progress.json` or `claude-progress.json`
- Extracts resumption context (position, next action, blockers)
- Reports feature progress from `feature-list.json`
- Provides clear resume instructions

### 7. Parallel Agent Execution

For independent work, launch multiple agents simultaneously:
- Phase 2: 2-3 code-explorer agents
- Phase 4: 2-3 architect agents with different focuses
- Phase 6: 3 review agents (qa, security, verification)

### 8. Read-Only Audit Mode

`security-auditor` uses `permissionMode: plan` to:
- Maintain audit integrity
- Prevent accidental modifications
- Enforce separation of concerns

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
- Use `architect` for design decisions
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
