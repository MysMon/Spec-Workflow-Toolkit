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

## Initializer + Coding Agent Pattern

Anthropic's recommended pattern uses **two distinct roles**:

### 1. Initializer Role (First Session Only)

On first run:
- **Create** workspace progress files in `.claude/workspaces/{workspace-id}/`
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

From Claude Code Best Practices:

1. **Use TodoWrite extensively** - Break down work, track progress visibly
2. **JSON-based state persistence** - Use `.claude/workspaces/{workspace-id}/claude-progress.json` and `.claude/workspaces/{workspace-id}/feature-list.json`
3. **Checkpoint frequently** - Claude Code auto-saves before changes
4. **Mark complete immediately** - Don't batch completions

> **Why JSON over Markdown?** "Models are less likely to improperly modify JSON files compared to Markdown files." - Anthropic

## State Management

For detailed progress tracking implementation, see the `progress-tracking` skill which covers:
- JSON file schemas (`claude-progress.json`, `feature-list.json`)
- Workspace isolation (`{branch}_{path-hash}` format)
- PreCompact hook integration and compaction recovery
- Session tracking and resumption context

**Quick Reference:**
```
.claude/workspaces/{workspace-id}/
├── claude-progress.json  # Progress log, resumption context
└── feature-list.json     # Feature/task status tracking
```

## TodoWrite Integration

Use TodoWrite alongside JSON files:

| System | Purpose | Scope |
|--------|---------|-------|
| TodoWrite | Real-time visibility | Current session |
| JSON files | Persistence | Across sessions |

**Flow:**
1. Mark todo `in_progress` BEFORE starting work
2. Mark `completed` IMMEDIATELY after finishing
3. Keep only ONE `in_progress` at a time
4. Sync from JSON files on session resume

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

## Subagent Resume Pattern

Patterns for efficiently utilizing subagents in long-running tasks.

### Why Resume Matters

From Claude Code Subagents Documentation:

> "Resumed subagents retain their full conversation history, including all previous tool calls, results, and reasoning."

Benefits of resuming subagents:
- No need to rebuild context from scratch
- Continue exactly where the agent stopped
- Prevent loss of exploration results
- Recover from permission errors or interruptions

### Basic Resume Pattern

```
Initial invocation:
"Use code-explorer to analyze module A"
[Agent completes, returns agent ID: agent-abc123]

Continuation (resume same agent):
"Resume agent-abc123 and also analyze module B"
[Resumes with full context from previous conversation]
```

### Orchestrator Resume Protocol

When orchestrating long tasks, track agent IDs for potential resume:

```json
{
  "activeAgents": {
    "exploration": "agent-abc123",
    "implementation": "agent-def456"
  },
  "completedAgents": [
    {"id": "agent-xyz789", "task": "architecture review", "summary": "..."}
  ]
}
```

**Resume Decision Tree:**

```
Agent completed successfully?
├─ Yes: Store summary, clear agent ID
└─ No (interrupted/failed):
    ├─ Permission error → Resume in foreground
    ├─ Context exhaustion → Start new agent with summary
    └─ Network error → Resume after brief wait
```

### Background Subagent Recovery

When a background subagent fails due to missing permissions:

1. The agent skips the failed tool call and continues
2. After completion, can be resumed in foreground to retry
3. Interactive permission prompts are available when resumed

**Recovery Example:**

```
# Background agent hit permission error
Agent agent-abc123 completed with partial results.
Skipped operations: Write to /etc/config (permission denied)

# Resume in foreground to complete
Resume agent-abc123 in foreground to retry failed operations.
[Interactive permission prompt appears]
```

### Background Subagent Limitations

| Feature | Foreground | Background |
|---------|------------|------------|
| MCP tools | ✅ Available | ❌ Not available |
| Permission prompts | ✅ Interactive | ❌ Auto-denied |
| AskUserQuestion | ✅ Available | ❌ Fails |
| Resume | - | ✅ Can resume in foreground |

### When to Use Resume

| Scenario | Recommended Action |
|----------|-------------------|
| Expanding exploration | Resume same code-explorer |
| Additional review checks | Resume same security-auditor |
| Recovering from permission errors | Resume in foreground |
| Agent hit context limit | Start new agent with summary |
| Need completely fresh perspective | Launch new agent |

### Context Preservation on Resume

When resuming, the agent retains:
- Full conversation history
- All previous tool calls and results
- Reasoning and decisions made
- Files read and analysis performed

This makes resume ideal for:
- Iterative exploration (analyze A, then B, then C)
- Multi-phase reviews (security, then performance, then accessibility)
- Error recovery without losing work

### Transcript Location

Subagent transcripts are stored at:
```
~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl
```

Automatic cleanup after 30 days by default (configurable via `cleanupPeriodDays` setting).

## Multi-Session Work

**End of Session:**
1. Update progress files with current position
2. Commit WIP changes with descriptive message
3. Ensure `resumptionContext.nextAction` is specific

**Start of Next Session:**
1. Read workspace progress files
2. Find first `pending` or `in_progress` feature
3. Continue from documented position

For detailed session protocols and examples, see the `progress-tracking` skill.

## Anti-Patterns to Avoid

| Anti-Pattern | Why Bad | Instead |
|--------------|---------|---------|
| Batching completions | Loses progress on failure | Mark complete immediately |
| Multiple in_progress | Confusing, loses focus | One at a time |
| No state file | Can't resume | Always document state |
| No progress log | Can't track what happened | Log each action |
| Skipping tests | Regressions compound | Test after each batch |

## Rules (L1 - Hard)

Critical for session continuity and data integrity.

- ALWAYS include workspaceId in progress files (prevents workspace conflicts)
- NEVER write to progress files outside current workspace
- ALWAYS read workspace progress files first after compaction or new session
- NEVER have more than one todo in_progress (focus and clarity)

## Defaults (L2 - Soft)

Important for effective long-running tasks. Override with reasoning when appropriate.

- Create workspace progress files for tasks > 3 steps
- Use workspace-isolated paths: `.claude/workspaces/{workspace-id}/`
- Update progress files after each significant action
- Mark todos complete immediately (not batched)
- Document resumption context in JSON (position, nextAction, keyFiles)
- Test after batched changes
- Use JSON for state persistence (not plain text)

## Guidelines (L3)

Recommendations for managing complex tasks.

- Consider using the Initializer + Coding pattern for multi-session work
- Prefer ONE feature at a time approach
- Consider background subagents for non-blocking operations
