# SDD Toolkit Plugin - Developer Guide

This file is for **Claude working on this plugin repository**.
Users receive context via the `SessionStart` hook, not this file.

## What This Plugin Does

A Claude Code plugin implementing Anthropic's 6 composable patterns for long-running autonomous work:
7-phase SDD workflow, 12 specialized subagents, TDD integration, evaluator-optimizer loops, checkpoint-based error recovery, and progress tracking.

## Project Structure

```
.claude-plugin/plugin.json   # Plugin metadata
commands/                    # 7 slash commands
agents/                      # 12 subagent definitions
skills/                      # 17 skill definitions (core/, detection/, workflows/)
hooks/                       # Event handlers + Python validators
docs/                        # DEVELOPMENT.md (detailed specs), specs/
```

## Key Entry Points

| Task | Start Here |
|------|------------|
| Understand main workflow | `commands/sdd.md` |
| See how agents work | `agents/code-explorer.md`, `agents/code-architect.md` |
| Understand skill pattern | `skills/core/subagent-contract/SKILL.md` |
| Check hook implementation | `hooks/hooks.json`, `hooks/sdd_context.sh` |

## Development Rules

### Editing Agents (`agents/*.md`)

YAML frontmatter fields:
- `model`: sonnet (default), opus, haiku, inherit
- `tools`: Available tools
- `disallowedTools`: Explicitly prohibited tools
- `permissionMode`: default, acceptEdits, plan, dontAsk
- `skills`: Comma-separated skill names (minimize to preserve context)

### Editing Skills (`skills/**/SKILL.md`)

- Keep SKILL.md ≤ 500 lines, ≤ 5,000 tokens
- Use `reference.md`, `examples.md` for detailed content (loaded on demand)
- Use `scripts/` for executable helpers (run, don't read into context)

### Editing Commands (`commands/*.md`)

- `description`: Shown in `/help`
- `argument-hint`: Placeholder for arguments
- `allowed-tools`: Tools available during execution

### Editing Hooks (`hooks/hooks.json`)

**CRITICAL for PreToolUse hooks:**
- Use JSON decision control (`permissionDecision: "deny"`) with exit 0 (recommended)
- Exit 2 = blocking error
- Exit 1, 3, etc. = non-blocking error (tool may still execute!)

See `docs/DEVELOPMENT.md` for full hook specification with code examples.

## Content Guidelines

**Skills and agents are fully injected into context. Keep content lean.**

### URL Rule

| Do | Don't |
|----|-------|
| `From Claude Code Best Practices:` | `From [Claude Code Best Practices](https://...):` |
| Plain text source attribution | `## Sources` or `## References` sections |

**Rationale**: URLs consume tokens without adding actionable value. Keep URLs in README.md and DEVELOPMENT.md only.

### Documentation Sync Rule

When adding, removing, or renaming components:
1. Update component counts in this file if they change
2. Update `README.md` tables and directory tree
3. Update `docs/DEVELOPMENT.md` if templates/specs change

### Version Rule

Version is managed in `plugin.json` only (Single Source of Truth). Do not add version numbers to document titles or content.

## Validation

```bash
/plugin validate
```

## Coding Standards

- Semantic commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Test hook scripts on both bash and zsh
- Keep documentation in sync with code changes

## More Info

- **For detailed specs and templates**: `docs/DEVELOPMENT.md`
- **For user-facing documentation**: `README.md`
