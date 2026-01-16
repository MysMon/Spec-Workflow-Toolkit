#!/bin/bash
# SessionStart Hook: Inject SDD context and operational guidance
# This hook runs once at session start to provide plugin context to the user's project
# Based on: https://www.anthropic.com/engineering/claude-code-best-practices

cat << 'EOF'
## SDD Toolkit v6.0 - Session Initialized

### Core Principles (Spec-First Development)

1. **No Code Without Spec** - Never implement without approved specification
2. **Ambiguity Tolerance Zero** - If unclear, ask immediately using AskUserQuestion
3. **Protect Main Context** - Delegate complex work to subagents to preserve tokens

### Context Management (Critical for Long Sessions)

**ALWAYS delegate to subagents** for multi-step or exploratory work:
- Subagents run in isolated context windows
- Only results/summaries return to main context
- Main orchestrator stays clean and focused

| Task Type | Delegate To | Why |
|-----------|-------------|-----|
| Requirements | `product-manager` | Exploration stays isolated |
| Design | `architect` | Iterations don't pollute main |
| Frontend | `frontend-specialist` | Implementation details contained |
| Backend | `backend-specialist` | Implementation details contained |
| Testing | `qa-engineer` | Test execution isolated |
| Security | `security-auditor` | Audit trails separate |

### Long-Running Task Support

For complex multi-step tasks:
1. **Use TodoWrite extensively** - Track progress, break down tasks
2. **Use file-based state** - Write plans to `docs/plans/` for persistence
3. **Mark todos immediately** - Complete items as soon as done (don't batch)
4. **One in_progress at a time** - Focus on current task

### Available Commands

| Command | Use When |
|---------|----------|
| `/sdd` | New features, complex changes (6-phase workflow) |
| `/spec-review` | Validate specifications before implementation |
| `/code-review` | Review code before committing (parallel agents) |
| `/quick-impl` | Small, clear tasks with obvious scope |

### Parallel Agent Execution

For independent reviews or analyses, launch multiple agents simultaneously:
```
Launch these agents in parallel:
1. qa-engineer - Test coverage analysis
2. security-auditor - Security review
3. code-quality skill - Lint and format check
```

### Quick Reference

- **Specs location**: `docs/specs/[feature-name].md`
- **Plans location**: `docs/plans/[task-name].md` (for long-running tasks)
- **Use `/clear`** frequently between major tasks
- **Ask questions** rather than assume requirements

EOF
