# SDD Toolkit - Development Guide

Detailed specifications for plugin contributors. For user documentation, see `README.md`.

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
| Agent specialization | 3 general | 12 specialized | Domain expertise improves quality |

### Context Management

From Claude Code Best Practices:

> "Subagents use their own isolated context windows, and only send relevant information back to the orchestrator."

| Approach | Context Cost | Result |
|----------|-------------|--------|
| Direct exploration | 10,000+ tokens | Context exhaustion |
| Subagent exploration | ~500 token summary | Clean main context |

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
| **Sonnet** | Balanced cost/capability | code-explorer, qa-engineer |
| **Haiku** | Fast, cheap operations | Scoring in /code-review |
| **inherit** | User controls tradeoff | frontend-specialist, backend-specialist |

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

## Hook Specification

### Supported Events

| Event | Purpose | This Plugin Uses |
|-------|---------|------------------|
| `SessionStart` | Inject context | `sdd_context.sh` |
| `PreToolUse` | Validate/block tools | `safety_check.py`, `prevent_secret_leak.py` |
| `PostToolUse` | Post-execution actions | - |
| `PreCompact` | Save state before compaction | `pre_compact_save.sh` |
| `SubagentStop` | Log completion | `subagent_summary.sh` |
| `Stop` | Session summary | `session_summary.sh` |
| `SessionEnd` | Cleanup | - |
| `PermissionRequest` | Custom permission handling | - |
| `Notification` | External notifications | - |
| `UserPromptSubmit` | Input preprocessing | - |

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

**Tool Input Modification:**

```python
output = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "updatedInput": {
            "command": f"safe_wrapper {command}"
        }
    }
}
```

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
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('trigger','unknown'))")

if [ -f ".claude/claude-progress.json" ]; then
    # Update progress file with compaction timestamp
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

---

## Confidence Scoring

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

## Tool Configuration

| Agent | Tools | Notes |
|-------|-------|-------|
| `code-explorer` | Glob, Grep, Read, WebFetch, WebSearch, TodoWrite | Read supports .ipynb |
| `code-architect` | Glob, Grep, Read, WebFetch, WebSearch, TodoWrite | Design-only |
| `security-auditor` | Read, Glob, Grep, Bash (validated) | Bash via PreToolUse hook |

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
