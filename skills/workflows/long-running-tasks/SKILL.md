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

## Official References

- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)

Techniques for managing complex, multi-step tasks that may exceed a single session or context window.

## Official Pattern: Initializer + Coding Agent

Based on [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), Anthropic's recommended pattern uses **two distinct roles**:

### 1. Initializer Role (First Session Only)

On first run:
- **Create** `.claude/claude-progress.json` and `.claude/feature-list.json`
- **Analyze** the full task scope and break into features
- **Initialize** git repository state
- **Document** resumption context for future sessions

### 2. Coding Role (Each Session)

On each session:
1. **Read** progress files and git log
2. **Identify** next incomplete feature
3. **Implement** one feature at a time (not all at once!)
4. **Test** the feature manually or automatically
5. **Update** progress files with results
6. **Commit** working code with descriptive message

### Key Insight: "One Feature at a Time"

From Anthropic's research: The agent tends to try to do too much at once—essentially attempting to one-shot the app.

**Solution**: Focus on ONE feature per session, test it thoroughly, then update progress.

---

## Core Principles

Based on [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices):

1. **Use TodoWrite extensively** - Break down work, track progress visibly
2. **JSON-based state persistence** - Use `.claude/claude-progress.json` and `.claude/feature-list.json`
3. **Checkpoint frequently** - Claude Code auto-saves before changes
4. **Mark complete immediately** - Don't batch completions

> **Why JSON over Markdown?** "Models are less likely to improperly modify JSON files compared to Markdown files." - Anthropic

## State Management Pattern

### 1. Initialize Progress Files

At task start, create the progress structure:

**`.claude/claude-progress.json`** - Resumption context:

```json
{
  "project": "task-name",
  "status": "in_progress",
  "startedAt": "2025-01-15T10:00:00Z",
  "currentTask": "Setting up project structure",
  "resumptionContext": {
    "position": "Phase 1 - Initialization",
    "nextAction": "Create feature list",
    "keyFiles": [],
    "decisions": [],
    "blockers": []
  },
  "log": [
    {
      "timestamp": "2025-01-15T10:00:00Z",
      "action": "Started task",
      "status": "success"
    }
  ]
}
```

**`.claude/feature-list.json`** - Task breakdown:

```json
{
  "features": [
    {"id": "F001", "name": "Step 1: Description", "status": "pending"},
    {"id": "F002", "name": "Step 2: Description", "status": "pending"},
    {"id": "F003", "name": "Step 3: Description", "status": "pending"}
  ]
}
```

### 2. Update Progress Continuously

After each significant action, update both files:

```json
// Add to log array in claude-progress.json
{
  "timestamp": "2025-01-15T11:30:00Z",
  "action": "Completed Step 1",
  "status": "success",
  "filesModified": ["src/config.ts", "src/index.ts"]
}
```

```json
// Update feature status in feature-list.json
{"id": "F001", "name": "Step 1: Description", "status": "completed"}
```

### 3. Mark Completion

```json
// Final state in claude-progress.json
{
  "project": "task-name",
  "status": "completed",
  "startedAt": "2025-01-15T10:00:00Z",
  "completedAt": "2025-01-15T14:00:00Z",
  "summary": {
    "accomplished": ["Created X", "Modified Y"],
    "filesChanged": ["src/config.ts", "src/index.ts"],
    "followUp": ["Deploy to staging", "Run integration tests"]
  }
}
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

### PreCompact Hook Integration

This plugin includes a `PreCompact` hook that automatically:
- Saves compaction timestamp to progress file
- Maintains compaction history (last 10 events)
- Outputs context reminder for post-compaction recovery

**After compaction**, always:
1. Read `.claude/claude-progress.json` to restore context
2. Check `feature-list.json` for current task status
3. Continue from the documented position

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

1. Update `.claude/claude-progress.json` with current position
2. Update `.claude/feature-list.json` with feature status
3. Commit WIP changes with descriptive message
4. Ensure resumptionContext has clear next action

### Start of Next Session

1. Read `.claude/claude-progress.json` for resumption context
2. Check `.claude/feature-list.json` for current feature status
3. Identify first `pending` or `in_progress` feature
4. Continue from documented position

## Example: Database Migration

**`.claude/claude-progress.json`**:

```json
{
  "project": "migrate-to-prisma",
  "status": "in_progress",
  "startedAt": "2025-01-15T10:00:00Z",
  "currentTask": "Migrate Order model",
  "resumptionContext": {
    "position": "Phase 2 - Model Migration",
    "nextAction": "Migrate Order model (complex relations)",
    "keyFiles": [
      "prisma/schema.prisma:45",
      "src/repositories/order.repository.ts:12"
    ],
    "decisions": [
      "Using Prisma's implicit m-n relations",
      "Keeping soft deletes pattern"
    ],
    "blockers": []
  },
  "log": [
    {
      "timestamp": "2025-01-15T10:00:00Z",
      "action": "Analyzed existing Sequelize models (12 found)",
      "status": "success"
    },
    {
      "timestamp": "2025-01-15T10:30:00Z",
      "action": "Created initial schema.prisma",
      "status": "success"
    },
    {
      "timestamp": "2025-01-15T11:00:00Z",
      "action": "Generated Prisma client",
      "status": "success"
    },
    {
      "timestamp": "2025-01-15T11:30:00Z",
      "action": "Migrated User and Product models",
      "status": "success",
      "filesModified": ["prisma/schema.prisma", "src/repositories/user.ts"]
    }
  ]
}
```

**`.claude/feature-list.json`**:

```json
{
  "features": [
    {"id": "F001", "name": "Audit existing Sequelize models", "status": "completed"},
    {"id": "F002", "name": "Create Prisma schema", "status": "completed"},
    {"id": "F003", "name": "Generate Prisma client", "status": "completed"},
    {"id": "F004", "name": "Migrate User model", "status": "completed"},
    {"id": "F005", "name": "Migrate Product model", "status": "completed"},
    {"id": "F006", "name": "Migrate Order model (complex relations)", "status": "in_progress"},
    {"id": "F007", "name": "Update repository layer", "status": "pending"},
    {"id": "F008", "name": "Run integration tests", "status": "pending"},
    {"id": "F009", "name": "Remove Sequelize dependencies", "status": "pending"}
  ]
}
```

**Resumption note**: After compaction or new session, read these files first to understand current state.

## Anti-Patterns to Avoid

| Anti-Pattern | Why Bad | Instead |
|--------------|---------|---------|
| Batching completions | Loses progress on failure | Mark complete immediately |
| Multiple in_progress | Confusing, loses focus | One at a time |
| No state file | Can't resume | Always document state |
| No progress log | Can't track what happened | Log each action |
| Skipping tests | Regressions compound | Test after each batch |

## Rules

- ALWAYS create `.claude/claude-progress.json` and `.claude/feature-list.json` for tasks > 3 steps
- ALWAYS update progress files after each significant action
- ALWAYS mark todos complete immediately
- NEVER have more than one todo in_progress
- ALWAYS document resumption context in JSON (position, nextAction, keyFiles)
- ALWAYS test after batched changes
- ALWAYS read progress files first after compaction or new session
- NEVER use plain text files for state - use JSON for reliability
