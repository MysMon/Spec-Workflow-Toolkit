---
name: long-running-tasks
description: |
  Patterns for autonomous, long-running tasks with state persistence and progress tracking.
  Use when:
  - Task has multiple steps that need tracking
  - Work may span context window limits
  - Need to persist state between sessions
  - Complex migrations, refactoring, or multi-file changes
  - User says "complete everything" or "run autonomously"
  Trigger phrases: long task, autonomous, persist state, track progress, migration, refactoring, multi-step
allowed-tools: Read, Write, Glob, Grep, Bash, TodoWrite
model: sonnet
user-invocable: true
---

# Long-Running Task Patterns

Techniques for managing complex, multi-step tasks that may exceed a single session or context window.

## Core Principles

Based on [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices):

1. **Use TodoWrite extensively** - Break down work, track progress visibly
2. **File-based state persistence** - Write plans and progress to `docs/plans/`
3. **Checkpoint frequently** - Claude Code auto-saves before changes
4. **Mark complete immediately** - Don't batch completions

## State Management Pattern

### 1. Initialize Task Plan

At task start, create a plan file:

```markdown
# docs/plans/[task-name].md

## Task: [Description]

**Started**: [timestamp]
**Status**: In Progress

## Steps

- [ ] Step 1: [Description]
- [ ] Step 2: [Description]
- [ ] Step 3: [Description]

## Progress Log

### [timestamp]
- Started task
- [Initial observations]

## Context for Resumption

If this task is resumed, note:
- Current position: [where we are]
- Next action: [what to do next]
- Dependencies: [what's needed]
```

### 2. Update Progress Continuously

After each significant action:

```markdown
## Progress Log

### [timestamp]
- Completed: [what was done]
- Files modified: [list]
- Next: [upcoming work]
```

### 3. Mark Completion

```markdown
**Status**: Completed
**Finished**: [timestamp]

## Summary
- [What was accomplished]
- [Files created/modified]
- [Any follow-up needed]
```

## TodoWrite Integration

**CRITICAL**: Use TodoWrite for real-time tracking alongside file-based state.

```
Flow:
1. Create todos from plan file
2. Mark todo in_progress BEFORE starting
3. Mark todo completed IMMEDIATELY after
4. Add new todos as discovered
5. Keep only ONE in_progress at a time
```

### Example TodoWrite Pattern

```
Initial todos:
1. [in_progress] Analyze current codebase structure
2. [pending] Create migration plan
3. [pending] Implement changes for module A
4. [pending] Implement changes for module B
5. [pending] Run tests and fix issues
6. [pending] Update documentation
```

## Checkpoints and Recovery

### Using Checkpoints

Claude Code automatically creates checkpoints before each edit:

- **Safe experimentation** - Try approaches without fear
- **Use `/rewind`** - Roll back to previous state if needed
- **Esc twice** - Cancel current operation and discuss

### Recovery from Context Limits

When approaching context limits:

1. Write current state to plan file
2. Document "Resumption Context" section
3. User can `/clear` and continue with state file

## Large Migration Pattern

For migrations affecting many files:

### Phase 1: Discovery

```bash
# Find all affected files
find . -name "*.tsx" -exec grep -l "OldPattern" {} \;

# Count scope
wc -l $(find . -name "*.tsx" -exec grep -l "OldPattern" {} \;)
```

Document findings in plan file.

### Phase 2: Batch Processing

Process files in manageable batches:

```
Batch 1: src/components/*.tsx (15 files)
Batch 2: src/pages/*.tsx (8 files)
Batch 3: src/utils/*.ts (4 files)
```

Track each batch as a separate todo.

### Phase 3: Verification

After each batch:
- Run tests
- Check for regressions
- Update progress

## Background Tasks

For non-blocking operations:

```bash
# Run dev server in background
npm run dev &

# Run tests while continuing work
npm test &

# Use Ctrl+B to background running tasks
```

## Multi-Session Work

When work spans multiple sessions:

### End of Session

1. Write comprehensive state to plan file
2. Commit WIP changes with descriptive message
3. Document exact resumption point

### Start of Next Session

1. Read plan file: `docs/plans/[task-name].md`
2. Review progress and current position
3. Load relevant context
4. Continue from documented point

## Example: Database Migration

```markdown
# docs/plans/migrate-to-prisma.md

## Task: Migrate from Sequelize to Prisma

**Started**: 2025-01-15
**Status**: In Progress

## Steps

- [x] Audit existing Sequelize models (12 models found)
- [x] Create Prisma schema
- [x] Generate Prisma client
- [ ] Migrate User model
- [ ] Migrate Product model
- [ ] Migrate Order model (complex relations)
- [ ] Update repository layer
- [ ] Run integration tests
- [ ] Remove Sequelize dependencies

## Progress Log

### 2025-01-15 10:00
- Analyzed existing models
- Created initial schema.prisma
- Generated client successfully

### 2025-01-15 11:30
- Migrated User and Product models
- Tests passing for both
- Next: Order model (has complex relations)

## Context for Resumption

If resumed:
- Read: prisma/schema.prisma for current state
- Read: src/repositories/order.repository.ts for next migration
- Run: npx prisma generate after any schema changes
```

## Anti-Patterns to Avoid

| Anti-Pattern | Why Bad | Instead |
|--------------|---------|---------|
| Batching completions | Loses progress on failure | Mark complete immediately |
| Multiple in_progress | Confusing, loses focus | One at a time |
| No state file | Can't resume | Always document state |
| No progress log | Can't track what happened | Log each action |
| Skipping tests | Regressions compound | Test after each batch |

## Rules

- ALWAYS create plan file for tasks > 3 steps
- ALWAYS update progress after each significant action
- ALWAYS mark todos complete immediately
- NEVER have more than one todo in_progress
- ALWAYS document resumption context
- ALWAYS test after batched changes
