---
name: parallel-execution
description: |
  Patterns for parallel subagent execution to maximize efficiency and reduce context usage.
  Use when:
  - Multiple independent analyses or reviews are needed
  - Tasks can run concurrently without dependencies
  - Code review requires multiple perspectives
  - Exploration of codebase from different angles
  Trigger phrases: parallel review, concurrent agents, multi-agent, independent analysis, run simultaneously
allowed-tools: Read, Glob, Grep, Task
model: sonnet
user-invocable: true
context: fork
agent: general-purpose
---

# Parallel Agent Execution

Techniques for running multiple subagents concurrently to maximize efficiency and minimize main context usage.

## Core Principles

From Claude Code Best Practices:

1. **Subagents preserve context** - Exploration happens in isolation
2. **Only results return** - Main context stays clean
3. **Independence enables parallelism** - No dependencies = run together
4. **Aggregation happens in main** - Combine results intelligently

## When to Use Parallel Execution

### Suitable Tasks

| Task Type | Agents | Why Parallel |
|-----------|--------|--------------|
| Code review | qa, security, style | Independent perspectives |
| Codebase exploration | Multiple Explore | Different search angles |
| Test coverage | unit, integration, e2e | Independent scopes |
| Documentation | API docs, user guide, changelog | Different audiences |
| Architecture analysis | frontend, backend, infra | Different domains |

### Not Suitable

- Tasks with dependencies (must be sequential)
- Tasks that modify same files (conflicts)
- Tasks requiring shared state
- Simple single-file operations

## Parallel Review Pattern

### Multi-Perspective Code Review

```
Launch these agents in parallel:

1. qa-engineer agent
   Task: Review test coverage for [files]
   Output: Test gap report with confidence scores

2. security-auditor agent
   Task: Security audit for [files]
   Output: Vulnerability findings (confidence >= 70)

3. code-quality skill
   Task: Lint and style check for [files]
   Output: Quality issues and fixes
```

### Execution

The orchestrator:
1. Launches all agents simultaneously
2. Each runs in isolated context
3. Results stream back as agents complete
4. Main context aggregates findings

### Result Aggregation

After parallel completion:

```markdown
## Combined Review Results

### Critical Issues (must fix)
- [From security-auditor] SQL injection in auth.ts:45 (confidence: 95)
- [From qa-engineer] Missing test for payment flow (confidence: 92)

### Important Issues (should fix)
- [From code-quality] Unused import in utils.ts
- [From qa-engineer] Edge case not covered in validation

### Suggestions (consider)
- [From code-quality] Could use early return pattern
```

## Parallel Exploration Pattern

### Codebase Discovery

When understanding unfamiliar codebase:

```
Launch exploration agents in parallel:

1. Explore agent
   Task: Find all API endpoints and their handlers

2. Explore agent
   Task: Trace authentication flow from login to session

3. Explore agent
   Task: Map database models and their relationships
```

### Combining Insights

Results create comprehensive picture without consuming main context on exploration:

```markdown
## Codebase Understanding

### API Layer (from Agent 1)
- 23 REST endpoints in /api/
- Uses Express with middleware pattern
- Auth middleware on /api/protected/*

### Authentication (from Agent 2)
- JWT-based auth
- Refresh token rotation
- Session stored in Redis

### Data Layer (from Agent 3)
- PostgreSQL with Prisma
- 15 models, User is central
- Soft deletes on most entities
```

## Sequential vs Parallel Decision

### Use Sequential When

```
Task A: Create database schema
    ↓
Task B: Generate Prisma client (depends on A)
    ↓
Task C: Write repository layer (depends on B)
```

### Use Parallel When

```
Task A: Review frontend code ──┐
Task B: Review backend code   ──┼── Aggregate results
Task C: Review infrastructure ──┘
```

## Confidence Score Aggregation

When multiple agents report on same issue:

| Agent Count | Confidence Adjustment |
|-------------|----------------------|
| 1 agent reports | Use agent's score |
| 2 agents agree | Boost score +10 |
| 3+ agents agree | Treat as confirmed |
| Agents disagree | Average scores, flag for review |

## Implementation Checklist

Before launching parallel agents:

- [ ] Tasks are truly independent
- [ ] No shared file modifications
- [ ] Each agent has clear scope
- [ ] Output format is consistent
- [ ] Aggregation criteria defined

## Background Agent Pattern

For long-running analyses:

```
Launch in background:
- Full security audit (may take time)
- Complete test suite run
- Dependency vulnerability scan

Continue with:
- Implementation work
- Documentation
- Other reviews

Check background results when ready.
```

## Anti-Patterns

| Anti-Pattern | Why Bad | Instead |
|--------------|---------|---------|
| Parallel with dependencies | Race conditions, wrong order | Sequence dependent tasks |
| Too many parallel agents | Overwhelming, hard to aggregate | Max 3-4 for reviews |
| Same files, parallel writes | Conflicts, lost changes | Coordinate file access |
| No aggregation plan | Scattered insights | Define merge strategy |

## Example: Full Feature Review

```markdown
## Launching Parallel Review for: User Dashboard Feature

### Agents to Launch

1. **code-explorer** (background)
   - Trace all data flows in dashboard components
   - Map component hierarchy

2. **qa-engineer** (parallel)
   - Review test coverage
   - Identify missing edge cases

3. **security-auditor** (parallel)
   - Check for XSS vulnerabilities
   - Verify auth on all endpoints

4. **architect** (parallel)
   - Evaluate component structure
   - Check for coupling issues

### Aggregation Strategy

- Critical issues from ANY agent → Must address
- Performance concerns → Prioritize by impact
- Style issues → Bundle into single cleanup PR
- Architecture suggestions → Discuss with team
```

## Rules (L1 - Hard)

Critical for conflict-free parallel execution.

- ALWAYS verify tasks are independent before parallelizing (prevent race conditions)
- NEVER run parallel agents that modify same files (causes conflicts)
- NEVER skip result aggregation (scattered insights are useless)

## Defaults (L2 - Soft)

Important for effective parallelism. Override with reasoning when appropriate.

- Define aggregation strategy before launching
- Include confidence scores in agent outputs
- Limit to 3-4 parallel agents for manageability
- Use consistent output format across agents

## Guidelines (L3)

Recommendations for optimal parallel execution.

- Consider using background agents for long-running analyses
- Prefer boosting confidence scores when multiple agents agree
- Consider flagging conflicting findings for human review
