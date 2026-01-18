# SDD Toolkit Plugin v9.0.0 - Developer Guide

This file is for **developers working on this plugin repository**.
Users who install this plugin receive context via the `SessionStart` hook, not this file.

## What This Plugin Does

A Claude Code plugin implementing all 6 Anthropic composable patterns for long-running autonomous work:

- **7-phase SDD workflow** (`/sdd` command) - Prompt Chaining pattern
- **12 specialized subagents** for task delegation - Orchestrator-Workers pattern
- **TDD integration** with Red-Green-Refactor cycle
- **Evaluator-Optimizer loops** for iterative quality improvement
- **Checkpoint-based error recovery** for resilient workflows
- **Standardized subagent contracts** for consistent results
- **Progress tracking** for long-running sessions - Augmented LLM pattern
- **Parallel review** with confidence-based filtering - Parallelization pattern

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
| `skills/core/composable-patterns/SKILL.md` | Anthropic's 6 patterns documentation |
| `skills/workflows/tdd-workflow/SKILL.md` | Test-driven development workflow |
| `skills/workflows/evaluator-optimizer/SKILL.md` | Iterative improvement pattern |
| `skills/workflows/error-recovery/SKILL.md` | Checkpoint and recovery patterns |
| `skills/core/subagent-contract/SKILL.md` | Standardized result formats |

## Available Agents (12 Specialized Roles)

| Agent | Model | Role | permissionMode |
|-------|-------|------|----------------|
| `code-explorer` | Sonnet | Deep codebase analysis | plan (read-only) |
| `code-architect` | Sonnet | Implementation blueprints | plan (read-only) |
| `system-architect` | **Opus** | System design, ADRs | acceptEdits |
| `product-manager` | **Opus** | Requirements gathering | acceptEdits |
| `frontend-specialist` | inherit | UI implementation | acceptEdits |
| `backend-specialist` | inherit | API implementation | acceptEdits |
| `qa-engineer` | Sonnet | Testing, quality review | acceptEdits |
| `security-auditor` | Sonnet | Security audit | plan (read-only) |
| `devops-sre` | Sonnet | CI/CD, infrastructure | acceptEdits |
| `technical-writer` | Sonnet | Documentation | acceptEdits |
| `ui-ux-designer` | Sonnet | Design specifications | plan (Write for specs only) |
| `legacy-modernizer` | Sonnet | Code modernization | acceptEdits |

## Available Commands

| Command | Purpose |
|---------|---------|
| `/sdd` | 7-phase Specification-Driven Development workflow |
| `/code-review` | Parallel code review with confidence scoring |
| `/spec-review` | Specification validation before implementation |
| `/quick-impl` | Fast implementation for small, clear tasks |

## Skills (18 Total)

### Core Skills
| Skill | Purpose |
|-------|---------|
| `composable-patterns` | Anthropic's 6 patterns documentation |
| `subagent-contract` | Standardized result formats |
| `sdd-philosophy` | Spec-first development principles |
| `security-fundamentals` | Security best practices |
| `interview` | Structured requirements gathering |

### Detection Skills
| Skill | Purpose |
|-------|---------|
| `stack-detector` | Technology stack auto-detection |

### Workflow Skills
| Skill | Purpose |
|-------|---------|
| `tdd-workflow` | Test-driven development |
| `evaluator-optimizer` | Iterative improvement |
| `error-recovery` | Checkpoint and recovery |
| `progress-tracking` | JSON-based state persistence |
| `long-running-tasks` | Multi-session work patterns |
| `parallel-execution` | Concurrent agent coordination |
| `code-quality` | Linting and formatting |
| `testing` | Test pyramid and strategies |
| `git-mastery` | Conventional Commits |
| `api-design` | API specification patterns |
| `migration` | Code migration strategies |
| `observability` | Monitoring and logging |

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

**CRITICAL for PreToolUse hooks:**
- Use JSON decision control (`permissionDecision: "deny"`) with exit 0 (recommended)
- Exit 2 = blocking error (tool blocked, error shown to Claude)
- Other non-zero exit codes (1, 3, etc.) = non-blocking error (tool may still execute!)
- See `docs/DEVELOPMENT.md` for full hook specification

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
