# Spec-Workflow Toolkit Plugin - Developer Guide

This file is for **Claude working on this plugin repository**.
Users receive context via the `SessionStart` hook, not this file.

## What This Plugin Does

A Claude Code plugin implementing Anthropic's 6 composable patterns for long-running autonomous work:
Plan→Review→Implement→Revise workflow (4 commands with iterative refinement), 13 specialized subagents, TDD integration, evaluator-optimizer loops, checkpoint-based error recovery, and progress tracking.

## Project Structure

```
.claude-plugin/plugin.json   # Plugin metadata
commands/                    # 16 slash commands
agents/                      # 13 subagent definitions
skills/                      # 23 skill definitions
  core/                      #   6 core skills (subagent-contract, spec-philosophy, security-fundamentals, interview, bounded-autonomy, language-enforcement)
  detection/                 #   1 detection skill (stack-detector)
  workflows/                 #   16 workflow skills
hooks/                       # Event handlers (7 event types, 12 handlers) + Python validators
docs/                        # DEVELOPMENT.md (detailed specs), specs/
```

## Key Entry Points

| Task | Start Here |
|------|------------|
| Understand planning (with refinement loops) | `commands/spec-plan.md` |
| Understand interactive plan review | `commands/spec-review.md` |
| Understand implementation phase | `commands/spec-implement.md` |
| Understand post-implementation changes | `commands/spec-revise.md` |
| See how agents work | `agents/code-explorer.md`, `agents/code-architect.md` |
| Understand skill pattern | `skills/core/subagent-contract/SKILL.md` |
| Check hook implementation | `hooks/hooks.json`, `hooks/spec_context.sh` |
| Understand insight tracking | `commands/review-insights.md`, `hooks/insight_capture.sh` |

## Development Rules

### Editing Agents (`agents/*.md`)

YAML frontmatter fields:
- `model`: sonnet (default), opus, haiku, inherit
- `tools`: Available tools
- `disallowedTools`: Explicitly prohibited tools
- `permissionMode`: default, acceptEdits, plan, dontAsk
- `skills`: YAML array of skill names (minimize to preserve context)

### Editing Skills (`skills/**/SKILL.md`)

- Keep SKILL.md ≤ 500 lines, ≤ 5,000 tokens
- Use `reference.md`, `examples.md` for detailed content (loaded on demand)
- Use `scripts/` for executable helpers (run, don't read into context)

### Editing Commands (`commands/*.md`)

- `description`: Shown in `/help`
- `argument-hint`: Placeholder for arguments
- `allowed-tools`: Tools available during execution

**Validation Rule:** Ensure `allowed-tools` includes all tools referenced in instructions. If the command says "Use AskUserQuestion to confirm", then `AskUserQuestion` must be in `allowed-tools`.

### Editing Hooks (`hooks/hooks.json`)

**CRITICAL for PreToolUse hooks:**
- Use JSON decision control (`permissionDecision: "deny"`) with exit 0 (recommended)
- Exit 2 = blocking error
- Exit 1, 3, etc. = non-blocking error (tool may still execute!)

**Global hooks (7 event types, 11 handlers in hooks.json):**

| Hook | Script | Purpose |
|------|--------|---------|
| SessionStart | `spec_context.sh` | Load progress files and notify pending insights |
| PreToolUse (Bash) | `safety_check.py` | Block dangerous commands |
| PreToolUse (Write\|Edit) | `prevent_secret_leak.py` | Prevent secret leakage |
| PreToolUse (WebFetch\|WebSearch) | `external_content_validator.py` | Validate external URLs (SSRF prevention) |
| PostToolUse | `audit_log.sh` | Audit logging for tool usage tracking |
| PreCompact | `pre_compact_save.sh` | Save progress before context compaction |
| SubagentStop | `subagent_summary.sh` | Summarize subagent results |
| SubagentStop | `insight_capture.sh` | Capture marked insights from subagent output |
| SubagentStop | `verify_references.py` | Validate file:line references in subagent output |
| Stop | `session_summary.sh` | Record session summary on exit |
| SessionEnd | `session_cleanup.sh` | Clean up resources on session termination |

**Agent-specific hooks:** Agents can define their own hooks in YAML frontmatter (e.g., `security-auditor.md` defines a stricter Bash validator). These run only when that agent is active. See `docs/DEVELOPMENT.md` "Component-Scoped Hooks" for details.

See `docs/DEVELOPMENT.md` for full hook specification with code examples.

## Content Guidelines

**Skills and agents are fully injected into context. Keep content lean.**

### URL Rule

| Do | Don't |
|----|-------|
| `From Claude Code Best Practices:` | `From [Claude Code Best Practices](https://...):` |
| Plain text source attribution | `## Sources` or `## References` sections |

**Rationale**: URLs consume tokens without adding actionable value. Keep URLs in README.md and DEVELOPMENT.md only.

### Reference Management Rule

When referencing external resources (Anthropic blog posts, official docs, etc.) and adopting their patterns into this plugin:

1. Add the reference to `docs/DEVELOPMENT.md` "Official References" section
2. Use plain text attribution in skills/agents/commands (no URLs)
3. Keep README.md references to essential items only (3-5 max)

### README Guidelines

README.md is **user-facing documentation**. Keep it focused on what users need to know.

**Target**: 200-250 lines maximum

**Include:**
- What the plugin does (in one sentence)
- Quick start (install + first command)
- Command list with brief descriptions
- One diagram maximum (plan→review→implement workflow)
- Best practices (do/don't)
- Link to DEVELOPMENT.md for details

**Exclude (move to DEVELOPMENT.md if needed):**
- Internal implementation details (file structures, why JSON, etc.)
- Multiple Mermaid diagrams
- Exhaustive reference lists
- Rule hierarchy details (L1/L2/L3)
- Marker types and agent coverage tables

**Test**: Can a new user understand what this does and start using it in 30 seconds?

### Documentation Sync Rule

When adding, removing, or renaming components:
1. Update component counts in this file if they change
2. Update `README.md` tables and directory tree (keep README under 250 lines)
3. Update `docs/DEVELOPMENT.md` if templates/specs change

### Version Rule

Version is managed in `plugin.json` only (Single Source of Truth). Do not add version numbers to document titles or content.

### Obsolescence Prevention

Avoid content that becomes outdated when external tools/APIs change.

| Avoid | Instead |
|-------|---------|
| Specific API method names | Conceptual descriptions ("find references") |
| Version numbers ("v2.1.0") | "When available" or omit |
| Prescriptive tool requirements | Examples with alternatives |

**Skills**: Define processes, not static knowledge. Use WebSearch for current options.

**Commands/Agents**: Concrete examples OK if framed as examples, not requirements.

**Time-sensitive queries**: When a year is needed, derive it from the system clock (e.g., `date +%Y`). If results are thin (early in the year), add the previous year and a yearless "latest/recent" query.

See `docs/DEVELOPMENT.md` "Command and Agent Content Guidelines" for details.

## Validation

```bash
/plugin validate
```

## Rule Hierarchy (L1/L2/L3)

This plugin uses a 3-level rule hierarchy for balancing accuracy with creative problem-solving:

| Level | Name | Enforcement | In Skills/Commands |
|-------|------|-------------|-------------------|
| **L1** | Hard Rules | Never break | `NEVER`, `ALWAYS`, `MUST` |
| **L2** | Soft Rules | Default, override with reasoning | `should`, `by default` |
| **L3** | Guidelines | Recommendations | `consider`, `prefer`, `recommend` |

**When writing instructions:**
- Use L1 sparingly (security, safety, data integrity)
- L2 for best practices that may have exceptions
- L3 for suggestions that depend on context

See `docs/DEVELOPMENT.md` "Instruction Design Guidelines" for full specification.

## Coding Standards

- Semantic commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Test hook scripts on both bash and zsh
- Keep documentation in sync with code changes

## More Info

- **For detailed specs and templates**: `docs/DEVELOPMENT.md`
- **For user-facing documentation**: `README.md`
