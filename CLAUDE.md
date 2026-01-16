# SDD Toolkit: Multi-Stack Specification-Driven Development

A Claude Code plugin providing disciplined software development practices across **any technology stack**.

> **Based on Official Best Practices**: This plugin follows [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) and [Official Plugin Guidelines](https://code.claude.com/docs/en/plugins).

## Core Philosophy

### Specification-Driven Development (SDD)

1. **No Code Without Spec**: Never implement without an approved specification
2. **Ambiguity Tolerance Zero**: If unclear, ask questions immediately
3. **Context Economy**: Delegate to specialized agents, keep orchestrator clean

### Multi-Stack Approach

This toolkit is **stack-agnostic** by design:
- **Commands** define WHEN to use workflows (`/sdd`, `/code-review`)
- **Agents** define WHAT to do (roles and responsibilities)
- **Skills** define HOW to do it (task-oriented patterns)
- **Stack Detector** auto-identifies project technology

---

## CRITICAL: Context Management & Subagent Delegation

### Protect the Main Context

**The main orchestrator context is precious.** Complex tasks consume tokens rapidly. To maintain effectiveness throughout long sessions:

1. **ALWAYS delegate to subagents** for multi-step or exploratory work
2. **Use `/clear` frequently** to reset when switching tasks
3. **Never accumulate** detailed implementation context in main thread

### Automatic Delegation

Agents have **proactive triggers** in their descriptions. Claude Code will automatically suggest delegation when:
- Task matches agent trigger phrases (e.g., "architecture", "test", "security review")
- Task is complex and multi-step
- Exploration or iteration is needed

### Mandatory Delegation Rules

| Task Type | MUST Delegate To | Why |
|-----------|------------------|-----|
| Requirements gathering | `product-manager` | Keeps exploration out of main context |
| System design | `architect` | Design iterations don't pollute main |
| Frontend implementation | `frontend-specialist` | Implementation details stay isolated |
| Backend implementation | `backend-specialist` | Implementation details stay isolated |
| Testing & QA | `qa-engineer` | Test execution context stays separate |
| Security review | `security-auditor` | Audit trails don't bloat main |
| Infrastructure changes | `devops-sre` | Infra complexity stays contained |
| UI/UX design | `ui-ux-designer` | Design iterations isolated |
| Documentation | `technical-writer` | Doc generation isolated |
| Legacy code analysis | `legacy-modernizer` | Analysis context stays separate |

### How to Delegate

```
Launch the [agent-name] agent to [task description].

Context:
- [Relevant files or specs]
- [Constraints or requirements]

Expected output:
- [What you need back]
```

### When NOT to Delegate

- Single-line fixes
- Reading a specific file
- Simple questions about the codebase
- Quick config changes

---

## Long-Running Tasks & Autonomous Operation

### Checkpoints and Recovery

Claude Code supports **checkpoints** for long-running tasks:
- Code state is saved before each change
- Use `Esc` twice or `/rewind` to restore previous state
- Safe exploration without fear of breaking things

### Background Tasks

For non-blocking operations:
- Dev servers can run in background
- Tests can execute while continuing work
- Use `Ctrl+B` to send running tasks to background

### Subagent Resumption

Subagents maintain their context and can be resumed:
- Each subagent has isolated context window
- Resume with "Continue that [task]" to preserve history
- Automatic compaction when context limit approaches

### TodoWrite for Progress Tracking

**CRITICAL**: Use TodoWrite tool extensively for:
- Breaking down complex tasks
- Tracking progress across context boundaries
- Maintaining visibility during long operations
- Documenting completed steps

Example workflow:
```
1. Create todo list at task start
2. Mark items in_progress when starting
3. Mark completed immediately when done
4. Add new items as they're discovered
```

---

## Quick Reference

### Workflow Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/sdd` | Full 6-phase development workflow | New features, complex changes |
| `/spec-review` | Parallel spec validation | Before implementation |
| `/code-review` | Parallel code review | Before committing |
| `/quick-impl` | Fast implementation | Small, clear tasks |

### Development Phases

| Phase | Action | Agent/Skill |
|-------|--------|-------------|
| 1. Ambiguity | Receive vague request | - |
| 2. Clarification | Gather requirements | `product-manager` + `interview` |
| 3. Definition | Create specification | `product-manager` |
| 4. Design | Architecture decisions | `architect` |
| 5. Implementation | Write code | `*-specialist` agents |
| 6. Verification | Test and audit | `qa-engineer` + `security-auditor` |

### Skill Categories

| Category | Skills | Purpose |
|----------|--------|---------|
| Core | `sdd-philosophy`, `security-fundamentals`, `interview` | Universal principles |
| Detection | `stack-detector` | Auto-detect project technology |
| Workflows | `code-quality`, `git-mastery`, `testing`, `migration`, `api-design`, `observability` | Cross-stack workflows |

---

## Operational Rules

### Security (OPSEC)

- **NEVER** output real API keys, passwords, or secrets
- **NEVER** commit `.env` files (must be in `.gitignore`)
- **ALWAYS** run `security-auditor` before marking critical tasks complete
- Hooks automatically detect and block secret leaks

### Error Handling

- Do not blindly retry failed commands
- Analyze stderr first, form hypothesis
- For complex debugging, delegate to specialist agent

### Code Quality

- Write tests BEFORE implementation (Red-Green-Refactor)
- Follow semantic commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Use `code-quality` skill after edits
- All UI must meet WCAG 2.1 AA accessibility

---

## File Locations

```
commands/            # Workflow commands (/sdd, /code-review, etc.)
agents/              # Specialized subagents (10 roles)
skills/              # Task-oriented skills with progressive disclosure
  ├── core/          # Universal principles
  ├── detection/     # Stack detection
  └── workflows/     # Cross-stack workflows
hooks/               # Automatic enforcement hooks
docs/specs/          # Specifications (required before implementation)
docs/specs/SPEC-TEMPLATE.md  # Specification template
```

---

## Hooks (Automatic Enforcement)

| Hook | Trigger | Purpose |
|------|---------|---------|
| `sdd_context.sh` | SessionStart (once) | Inject SDD philosophy reminder |
| `subagent_init.sh` | SubagentStart | Initialize subagent context |
| `safety_check.py` | PreToolUse (Bash) | Block dangerous commands |
| `prevent_secret_leak.py` | PreToolUse (Write/Edit) | Detect secrets |
| `post_edit_quality.sh` | PostToolUse (Write/Edit) | Auto-lint/format |
| `subagent_summary.sh` | SubagentStop | Log subagent completions |
| `session_summary.sh` | Stop | Git status summary |

---

## Best Practices for Long-Running Sessions

### 1. Use Commands for Structure

Start complex work with `/sdd` - it orchestrates the full workflow and manages subagent delegation automatically.

### 2. Delegate Aggressively

When in doubt, delegate. A subagent running in isolation:
- Has its own context window
- Returns only the essential result
- Keeps main context clean

### 3. Clear Between Major Tasks

After completing a feature or major task:
```
/clear
```
Then start fresh with the next task.

### 4. Use TodoWrite for Progress

Track progress with the todo list to maintain visibility across context boundaries. **This is critical for autonomous operation.**

### 5. Trust the Workflow

The `/sdd` command implements proven patterns:
- Phase gates prevent premature implementation
- Parallel reviews catch issues early
- Mandatory specs reduce rework

### 6. Leverage Checkpoints

Before risky changes:
- Checkpoint is automatic before each edit
- Use `/rewind` if something goes wrong
- Experiment freely with safety net

---

## Official Resources

- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Agent Skills Guide](https://code.claude.com/docs/en/skills)
- [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)
- [Official Plugin Marketplace](https://github.com/anthropics/claude-plugins-official)
