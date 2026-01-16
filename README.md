# SDD Toolkit v6.0

**Specification-Driven Development Toolkit for Claude Code**

A multi-stack agentic framework that brings disciplined software development practices to any technology stack through intelligent agents, composable skills, workflow commands, and automated quality enforcement.

> **Based on Official Best Practices**: This plugin follows [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) and [Official Plugin Guidelines](https://code.claude.com/docs/en/plugins).

## Features

- **Workflow Commands**: `/sdd`, `/spec-review`, `/code-review`, `/quick-impl` for structured development
- **Multi-Stack Support**: Automatically adapts to JavaScript, Python, Go, Rust, Java, C#, PHP, Ruby, Kotlin, Swift, and more
- **Specification-First Workflow**: Enforces specs before implementation
- **10 Specialized Agents**: Role-based expertise with confidence scoring for reviews
- **Task-Oriented Skills**: Workflow skills that load on demand with smart trigger phrases
- **Context Protection**: Aggressive subagent delegation to preserve main context
- **Long-Running Task Support**: File-based state persistence and TodoWrite integration
- **Parallel Agent Execution**: Run multiple independent reviews simultaneously
- **Security Hooks**: Automatic detection of dangerous commands and secret leaks
- **Quality Automation**: Auto-linting and formatting with support for all major languages

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
# Start the full SDD workflow
/sdd Add user authentication with OAuth support

# Or start interactively
/sdd
```

### For Reviewing Work

```bash
# Review a specification before implementation
/spec-review docs/specs/user-auth.md

# Review code before committing
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
│   └── plugin.json           # Plugin metadata
├── commands/                 # Workflow commands
│   ├── sdd.md               # Full 6-phase workflow
│   ├── spec-review.md       # Parallel spec review
│   ├── code-review.md       # Parallel code review
│   └── quick-impl.md        # Fast implementation
├── agents/                   # 10 specialized agents
│   ├── product-manager.md
│   ├── architect.md
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
│       ├── long-running-tasks/   # State persistence patterns
│       └── parallel-execution/   # Multi-agent coordination
├── hooks/                    # Enforcement hooks
│   ├── hooks.json
│   ├── sdd_context.sh       # SessionStart: inject SDD context
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

## Core Concepts

### Specification-Driven Development (SDD)

The toolkit enforces a disciplined approach:

1. **No Code Without Spec**: Every feature requires an approved specification in `docs/specs/`
2. **Ambiguity Tolerance Zero**: When requirements are unclear, ask questions first
3. **Context Economy**: Delegate to specialized agents to protect main context

### Context Protection

**The main context is precious.** Complex tasks consume tokens rapidly. The toolkit implements:

- **Mandatory delegation** for requirements, design, implementation, and review
- **SessionStart hook** that reminds about SDD principles
- **SubagentStop hook** that prompts for next actions
- **Workflow commands** that orchestrate delegation automatically

### Workflow Commands

| Command | Purpose | Phases |
|---------|---------|--------|
| `/sdd` | Full development workflow | 6: Discovery → Requirements → Design → Implementation → Review → Summary |
| `/spec-review` | Parallel specification review | 4 agents: Completeness, Feasibility, Security, Quality |
| `/code-review` | Parallel code review | 4 agents: Compliance, Bugs, Security, Quality |
| `/quick-impl` | Fast implementation | 1: Implement (with guardrails) |

### Hub-and-Spoke Architecture

```
                    ┌─────────────────┐
                    │   Orchestrator  │
                    │      (Hub)      │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ product-      │  │   architect   │  │  frontend-    │
│ manager       │  │               │  │  specialist   │
└───────────────┘  └───────────────┘  └───────────────┘
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│  interview    │  │stack-detector │  │ code-quality  │
│    skill      │  │    skill      │  │    skill      │
└───────────────┘  └───────────────┘  └───────────────┘
```

### Agents

Agents define **roles and responsibilities** without being tied to specific technologies:

| Agent | Purpose |
|-------|---------|
| `product-manager` | Requirements gathering, PRD creation, spec writing |
| `architect` | System design, API design, database schema |
| `frontend-specialist` | UI implementation (adapts to React, Vue, Angular, etc.) |
| `backend-specialist` | API implementation (adapts to Node, Python, Go, etc.) |
| `qa-engineer` | Test strategy and automation |
| `security-auditor` | Security review and vulnerability assessment |
| `devops-sre` | Infrastructure, CI/CD, deployment |
| `ui-ux-designer` | Design systems, accessibility |
| `technical-writer` | Documentation, changelogs, API docs |
| `legacy-modernizer` | Safe refactoring, characterization testing |

### Skills

Skills are **task-oriented** with smart trigger phrases for automatic discovery:

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
- `long-running-tasks`: State persistence, session resumption, progress tracking
- `parallel-execution`: Multi-agent coordination, result aggregation

### Stack Detection

The `stack-detector` skill automatically identifies your project:

```bash
# Detected from config files:
package.json       → JavaScript/TypeScript (npm/yarn/pnpm/bun)
pyproject.toml     → Python (pip/poetry/uv)
go.mod             → Go
Cargo.toml         → Rust
pom.xml            → Java (Maven)
build.gradle.kts   → Kotlin (Gradle)
*.csproj           → C# / .NET
composer.json      → PHP
Gemfile            → Ruby
Package.swift      → Swift
```

## Hooks

Automatic enforcement through lifecycle hooks:

| Hook | Event | Purpose |
|------|-------|---------|
| `sdd_context.sh` | SessionStart | Injects SDD philosophy and available commands |
| `safety_check.py` | PreToolUse (Bash) | Blocks `rm -rf /`, `sudo`, curl pipes |
| `prevent_secret_leak.py` | PreToolUse (Write/Edit) | Detects API keys, tokens, passwords |
| `post_edit_quality.sh` | PostToolUse (Write/Edit) | Auto-runs linters and formatters |
| `subagent_summary.sh` | SubagentStop | Logs completion and prompts for next action |
| `session_summary.sh` | Stop | Shows git status summary |

## Usage Examples

### Full Development Workflow

```
User: /sdd Add user authentication with OAuth

Claude: Starting SDD workflow...

Phase 1: Discovery
- Analyzing request
- Identifying stakeholders

Phase 2: Requirements (delegating to product-manager)
- Launching product-manager agent...
- [Agent gathers requirements]

Phase 3: Design (delegating to architect)
- Launching architect agent...
- [Agent proposes architecture options]

Phase 4: Implementation (delegating to specialists)
- Launching backend-specialist agent...
- Launching frontend-specialist agent...

Phase 5: Review (parallel agents)
- Launching qa-engineer, security-auditor, code-quality...

Phase 6: Summary
- Feature complete
- All tests passing
- Security review: Passed
```

### Parallel Code Review

```
User: /code-review staged

Claude: Launching 4 parallel review agents...

Agent 1 (CLAUDE.md Compliance): Checking guidelines...
Agent 2 (Bug Detection): Analyzing for bugs...
Agent 3 (Security): Scanning for vulnerabilities...
Agent 4 (Quality): Reviewing maintainability...

Review complete. Found 2 issues (confidence >= 80):

1. Missing input validation on email field (Confidence: 92)
   File: src/auth/register.ts:45

2. SQL injection risk in query (Confidence: 88)
   File: src/db/users.ts:23

What would you like to do?
1. Fix issues now
2. Proceed anyway
3. Get more details
```

## Specification Template

All features require a spec. Use the template at `docs/specs/SPEC-TEMPLATE.md`:

```markdown
# Feature: [Name]

## Overview
[Business value summary]

## User Stories
US-001: As a [user], I want [goal], so that [benefit]

## Functional Requirements
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-001 | [What] | P0 | [Testable condition] |

## Non-Functional Requirements
| ID | Category | Requirement |
|----|----------|-------------|
| NFR-001 | Performance | [Target] |

## Out of Scope
- [Explicitly excluded items]

## Approval
[ ] Product Owner
[ ] Tech Lead
```

## Best Practices

### Do

- Start complex work with `/sdd`
- Delegate aggressively to subagents
- Use `/clear` between major tasks
- Write specs before code
- Run `/code-review` before committing
- Let stack-detector identify the project

### Don't

- Skip the spec phase
- Accumulate context in main thread
- Hardcode secrets
- Ignore security-auditor findings
- Force a specific stack's patterns on another

## Customization

### Adding a New Command

Create `commands/my-command.md`:

```markdown
---
description: "What this command does"
argument-hint: "[optional args]"
allowed-tools: Read, Write, Task
---

# /my-command

Instructions for the command...
```

### Adding a New Agent

Create `agents/my-agent.md`:

```markdown
---
name: my-agent
description: When to use this agent
model: sonnet
tools: Read, Glob, Grep, Write, Edit, Bash
skills: relevant-skill
---

# Role: My Agent

Your responsibilities...

## Workflow

1. Step 1
2. Step 2

## Rules

- Rule 1
- Rule 2
```

### Adding a New Skill

Create `skills/category/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: |
  What this skill does. Use when:
  - Condition 1
  - Condition 2
  Trigger phrases: keyword1, keyword2, keyword3
allowed-tools: Bash, Read
user-invocable: true
---

# My Skill

## Workflow

1. Step 1
2. Step 2
```

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
- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Agent Skills Specification](https://code.claude.com/docs/en/skills)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
