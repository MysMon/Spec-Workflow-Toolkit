# SDD Toolkit Plugin - Developer Guide

> **Important**: This file is for **plugin developers** working on this repository.
> When users install the plugin in their project, context is delivered via the `SessionStart` hook (`hooks/sdd_context.sh`), not this file.

## Plugin Architecture

Based on [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) and [Official Plugin Guidelines](https://code.claude.com/docs/en/plugins).

### How Users Receive Context

When users install this plugin:

1. **SessionStart hook** (`hooks/sdd_context.sh`) injects SDD principles and operational guidance
2. **Agents** become available for delegation via natural language
3. **Skills** auto-activate based on task descriptions
4. **Commands** are accessible via `/sdd`, `/code-review`, etc.

The user's own `CLAUDE.md` file (in their project) defines their project-specific conventions.

---

## Directory Structure

```
sdd-toolkit/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata (v6.0.0)
├── commands/                # Slash commands
│   ├── sdd.md              # /sdd - Full 6-phase workflow
│   ├── code-review.md      # /code-review - Parallel review
│   ├── spec-review.md      # /spec-review - Spec validation
│   └── quick-impl.md       # /quick-impl - Fast implementation
├── agents/                  # Specialized subagents (10 roles)
│   ├── product-manager.md  # Requirements (disallows Bash/Edit)
│   ├── architect.md        # System design
│   ├── frontend-specialist.md
│   ├── backend-specialist.md
│   ├── qa-engineer.md      # Testing (confidence scoring)
│   ├── security-auditor.md # Audit (permissionMode: plan)
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
│       ├── long-running-tasks/   # State persistence patterns
│       └── parallel-execution/   # Multi-agent patterns
├── hooks/
│   ├── hooks.json
│   ├── sdd_context.sh      # SessionStart - User context injection
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

### 2. Proactive Triggers in Descriptions

Agents have clear trigger phrases so Claude automatically suggests delegation:

```yaml
description: |
  Use proactively when:
  - User request is vague or incomplete
  - Designing new features or systems
  Trigger phrases: architecture, design, database schema
```

### 3. Confidence Scoring for Reviews

Review agents (`qa-engineer`, `security-auditor`) use 0-100 confidence scores:
- Reduces false positives (threshold: 70)
- Prioritizes actionable findings
- Aligns with official code-review plugin patterns

### 4. Read-Only Audit Mode

`security-auditor` uses `permissionMode: plan` to:
- Maintain audit integrity
- Prevent accidental modifications
- Enforce separation of concerns

### 5. File-Based State for Long Tasks

`long-running-tasks` skill provides patterns for:
- Writing state to `docs/plans/[task].md`
- Resuming work across sessions
- Complementing TodoWrite with persistent storage

### 6. Parallel Agent Execution

`parallel-execution` skill documents how to:
- Launch multiple independent agents simultaneously
- Aggregate results with confidence weighting
- Maximize efficiency for code reviews

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
| `SessionStart` | Inject user context (once per session) |
| `SubagentStart` | Initialize subagent |
| `PreToolUse` | Validate/block tool calls |
| `PostToolUse` | Quality checks after tool use |
| `SubagentStop` | Log subagent completion |
| `Stop` | Session summary |

---

## Testing Changes

1. Run Claude Code in this directory
2. Test commands: `/sdd`, `/code-review`, etc.
3. Test agents: "Launch the architect agent to..."
4. Test skills: Reference skill names in requests
5. Verify SessionStart hook output

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

### Delegation in This Repo

When working on this plugin:
- Use `architect` for design decisions
- Use `qa-engineer` for testing new agents/skills
- Use `security-auditor` before releases

---

## Official Resources

- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)
- [Skills Documentation](https://code.claude.com/docs/en/skills)
- [Official Plugin Marketplace](https://github.com/anthropics/claude-plugins-official)
