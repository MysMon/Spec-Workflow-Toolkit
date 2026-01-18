# SDD Toolkit Plugin v8.2.0

A Claude Code plugin for specification-driven development with long-running autonomous sessions.

## Core Goals

1. **Long autonomous sessions** - Complete complex tasks across context windows
2. **Spec-driven development** - Zero ambiguity, spec before code
3. **Aggressive subagent delegation** - Protect main context
4. **Sufficient user questions** - Always clarify unknowns

## Project Structure

```
commands/     # /sdd, /code-review, /spec-review, /quick-impl
agents/       # 12 specialized subagents (code-explorer, code-architect, etc.)
skills/       # Core principles and workflow patterns
hooks/        # SessionStart, PreToolUse, PostToolUse, Stop
docs/         # Specs and development guide
```

## Key Commands

- `/sdd` - 7-phase workflow for complex features
- `/code-review` - Parallel review with confidence >= 80%
- `/spec-review` - Validate specifications before implementation
- `/quick-impl` - Fast implementation for small tasks

## Development Rules

### Context Protection (Critical)

**DO NOT explore code yourself. ALWAYS delegate to subagents.**

The main orchestrator must:
- Delegate ALL codebase exploration to `code-explorer` agents
- Only read specific files identified by subagents
- Keep context clean for long sessions

### Model Selection

| Agent | Model | Reason |
|-------|-------|--------|
| `system-architect` | **opus** | Deep reasoning for ADRs |
| `code-explorer`, `code-architect` | sonnet | Analysis tasks |
| `frontend/backend-specialist` | **inherit** | User controls cost/quality |
| Scoring (Haiku in /code-review) | haiku | Fast, cheap |

### Confidence Threshold

Report only issues with confidence >= 80%. Use detailed rubric (0/25/50/75/100).

### Progress Tracking

For long tasks, use JSON progress files:
- `.claude/claude-progress.json` - Resumption context
- `.claude/feature-list.json` - Feature status tracking

## Testing Changes

1. Run Claude Code in this directory
2. Test: `/sdd`, `/code-review`, agents, skills
3. Verify SessionStart hook output

## More Info

See `docs/DEVELOPMENT.md` for detailed development guidelines.
