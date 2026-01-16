# SDD Toolkit

**Specification-Driven Development Toolkit for Claude Code**

A multi-stack agentic framework that brings disciplined software development practices to any technology stack through intelligent agents, composable skills, and automated quality enforcement.

## Features

- **Multi-Stack Support**: Automatically adapts to JavaScript, Python, Go, Rust, Java, C#, PHP, Ruby, Kotlin, Swift, and more
- **Specification-First Workflow**: Enforces specs before implementation
- **10 Specialized Agents**: Role-based expertise for different aspects of development
- **Task-Oriented Skills**: Workflow skills that load on demand (code-quality, testing, etc.)
- **Language References**: Curated best practices documentation for 10+ languages
- **Security Hooks**: Automatic detection of dangerous commands and secret leaks
- **Quality Automation**: Auto-linting and formatting with support for npm, yarn, pnpm, bun, and more

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

## Plugin Structure

```
sdd-toolkit/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata
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
│       └── observability/
├── hooks/                    # Enforcement hooks
│   ├── hooks.json
│   ├── safety_check.py
│   ├── prevent_secret_leak.py
│   ├── post_edit_quality.sh
│   └── session_summary.sh
├── docs/
│   ├── specs/
│   │   └── SPEC-TEMPLATE.md
│   └── references/           # Language-specific docs
│       └── languages/
│           ├── javascript/
│           ├── python/
│           ├── go/
│           ├── rust/
│           └── ...
├── CLAUDE.md                 # Project instructions
└── README.md
```

## Core Concepts

### Specification-Driven Development (SDD)

The toolkit enforces a disciplined approach:

1. **No Code Without Spec**: Every feature requires an approved specification in `docs/specs/`
2. **Ambiguity Tolerance Zero**: When requirements are unclear, ask questions first
3. **Context Economy**: Use specialized agents to maintain clean orchestrator context

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

Skills are **task-oriented** and provide workflow knowledge that agents load on demand:

**Core Skills** (always applicable):
- `sdd-philosophy`: Specification-driven methodology
- `security-fundamentals`: Security best practices
- `interview`: Structured requirements gathering
- `stack-detector`: Auto-detect project technology

**Workflow Skills** (cross-stack):
- `code-quality`: Linting, formatting, type checking
- `git-mastery`: Conventional commits, changelog
- `testing`: Test pyramid, strategies, frameworks
- `migration`: Safe database schema changes
- `api-design`: REST, GraphQL, gRPC patterns
- `observability`: Logging, metrics, tracing

### Language References

Language-specific best practices are provided as **reference documentation** (not skills) in `docs/references/languages/`:

- JavaScript/TypeScript, Python, Go, Rust, Java, C#, PHP, Ruby, Kotlin, Swift

These are loaded via the `Read` tool when specific language guidance is needed, following the [official Claude Code best practices](https://www.anthropic.com/engineering/claude-code-best-practices) of keeping skills task-oriented rather than language-oriented.

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

Based on detection, appropriate workflow skills and language references are recommended.

## Hooks

Automatic enforcement through lifecycle hooks:

| Hook | Event | Purpose |
|------|-------|---------|
| `safety_check.py` | PreToolUse (Bash) | Blocks `rm -rf /`, `sudo`, curl pipes |
| `prevent_secret_leak.py` | PreToolUse (Write/Edit) | Detects API keys, tokens, passwords |
| `post_edit_quality.sh` | PostToolUse (Write/Edit) | Auto-runs linters and formatters |
| `session_summary.sh` | Stop | Shows git status summary |

## Usage Examples

### Starting a New Feature

```
User: Add user authentication

Claude: I'll use the interview skill to gather requirements first.
        [Asks structured questions]

Claude: Creating specification at docs/specs/feature-auth.md
        [Creates detailed PRD]

Claude: Now delegating to architect for system design...
```

### Working on Existing Code

```
User: Fix the login bug

Claude: Let me use stack-detector to understand the project...
        Detected: JavaScript/TypeScript + React + Node.js

Claude: Loading code-quality skill and reading JS reference docs.
        Delegating to backend-specialist...
```

### Code Quality

```
User: Clean up my code

Claude: Running code-quality skill...
        Detected: ESLint + Prettier in project
        Running: npx eslint --fix && npx prettier --write
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

## Customization

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
description: When to use this skill
allowed-tools: Bash, Read
user-invocable: true
---

# My Skill

## Workflow

1. Step 1
2. Step 2
```

## Best Practices

### Do

- Write specs before code
- Use agents for their specialties
- Let stack-detector identify the project
- Run code-quality after changes
- Document decisions with ADRs

### Don't

- Skip the spec phase
- Hardcode secrets
- Ignore security-auditor findings
- Force a specific stack's patterns on another

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
- [Agent Skills Specification](https://code.claude.com/docs/en/skills)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
