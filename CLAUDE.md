# SDD Toolkit: Multi-Stack Specification-Driven Development

A Claude Code plugin providing disciplined software development practices across **any technology stack**.

## Core Philosophy

### Specification-Driven Development (SDD)

1. **No Code Without Spec**: Never implement without an approved specification
2. **Ambiguity Tolerance Zero**: If unclear, ask questions immediately
3. **Context Economy**: Delegate to specialized agents, keep orchestrator clean

### Multi-Stack Approach

This toolkit is **stack-agnostic** by design:
- **Agents** define WHAT to do (roles and responsibilities)
- **Skills** define HOW to do it (stack-specific patterns)
- **Stack Detector** auto-identifies project technology and loads appropriate skills

## Quick Reference

### Development Phases

| Phase | Action | Agent/Skill |
|-------|--------|-------------|
| 1. Ambiguity | Receive vague request | - |
| 2. Clarification | Gather requirements | `product-manager` + `interview` |
| 3. Definition | Create specification | `product-manager` |
| 4. Design | Architecture decisions | `architect` |
| 5. Implementation | Write code | `*-specialist` agents |
| 6. Verification | Test and audit | `qa-engineer` + `security-auditor` |

### Agent Delegation Table

| Task | Delegate To |
|------|-------------|
| Requirements & specs | `product-manager` |
| System design | `architect` |
| Frontend implementation | `frontend-specialist` |
| Backend implementation | `backend-specialist` |
| Testing & QA | `qa-engineer` |
| Security review | `security-auditor` |
| Infrastructure | `devops-sre` |
| UI/UX design | `ui-ux-designer` |
| Documentation | `technical-writer` |
| Legacy modernization | `legacy-modernizer` |

### Skill Categories

| Category | Skills | Purpose |
|----------|--------|---------|
| Core | `sdd-philosophy`, `security-fundamentals`, `interview` | Universal principles |
| Detection | `stack-detector` | Auto-detect project technology |
| Languages | `javascript`, `python`, `go`, `rust`, `java`, `csharp`, `php`, `ruby`, `kotlin`, `swift` | Language-specific patterns |
| Workflows | `code-quality`, `git-mastery`, `testing`, `migration`, `api-design`, `observability` | Cross-stack workflows |

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

## File Locations

```
docs/specs/          # Specifications (required before implementation)
docs/specs/SPEC-TEMPLATE.md  # Specification template
```

## Hooks (Automatic Enforcement)

| Hook | Trigger | Purpose |
|------|---------|---------|
| `safety_check.py` | PreToolUse (Bash) | Block dangerous commands |
| `prevent_secret_leak.py` | PreToolUse (Write/Edit) | Detect secrets |
| `post_edit_quality.sh` | PostToolUse (Write/Edit) | Auto-lint/format |
| `session_summary.sh` | Stop | Git status summary |
