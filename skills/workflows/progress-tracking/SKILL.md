---
name: progress-tracking
description: |
  JSON-based progress tracking for long-running and multi-session tasks.
  Based on Anthropic's "Effective harnesses for long-running agents" pattern.
  Use when:
  - Starting complex tasks that may span multiple sessions
  - Need to track feature implementation progress
  - Want resumable workflows across context windows
  - Managing large migrations or refactoring
  - User says "track progress", "resume work", "continue from where we left off"
  Trigger phrases: track progress, resume, continue, multi-session, persist state, progress file, feature list
allowed-tools: Read, Write, Glob, Grep, TodoWrite
model: sonnet
user-invocable: false
---

# Progress Tracking System

JSON-based progress tracking for autonomous, long-running tasks that may span multiple sessions or context windows.

Based on Anthropic's Effective Harnesses for Long-Running Agents pattern.

## Multi-Project Isolation

Based on Claude Code's official git worktree recommendations, this system isolates each workspace to prevent conflicts when running multiple projects or sessions concurrently.

### Workspace Structure

```
.claude/
└── workspaces/
    └── {workspace-id}/           # Format: {branch}_{path-hash}
        ├── claude-progress.json  # Progress log with resumption context
        ├── feature-list.json     # Feature/task tracking
        ├── session-state.json    # Current session state (optional)
        └── logs/
            ├── subagent_activity.log
            └── sessions/
                └── {session-id}.log
```

### Workspace ID Generation

The workspace ID is generated from:
- **Branch name**: Current git branch (e.g., `main`, `feature-auth`)
- **Path hash**: MD5 hash of working directory path (8 chars)

Example workspace IDs:
- `main_a1b2c3d4` - main branch in directory with hash a1b2c3d4
- `feature-auth_e5f6g7h8` - feature/auth branch in different worktree

### Why This Structure?

From Claude Code Issue #1985 (Session Isolation):
> "File path from one session appeared in the context of a completely separate session"

This structure ensures:
1. **Worktree isolation**: Different git worktrees get different workspaces
2. **Branch isolation**: Same directory, different branch = different workspace
3. **Session tracking**: Each session has its own log file
4. **Resume capability**: Easy identification by branch name

## Core Principle

**Context windows are limited.** Complex tasks cannot be completed in a single window. This system provides:

1. **claude-progress.json** - Structured progress log
2. **feature-list.json** - Feature/task tracking with status
3. **Resumption context** - Clear state for new sessions

## Why JSON over Markdown?

From Anthropic's research: "Models are less likely to inappropriately modify JSON files compared to Markdown files."

- JSON has strict schema - harder to accidentally corrupt
- Fields can be independently updated
- Machine-readable for automation
- Clear separation of data and presentation

## claude-progress.json Schema

```json
{
  "workspaceId": "main_a1b2c3d4",
  "project": "project-name",
  "started": "2025-01-16T10:00:00Z",
  "lastUpdated": "2025-01-16T14:30:00Z",
  "status": "in_progress",
  "currentTask": "Implementing user authentication",
  "sessions": [
    {
      "id": "20250116_100000_abc1",
      "started": "2025-01-16T10:00:00Z",
      "ended": "2025-01-16T12:00:00Z",
      "summary": "Set up project structure, created database schema",
      "filesModified": ["schema.prisma", "src/models/user.ts"],
      "nextSteps": ["Implement auth service", "Add JWT handling"]
    }
  ],
  "log": [
    {
      "timestamp": "2025-01-16T10:15:00Z",
      "action": "Created database schema",
      "details": "Added User, Session, and Token models",
      "files": ["prisma/schema.prisma"]
    }
  ],
  "resumptionContext": {
    "position": "Completed Phase 2 (Database), starting Phase 3 (Services)",
    "nextAction": "Create AuthService in src/services/auth.ts",
    "dependencies": ["Database migrations must be run first"],
    "blockers": []
  }
}
```

## feature-list.json Schema

```json
{
  "workspaceId": "main_a1b2c3d4",
  "project": "project-name",
  "totalFeatures": 10,
  "completed": 3,
  "features": [
    {
      "id": "F001",
      "name": "User registration",
      "description": "Users can create accounts with email/password",
      "status": "completed",
      "completedAt": "2025-01-16T11:30:00Z"
    },
    {
      "id": "F002",
      "name": "User login",
      "description": "Users can log in and receive JWT token",
      "status": "in_progress",
      "startedAt": "2025-01-16T12:00:00Z"
    },
    {
      "id": "F003",
      "name": "Password reset",
      "description": "Users can reset password via email",
      "status": "pending"
    }
  ]
}
```

## Workflow

### Starting a New Task

1. **Determine Workspace ID**
   ```bash
   # Generated automatically by hooks:
   # {branch}_{path-hash} e.g., main_a1b2c3d4
   ```

2. **Initialize Progress Files**
   ```
   Create .claude/workspaces/{workspace-id}/claude-progress.json with:
   - Workspace ID
   - Project name
   - Start timestamp
   - Initial status
   - First session entry
   ```

3. **Create Feature List** (if multiple features)
   ```
   Create .claude/workspaces/{workspace-id}/feature-list.json with:
   - All features to implement
   - All marked as "pending" initially
   ```

4. **Use TodoWrite in Parallel**
   ```
   TodoWrite for real-time visibility
   JSON files for persistence across sessions
   ```

### During Work

1. **Update Progress Log** after significant actions
   ```json
   {
     "timestamp": "...",
     "action": "Implemented AuthService",
     "details": "Added login, logout, and token refresh methods",
     "files": ["src/services/auth.ts"]
   }
   ```

2. **Update Feature Status** when completing features
   ```json
   {
     "status": "completed",
     "completedAt": "..."
   }
   ```

3. **Keep Resumption Context Current**
   ```json
   {
     "position": "Where we are now",
     "nextAction": "What to do next",
     "dependencies": ["What's needed"],
     "blockers": ["What's in the way"]
   }
   ```

### Ending a Session

1. **Update Session Summary**
   ```json
   {
     "ended": "...",
     "summary": "What was accomplished",
     "filesModified": [...],
     "nextSteps": [...]
   }
   ```

2. **Ensure Resumption Context is Complete**
   - Position must be clear
   - Next action must be specific
   - Any blockers documented

### Resuming Work

1. **List Available Workspaces**
   ```
   Check .claude/workspaces/ for available workspaces
   Display workspace IDs with project names and status
   ```

2. **Read Progress Files for Selected Workspace**
   ```
   Read .claude/workspaces/{workspace-id}/claude-progress.json
   Read .claude/workspaces/{workspace-id}/feature-list.json (if exists)
   ```

3. **Understand Current State**
   - Check resumptionContext.position
   - Review last session summary
   - Note any blockers

4. **Continue from Documented Point**
   - Start new session entry
   - Follow nextAction from resumption context

## Integration with TodoWrite

Use BOTH systems together:

| System | Purpose | Scope |
|--------|---------|-------|
| TodoWrite | Real-time visibility | Current session |
| JSON files | Persistence | Across sessions |

```
Flow:
1. Read feature-list.json to populate TodoWrite
2. Mark TodoWrite items as you work
3. Update JSON files at milestones
4. Sync TodoWrite from JSON on new session
```

## Session Start Protocol

When starting or resuming:

```
1. Get current workspace ID (branch + path hash)
2. Check if .claude/workspaces/{workspace-id}/claude-progress.json exists
3. If exists:
   - Read resumptionContext
   - Read last session summary
   - Report: "Resuming from: [position]"
   - Report: "Workspace: [workspace-id]"
   - Report: "Next action: [nextAction]"
4. If not exists:
   - Initialize new progress tracking
   - Create feature list if multiple features
```

## PreCompact Hook Integration

This plugin includes a `PreCompact` hook that automatically saves state before context compaction.

### Compaction Process Flow

1. Context approaches limit (~50-70% full)
2. **PreCompact hook** triggers → saves state to workspace progress file
3. System compacts context (summarizes, details may be lost)
4. Agent continues with reduced context → **must read progress files to restore state**

### Post-Compaction Recovery Protocol

**After compaction, ALWAYS:**

1. **Read progress file** to restore context:
   ```
   Read .claude/workspaces/{workspace-id}/claude-progress.json
   ```

2. **Check for compaction history**:
   ```json
   {
     "compactionHistory": [
       {
         "timestamp": "2025-01-16T14:30:00Z",
         "contextBeforeCompaction": "Phase 5 - Implementation"
       }
     ]
   }
   ```

3. **Resume from documented position**:
   - Check `resumptionContext.position`
   - Follow `resumptionContext.nextAction`
   - Be aware of any `blockers`

4. **Re-read key files if needed**:
   - Check `resumptionContext.keyFiles` for important references
   - Use `file:line` format to quickly locate relevant code

### Compaction-Safe State Format

Ensure your progress files contain enough context to recover:

```json
{
  "workspaceId": "main_a1b2c3d4",
  "resumptionContext": {
    "position": "Phase 5 - Implementation: AuthService login method",
    "nextAction": "Add token refresh logic to src/services/auth.ts:67",
    "keyFiles": [
      "src/services/auth.ts:45",
      "src/config/jwt.ts:12"
    ],
    "recentDecisions": [
      "Using JWT with 24h expiry",
      "Refresh tokens stored in Redis"
    ],
    "blockers": []
  },
  "compactionHistory": [
    {
      "timestamp": "2025-01-16T14:30:00Z",
      "positionAtCompaction": "Starting token refresh implementation"
    }
  ]
}
```

### Why This Matters

Without proper recovery after compaction:
- Agent loses track of what was done
- May repeat work or skip steps
- Decisions made before compaction are forgotten
- Quality degrades significantly

With proper recovery:
- Agent resumes exactly where it left off
- All decisions are preserved in JSON
- Key file references enable quick context loading
- Work continues smoothly across compaction boundaries

## Context Editing (Advanced)

Claude Code includes **Context Editing** - an automatic feature that removes stale tool calls and results when approaching token limits.

From Anthropic's Context Management announcement:

> "Context editing automatically clears stale tool calls and results from within the context window when approaching token limits... reducing token consumption by 84%."

### How Context Editing Works

Unlike compaction (which summarizes the conversation), context editing **surgically removes** completed tool interactions while preserving:
- Conversation flow
- Important decisions
- Current task state

```
Before Context Editing:
[Turn 1: Read file A → Result: 500 lines]
[Turn 2: Read file B → Result: 800 lines]
[Turn 3: Edit file A → Success]
[Turn 4: Current task discussion]

After Context Editing:
[Turn 1: Read file A → [removed - stale]]
[Turn 2: Read file B → [removed - stale]]
[Turn 3: Edit file A → [removed - completed]]
[Turn 4: Current task discussion]  ← preserved
```

### Progress Files + Context Editing = Long Sessions

Combining progress files with context editing enables extended autonomous work:

| Feature | Compaction | Context Editing |
|---------|-----------|-----------------|
| **Trigger** | Manual or ~70% full | Automatic near limits |
| **Method** | Summarizes conversation | Removes stale tool calls |
| **Preserves** | Summary only | Conversation + decisions |
| **Recovery** | Requires progress file | Often self-recovers |
| **Token savings** | ~60-70% | Up to 84% |

### Best Practice: Use Both

1. **Context Editing** handles routine cleanup automatically
2. **Progress Files** provide insurance for major context loss
3. **PreCompact Hook** saves state before any compaction

**Recommendation**: Even with context editing, maintain progress files for:
- Multi-session work
- Complex decisions that must survive any context loss
- Work that spans multiple days

## Best Practices

### DO

- Update progress after EVERY significant action
- Keep resumption context specific and actionable
- Use feature-list.json for tasks with multiple deliverables
- Commit progress files to git for persistence
- Include file paths in log entries
- Include workspaceId in all progress files

### DON'T

- Batch updates (risk losing progress on failure)
- Use vague resumption context ("continue working")
- Forget to update feature status on completion
- Leave blockers undocumented
- Mix progress from different workspaces

## Example: Database Migration

```json
{
  "workspaceId": "feature-prisma_b2c3d4e5",
  "project": "sequelize-to-prisma-migration",
  "status": "in_progress",
  "currentTask": "Migrating Order model",
  "features": [
    {"id": "M001", "name": "User model", "status": "completed"},
    {"id": "M002", "name": "Product model", "status": "completed"},
    {"id": "M003", "name": "Order model", "status": "in_progress"},
    {"id": "M004", "name": "OrderItem model", "status": "pending"},
    {"id": "M005", "name": "Repository layer", "status": "pending"}
  ],
  "resumptionContext": {
    "position": "Order model migration - relations defined, testing CRUD",
    "nextAction": "Write integration tests for Order repository",
    "dependencies": ["User and Product models must pass tests"],
    "blockers": []
  }
}
```

## Rules (L1 - Hard)

Critical for session continuity and data integrity.

- ALWAYS update resumption context before ending session (enables recovery)
- NEVER leave nextAction empty or vague (agent cannot resume)
- ALWAYS include workspaceId in progress files (isolation)
- NEVER write to progress files outside current workspace (prevents conflicts)
- ALWAYS read progress files immediately after compaction (restores decision context)
- NEVER continue work without verifying resumptionContext.position after compaction

## Defaults (L2 - Soft)

Important for effective progress tracking. Override with reasoning when appropriate.

- Create progress files for tasks > 3 steps
- Use JSON format (not Markdown) for state
- Include file paths in log entries
- Sync TodoWrite with feature-list on resume

## Guidelines (L3)

Recommendations for better progress management.

- Consider committing progress files to git for persistence
- Prefer frequent small updates over batched large updates
- Include recent decisions in resumption context for continuity
