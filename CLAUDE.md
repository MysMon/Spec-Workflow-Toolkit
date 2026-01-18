# SDD Toolkit Plugin v8.3.0 - Developer Guide

This file is for **developers working on this plugin repository**.
Users who install this plugin receive context via the `SessionStart` hook, not this file.

## What This Plugin Does

A Claude Code plugin providing:
- **7-phase SDD workflow** (`/sdd` command)
- **12 specialized subagents** for task delegation
- **Progress tracking** for long-running sessions
- **Parallel review** with confidence-based filtering

## Project Structure

```
.claude-plugin/plugin.json   # Plugin metadata
commands/                    # Slash command definitions
agents/                      # Subagent definitions (12 roles)
skills/                      # Skill definitions
hooks/                       # Event handlers (SessionStart, etc.)
docs/                        # Specs and detailed docs
```

## Key Files to Understand

| File | Purpose |
|------|---------|
| `hooks/sdd_context.sh` | Delivers context to plugin users (SessionStart) |
| `commands/sdd.md` | Main 7-phase workflow definition |
| `agents/code-explorer.md` | Deep codebase analysis agent |
| `agents/code-architect.md` | Implementation blueprint agent |

## Development Guidelines

### Editing Agent Definitions

Agent files in `agents/` use YAML frontmatter:
- `model`: sonnet, opus, haiku, or inherit
- `tools`: Available tools for the agent
- `permissionMode`: default, acceptEdits, plan, dontAsk

### Editing Commands

Command files in `commands/` define slash command behavior.
Each phase should have clear instructions and expected outputs.

### Editing Hooks

`hooks/hooks.json` maps events to scripts.
`hooks/sdd_context.sh` is the main user-facing context.

## Testing Changes

1. Run `claude` in this directory
2. Verify the SessionStart hook output appears correctly
3. Test modified commands/agents with sample prompts
4. Check that file references and examples are accurate

## Coding Standards

- Use semantic commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Keep documentation in sync with code changes
- Test hook scripts work on both bash and zsh

## More Info

See `docs/DEVELOPMENT.md` for detailed specifications.
