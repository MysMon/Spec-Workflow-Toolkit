# SDD Toolkit v8.2

**Specification-Driven Development Toolkit for Claude Code**

A multi-stack agentic framework designed for **long-running autonomous work sessions**. Features 7-phase workflow, aggressive subagent delegation, JSON-based progress tracking, and resumable sessions. Based on official Anthropic best practices.

> **Based on Official Best Practices**:
> - [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
> - [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
> - [Official Plugin Marketplace](https://github.com/anthropics/claude-plugins-official)
> - [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)

## What's New in v8.2

| Feature | Description |
|---------|-------------|
| **Enhanced Initializer/Coding Role Detection** | SessionStart hook now explicitly displays current role (Initializer vs Coding) based on progress file presence |
| **Strengthened Context Protection** | "DO NOT explore code yourself" - clearer delegation rules for long autonomous sessions |
| **Model Selection Strategy** | Opus for system-architect (complex reasoning), Haiku for quick lookups, Sonnet for balanced tasks |
| **Tool Alignment with Official Pattern** | code-explorer/code-architect now include NotebookRead for Jupyter support |
| **Thoroughness-Based Model Guidance** | code-explorer notes when to use built-in Explore (Haiku) vs this agent (Sonnet) |

## Previous Versions

### v8.1
- Opus for system-architect (ADRs, schemas, contracts require deep reasoning)
- `inherit` model for implementation agents (user controls cost/quality tradeoff)

### v8.0
- code-architect agent with definitive recommendations
- 5-agent parallel code review + Haiku scorers

### v7.0
- 7-phase workflow aligned with official feature-dev plugin
- JSON progress tracking and auto-resume detection
- Confidence threshold 80%

## Features

- **7-Phase Workflow**: `/sdd` command with Discovery, Codebase Exploration, Clarifying Questions, Architecture Design, Implementation, Quality Review, Summary
- **11 Specialized Agents**: Including new `code-explorer` for deep codebase analysis
- **Multi-Stack Support**: Automatically adapts to JavaScript, Python, Go, Rust, Java, C#, PHP, Ruby, Kotlin, Swift, and more
- **Specification-First Workflow**: Enforces specs before implementation
- **JSON Progress Tracking**: `claude-progress.json` and `feature-list.json` for long-running tasks
- **Resumable Sessions**: SessionStart hook detects and reports progress files
- **Parallel Agent Execution**: Run multiple independent agents simultaneously
- **Context Protection**: Aggressive subagent delegation to preserve main context
- **Confidence Scoring**: 80% threshold for actionable recommendations
- **Security Hooks**: Automatic detection of dangerous commands and secret leaks

## Installation

### As a Claude Code Plugin

```bash
# Install from plugin directory
/plugin install sdd-toolkit@your-marketplace

# Or load directly for development
claude --plugin-dir /path/to/sdd-toolkit
```

### For Project Integration

Copy the `.claude-plugin` directory and relevant components to your project.

## Quick Start

### For New Features

```bash
# Start the full 7-phase SDD workflow
/sdd Add user authentication with OAuth support

# Or start interactively
/sdd
```

### For Reviewing Work

```bash
# Review a specification before implementation
/spec-review docs/specs/user-auth.md

# Review code before committing (parallel agents, confidence >= 80)
/code-review staged
```

### For Small Tasks

```bash
# Quick implementation for well-defined tasks
/quick-impl Fix typo in README.md
```

## Plugin Structure

```
sdd-toolkit/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata (v8.2.0)
├── commands/                 # Workflow commands
│   ├── sdd.md               # Full 7-phase workflow with parallel agents
│   ├── spec-review.md       # Parallel spec review
│   ├── code-review.md       # Parallel code review (confidence >= 80)
│   └── quick-impl.md        # Fast implementation
├── agents/                   # 11 specialized agents
│   ├── code-explorer.md     # NEW: Deep codebase analysis (read-only)
│   ├── product-manager.md
│   ├── system-architect.md
│   ├── frontend-specialist.md
│   ├── backend-specialist.md
│   ├── qa-engineer.md
│   ├── security-auditor.md
│   ├── devops-sre.md
│   ├── ui-ux-designer.md
│   ├── technical-writer.md
│   └── legacy-modernizer.md
├── skills/                   # Task-oriented skills
│   ├── core/                 # Universal principles
│   │   ├── sdd-philosophy/
│   │   ├── security-fundamentals/
│   │   └── interview/
│   ├── detection/            # Stack detection
│   │   └── stack-detector/
│   └── workflows/            # Cross-stack workflows
│       ├── code-quality/
│       ├── git-mastery/
│       ├── testing/
│       ├── migration/
│       ├── api-design/
│       ├── observability/
│       ├── long-running-tasks/
│       ├── parallel-execution/
│       └── progress-tracking/  # NEW: JSON-based state persistence
├── hooks/                    # Enforcement hooks
│   ├── hooks.json
│   ├── sdd_context.sh       # SessionStart: inject context + detect progress
│   ├── safety_check.py      # PreToolUse: block dangerous commands
│   ├── prevent_secret_leak.py # PreToolUse: detect secrets
│   ├── post_edit_quality.sh # PostToolUse: auto-lint/format
│   ├── subagent_summary.sh  # SubagentStop: log completions
│   └── session_summary.sh   # Stop: git status summary
├── docs/
│   └── specs/
│       └── SPEC-TEMPLATE.md
├── CLAUDE.md                 # Project instructions
└── README.md
```

## 7-Phase SDD Workflow

The `/sdd` command orchestrates a comprehensive development workflow:

### Phase 1: Discovery
Understand what needs to be built, identify stakeholders, document constraints.

### Phase 2: Codebase Exploration (Parallel Agents)
Launch 2-3 `code-explorer` agents to:
- Trace similar feature implementations
- Map overall architecture
- Analyze UI patterns (if frontend work)

### Phase 3: Clarifying Questions
Fill gaps, resolve ambiguities, confirm edge cases. **Waits for user answers.**

### Phase 4: Architecture Design (Parallel Agents)
Launch 2-3 `code-architect` agents with different focuses:
- Reuse focus (maximum pattern reuse)
- Extensibility focus (clean abstractions)
- Performance focus (if relevant)

Each returns **definitive recommendations** based on codebase patterns with file:line references.

### Phase 5: Implementation
After explicit user approval:
- Initialize JSON progress tracking
- Delegate to specialist agents
- Track progress with TodoWrite

### Phase 6: Quality Review (Parallel Agents)
Launch 3 review agents:
- `qa-engineer` - Test coverage, edge cases
- `security-auditor` - OWASP Top 10, vulnerabilities
- `code-explorer` - Verify implementation matches design

**Confidence threshold: 80%** for actionable issues.

### Phase 7: Summary
Document what was built, key decisions, files modified, next steps.

## JSON Progress Tracking

Based on Anthropic's long-running agent harness pattern:

### claude-progress.json
```json
{
  "project": "feature-name",
  "status": "in_progress",
  "currentTask": "Implementing auth service",
  "resumptionContext": {
    "position": "Phase 5 - Implementation",
    "nextAction": "Create AuthService in src/services/auth.ts",
    "blockers": []
  }
}
```

### feature-list.json
```json
{
  "features": [
    {"id": "F001", "name": "User registration", "status": "completed"},
    {"id": "F002", "name": "User login", "status": "in_progress"},
    {"id": "F003", "name": "Password reset", "status": "pending"}
  ]
}
```

**Why JSON?** "Models are less likely to inappropriately modify JSON files compared to Markdown files." - Anthropic

## Agents

| Agent | Purpose |
|-------|---------|
| `code-explorer` | Deep codebase analysis with file:line references (read-only) |
| `code-architect` | **NEW**: Feature implementation blueprints with definitive recommendations |
| `product-manager` | Requirements gathering, PRD creation, spec writing |
| `system-architect` | System-level design, ADRs, API contracts, database schema |
| `frontend-specialist` | UI implementation (adapts to React, Vue, Angular, etc.) |
| `backend-specialist` | API implementation (adapts to Node, Python, Go, etc.) |
| `qa-engineer` | Test strategy and automation (confidence >= 80) |
| `security-auditor` | Security review (read-only, confidence >= 80) |
| `devops-sre` | Infrastructure, CI/CD, deployment |
| `ui-ux-designer` | Design systems, accessibility |
| `technical-writer` | Documentation, changelogs, API docs |
| `legacy-modernizer` | Safe refactoring, characterization testing |

## Skills

**Core Skills** (always applicable):
- `sdd-philosophy`: Specification-driven methodology
- `security-fundamentals`: Security best practices (OWASP, secrets)
- `interview`: Structured requirements gathering
- `stack-detector`: Auto-detect project technology

**Workflow Skills** (cross-stack):
- `code-quality`: Linting, formatting, type checking
- `git-mastery`: Conventional commits, changelog
- `testing`: Test pyramid, strategies, frameworks
- `migration`: Safe database schema changes
- `api-design`: REST, GraphQL, gRPC patterns
- `observability`: Logging, metrics, tracing
- `long-running-tasks`: State persistence, session resumption
- `parallel-execution`: Multi-agent coordination
- `progress-tracking`: **NEW**: JSON-based state persistence

## Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `sdd_context.sh` | SessionStart | Injects SDD context, **detects progress files**, supports resumption |
| `safety_check.py` | PreToolUse (Bash) | Blocks `rm -rf /`, `sudo`, curl pipes |
| `prevent_secret_leak.py` | PreToolUse (Write/Edit) | Detects API keys, tokens, passwords |
| `post_edit_quality.sh` | PostToolUse (Write/Edit) | Auto-runs linters and formatters |
| `subagent_summary.sh` | SubagentStop | Logs completion and prompts for next action |
| `session_summary.sh` | Stop | Shows git status summary |

## Best Practices

### Do

- Start complex work with `/sdd`
- Delegate aggressively to subagents (especially `code-explorer`)
- Use `/clear` between major tasks
- Write specs before code
- Run `/code-review` before committing
- Use JSON progress tracking for long tasks
- Trust agents with confidence >= 80

### Don't

- Skip the exploration phase
- Accumulate context in main thread
- Hardcode secrets
- Ignore security-auditor findings
- Report issues with confidence < 80

## Customization

### Adding a New Command

Create `commands/my-command.md` with YAML frontmatter.

### Adding a New Agent

Create `agents/my-agent.md` with YAML frontmatter including `description`, `model`, `tools`, `skills`.

### Adding a New Skill

Create `skills/category/my-skill/SKILL.md` with YAML frontmatter.

See `CLAUDE.md` for detailed templates.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write a spec for your change
4. Implement following the spec
5. Submit a PR

## License

MIT

---

**Sources:**
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Official Plugin Marketplace](https://github.com/anthropics/claude-plugins-official)
- [Agent Skills Specification](https://code.claude.com/docs/en/skills)
