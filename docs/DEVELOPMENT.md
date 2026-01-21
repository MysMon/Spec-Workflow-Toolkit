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
| Progress isolation | Project-level | Workspace-level | Supports git worktrees, concurrent projects |
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
| **Sonnet** | Balanced cost/capability | code-explorer, qa-engineer, security-auditor |
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
| `PostToolUse` | Post-execution actions | `audit_log.sh` |
| `PreCompact` | Save state before compaction | `pre_compact_save.sh` |
| `SubagentStop` | Log completion, capture insights | `subagent_summary.sh`, `insight_capture.sh` |
| `Stop` | Session summary | `session_summary.sh` |
| `SessionEnd` | Cleanup resources | `session_cleanup.sh` |
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

### Insight Tracking System

The insight tracking system automatically captures valuable discoveries during development and allows users to review and apply them.

**Architecture:**

```
SubagentStop
    ↓ (marker detection)
insight_capture.sh
    ↓ (JSON append)
.claude/workspaces/{id}/insights/pending.json
    ↓ (/review-insights command)
User Decision
    ↓ (apply)
CLAUDE.md / .claude/rules/ / workspace
```

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
# Extracts markers from subagent output and appends to pending.json
# See hooks/insight_capture.sh for full implementation

INPUT=$(cat)
WORKSPACE_ID=$(get_workspace_id)
PENDING_FILE=".claude/workspaces/$WORKSPACE_ID/insights/pending.json"

# Python script extracts markers and appends to JSON
# Only markers are captured - no automatic inference
```

**pending.json Schema:**

```json
{
  "workspaceId": "main_a1b2c3d4",
  "created": "2025-01-21T10:00:00Z",
  "lastUpdated": "2025-01-21T14:30:00Z",
  "insights": [
    {
      "id": "INS-20250121143000123",
      "timestamp": "2025-01-21T14:30:00Z",
      "category": "pattern",
      "content": "Error handling uses AppError class with error codes",
      "source": "code-explorer",
      "status": "pending"
    }
  ]
}
```

**Status Values:**

| Status | Meaning |
|--------|---------|
| `pending` | Awaiting user review |
| `applied` | Applied to CLAUDE.md or .claude/rules/ |
| `workspace-approved` | Kept in workspace only |
| `rejected` | Rejected by user |

**Design Principles:**

1. **Explicit markers only**: No automatic inference - subagents must explicitly mark insights
2. **Workspace isolation**: Each workspace has its own pending.json
3. **User-driven evaluation**: `/review-insights` processes one insight at a time with AskUserQuestion
4. **Graduated destinations**: workspace → .claude/rules/ → CLAUDE.md

**Adding Insight Markers to Agents:**

When creating or updating agents, add the "Recording Insights" section:

```markdown
## Recording Insights (Optional)

When you discover something valuable for future reference, output it with a marker:

| Marker | Use When |
|--------|----------|
| `PATTERN:` | Discovered a reusable pattern |
| `ANTIPATTERN:` | Found an approach to avoid |
| `DECISION:` | Made an important decision with rationale |
| `INSIGHT:` | General learning about the codebase |

Only use markers for insights genuinely valuable for future work.
```

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
  Stop:
    - hooks:
        - type: command
          command: "./hooks/audit_report_generator.sh"
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

## MCP Integration

Model Context Protocol (MCP) servers extend Claude Code's capabilities. This plugin can work alongside MCP servers.

### MCP Tool Naming Convention

MCP tools follow the pattern: `mcp__<server>__<tool>`

Examples:
- `mcp__memory__create_entities`
- `mcp__filesystem__read_file`
- `mcp__github__search_repositories`

### Hook Considerations for MCP Tools

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

### Recommended MCP Servers for SDD Workflows

| MCP Server | Use Case | SDD Integration |
|------------|----------|-----------------|
| `@anthropic/mcp-server-memory` | Persistent memory | Complements progress-tracking |
| `@anthropic/mcp-server-github` | GitHub operations | PRレビュー対応フロー |
| `@anthropic/mcp-server-puppeteer` | Browser automation | E2E testing in qa-engineer |
| `@anthropic/mcp-server-filesystem` | File operations | Alternative to built-in tools |

### Configuration Example

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

### SDD Toolkit + MCP Best Practices

| Pattern | Recommendation |
|---------|----------------|
| **Progress tracking** | Use JSON files (this plugin) for workflow state, MCP memory for persistent knowledge |
| **Code exploration** | Use built-in `code-explorer` agent; MCP filesystem for specialized access |
| **GitHub operations** | MCP GitHub server for PR/Issue operations; `/code-review` for review workflow |
| **E2E testing** | MCP Puppeteer + `qa-engineer` agent for comprehensive testing |

---

## Web Environment (Claude Code on Web)

When running Claude Code on the web (`CLAUDE_CODE_REMOTE=true`), some capabilities differ from CLI usage.

### Environment Detection

Hooks can detect the web environment:

```bash
#!/bin/bash
if [ "$CLAUDE_CODE_REMOTE" = "true" ]; then
    # Web-specific behavior
    echo "Running in Claude Code on Web"
fi
```

### Known Differences

| Feature | CLI | Web | Notes |
|---------|-----|-----|-------|
| **File system** | Full local access | Sandboxed workspace | Web has restricted paths |
| **Git operations** | Full git access | Limited | Some operations may require workarounds |
| **Shell commands** | User's shell | Containerized | Different env vars, paths |
| **Interactive prompts** | Supported | Limited | Prefer non-interactive flags |
| **Long-running processes** | Supported | May timeout | Use timeouts, checkpointing |
| **MCP servers** | Configurable | Pre-configured | Limited customization |

### Best Practices for Web Compatibility

| Practice | Recommendation |
|----------|----------------|
| **Use non-interactive flags** | `git commit -m "msg"` not `-i`, `rm -f` not `-i` |
| **Avoid absolute paths** | Use `$CLAUDE_PROJECT_DIR` or relative paths |
| **Handle missing commands** | Check `command -v` before using |
| **Use progress files** | Essential for session resumption in web |
| **Set explicit timeouts** | Web sessions may have shorter limits |

### Hook Compatibility

Hooks in this plugin are designed to work in both environments:

- `CLAUDE_CODE_REMOTE` check in `sdd_context.sh`
- Fallback behaviors when commands unavailable
- Progress files use relative paths within `.claude/`

### Testing for Web Compatibility

When modifying hooks or scripts:

1. Test with `CLAUDE_CODE_REMOTE=true` environment variable
2. Verify behavior when typical CLI commands are unavailable
3. Ensure progress files are written to `.claude/workspaces/`
4. Test with restricted filesystem access

---

## Instruction Design Guidelines

Based on Anthropic's research and community best practices for balancing accuracy with creative problem-solving.

### The Bounded Autonomy Principle

From [Claude 4.5 Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices):

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

From [System Dynamics Review research](https://onlinelibrary.wiley.com/doi/10.1002/sdr.70008):

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

From [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices):

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
