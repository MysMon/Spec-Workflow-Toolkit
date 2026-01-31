---
description: "Resume work from progress files - restore context and continue from last checkpoint"
argument-hint: "[optional: 'list' | workspace-id | project-name]"
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite
---

# /resume - Session Resumption Command

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

Resume long-running autonomous work from progress files, restoring context and continuing from the last checkpoint.

## Purpose

Based on Anthropic's Initializer + Coding Agent pattern from Effective Harnesses for Long-Running Agents.

**The Problem:** Context windows are limited. Complex tasks cannot be completed in a single session. When starting fresh, the agent has no memory of previous work.

**The Solution:** This command reads structured progress files to restore context and continue from exactly where work stopped.

## Multi-Project Workspace Isolation

Progress files are now isolated per workspace to support concurrent projects and git worktrees.

### Workspace Structure

```
.claude/workspaces/
├── main_a1b2c3d4/              # main branch workspace
│   ├── claude-progress.json
│   ├── feature-list.json
│   └── logs/
│       ├── subagent_activity.log
│       └── sessions/
└── feature-auth_e5f6g7h8/      # feature branch worktree
    ├── claude-progress.json
    └── logs/
```

### Workspace ID Format

`{branch}_{path-hash}` where:
- `branch`: Current git branch (e.g., `main`, `feature-auth`)
- `path-hash`: MD5 hash of working directory path (8 chars)

## When to Use

- Starting a new session after `/spec-plan`, `/spec-review`, or `/spec-implement` was interrupted
- Continuing multi-day development work
- Recovering after context compaction
- Resuming after explicit `/clear`
- Checking status of in-progress work
- Switching between workspaces/worktrees

---

## Execution Instructions

### Phase 1: Workspace Detection

**Goal:** Find and validate available workspaces and progress files.

**If argument is "list":**

```bash
# List all available workspaces
ls -la .claude/workspaces/ 2>/dev/null
```

For each workspace found, display:
- Workspace ID
- Project name (from progress file)
- Status (in_progress, completed, blocked)
- Last updated timestamp
- Current position

Example output:
```markdown
## Available Workspaces

| Workspace ID | Project | Status | Last Updated | Position |
|--------------|---------|--------|--------------|----------|
| main_a1b2c3d4 | auth-feature | in_progress | 2025-01-16 | impl-in-progress |
| feature-api_e5f6g7h8 | api-refactor | completed | 2025-01-15 | Done |
```

**If argument is a workspace ID:**
- Look for `.claude/workspaces/{workspace-id}/claude-progress.json`
- If not found, report error

**If argument is a project name:**
- Search all workspaces for matching project name
- If multiple matches, list and ask user to choose

**If no argument:**
1. Use the workspace ID shown in SessionStart hook output (format: `{branch}_{path-hash}`)
2. Check for workspace progress file at `.claude/workspaces/{workspace-id}/claude-progress.json`

**If no progress files found:**
- Report: "No progress files found for this workspace."
- List available workspaces if any exist
- Suggest: "Use `/spec-plan` to start planning."
- Exit

### Phase 2: State Analysis

**Goal:** Understand current state from progress files.

**Read and analyze progress file:**

```json
// Key fields to extract from claude-progress.json:
{
  "workspaceId": "main_a1b2c3d4",
  "project": "...",
  "status": "in_progress | completed | blocked",
  "currentTask": "...",
  "resumptionContext": {
    "position": "Where we stopped",
    "nextAction": "What to do next",
    "keyFiles": ["file:line references"],
    "decisions": ["Past decisions"],
    "blockers": []
  }
}
```

**Read feature list if exists:**

```json
// Key fields from feature-list.json:
{
  "workspaceId": "main_a1b2c3d4",
  "features": [
    {"id": "F001", "name": "...", "status": "completed"},
    {"id": "F002", "name": "...", "status": "in_progress"},
    {"id": "F003", "name": "...", "status": "pending"}
  ]
}
```

**Calculate progress:**
- Total features
- Completed features
- Current in-progress feature
- Remaining features

### Phase 3: Git State Check

**Goal:** Verify git state matches expectations.

**Why this is acceptable (not delegated):**
- Git metadata commands (`status`, `branch`, `log --oneline`) return minimal output
- This is state validation, not content analysis
- Quick execution is critical for resumption workflow
- Minimal context consumption (typically <50 lines)

```bash
# Check for uncommitted changes
git status --porcelain

# Check recent commits
git log --oneline -5

# Check current branch
git branch --show-current

# Check if in a worktree
git worktree list
```

**If uncommitted changes exist:**
- Warn user about uncommitted work
- Ask if they want to continue or commit first

**If git state differs from progress file:**
- Report discrepancy
- Ask user how to proceed

**If current branch doesn't match workspace:**
- Warn: "Current branch `X` doesn't match workspace `Y`"
- Ask if user wants to switch workspace or continue

### Phase 4: Context Restoration Display

**Goal:** Present clear resumption context to user.

**Display resumption summary:**

```markdown
## Resuming: [Project Name]

### Workspace
**ID**: `main_a1b2c3d4`
**Branch**: `main`
**Path**: `/path/to/project`

### Progress
[====>     ] 4/10 features (40%)

### Current Position
**Phase:** [Phase from progress file]
**Task:** [Current task]

### Last Session Summary
[Summary from last session entry]

### Key Decisions Made
- [Decision 1]
- [Decision 2]

### Key Files
- `src/services/auth.ts:45` - AuthService implementation
- `prisma/schema.prisma:12` - User model

### Blockers
[List any blockers, or "None"]

### Next Action
> [Specific next action from resumption context]
```

### Phase 5: User Confirmation

**Goal:** Get user approval before continuing.

**Ask user:**

```
Question: "How would you like to proceed?"
Header: "Resume"
Options:
- "Continue from checkpoint" (Recommended)
- "Show more details first"
- "Start fresh (reset progress)"
- "Just checking status (exit)"
```

**If "Continue from checkpoint":**
- Proceed to Phase 6

**If "Show more details":**
- Display full progress log
- Delegate key file summarization to code-explorer agent (do NOT read files directly):
  ```
  Launch code-explorer agent:
  Task: Summarize key files for detailed status review
  Inputs: List of file:line references from progress file
  Thoroughness: quick
  Output: Brief summary of each file's current state
  ```
- Display agent's summary
- Return to confirmation

**If "Start fresh":**
- Confirm: "This will archive current progress. Are you sure?"
- If confirmed: Move progress files to `.claude/workspaces/{id}/archived/{timestamp}/`
  - Archive path format: `.claude/workspaces/{id}/archived/{YYYY-MM-DD_HH-MM-SS}/`
  - Move all progress files (claude-progress.json, feature-list.json, etc.) to this directory
- Exit with suggestion to run `/spec-plan`

**If "Just checking status":**
- Exit cleanly

### Phase 6: Work Resumption

**Goal:** Resume work from checkpoint with appropriate agent.

**Initialize TodoWrite from feature list:**

```
Sync TodoWrite with feature-list.json:
- Mark completed features as completed
- Mark current feature as in_progress
- Add pending features as pending
```

**Context Restoration via Subagent:**

**CRITICAL: Do NOT read key files directly. Delegate to subagent.**

```
Launch code-explorer agent:
Task: Summarize key files for resumption context
Inputs: List of file:line references from `keyFiles`
Thoroughness: quick
Output: Concise summary of each file's role and current state
```

Use the agent's summary output for context restoration. Do NOT read key files directly.

**Error Handling for code-explorer:**
If code-explorer fails or times out:
1. Display available resumption context from progress file (position, nextAction, decisions)
2. Show key file list with file:line references (without summaries)
3. Warn user: "Key file context could not be loaded. Using progress file data only."
4. Ask user:
   ```
   Question: "Context restoration partially failed. How would you like to proceed?"
   Header: "Proceed"
   Options:
   - "Continue with limited context (progress file only)"
   - "Review key files manually first"
   - "Retry context restoration"
   ```

**Determine appropriate workflow:**

| Current Phase | Action |
|---------------|--------|
| `plan-discovery` / `plan-discovery-complete` | Resume requirements gathering via `/spec-plan` |
| `plan-exploration-complete` | Resume spec drafting via `/spec-plan` |
| `plan-spec-approved` | Resume architecture design via `/spec-plan` |
| `plan-complete` | Proceed to `/spec-review` |
| `review-complete` | Proceed to `/spec-implement` |
| `impl-starting` / `impl-in-progress` | Resume implementation via `/spec-implement` |
| `impl-review-complete` | Finalize implementation |
| Blocked | Address blocker first |

**Delegate to appropriate agent based on context:**

For implementation work:
```
Identify the current feature's domain:
- Frontend work → delegate to frontend-specialist
- Backend work → delegate to backend-specialist
- Testing work → delegate to qa-engineer
- Documentation → delegate to technical-writer
```

**Update progress file:**

```json
// Add new session entry
{
  "id": "[session-id]",
  "started": "[current timestamp]",
  "summary": "Resumed from checkpoint",
  "continuing": true
}
```

---

## Progress File Schemas

### claude-progress.json

```json
{
  "workspaceId": "main_a1b2c3d4",
  "project": "project-name",
  "started": "ISO timestamp",
  "lastUpdated": "ISO timestamp",
  "status": "in_progress | completed | blocked",
  "currentTask": "Current task description",
  "sessions": [
    {
      "id": "20250116_100000_abc1",
      "started": "ISO timestamp",
      "ended": "ISO timestamp",
      "summary": "What was accomplished",
      "filesModified": ["file1.ts", "file2.ts"],
      "nextSteps": ["Step 1", "Step 2"]
    }
  ],
  "log": [
    {
      "timestamp": "ISO timestamp",
      "action": "What was done",
      "status": "success | failed",
      "files": ["affected files"]
    }
  ],
  "resumptionContext": {
    "position": "Phase and step description",
    "nextAction": "Specific next action",
    "keyFiles": ["file:line", "file:line"],
    "decisions": ["Decision 1", "Decision 2"],
    "blockers": []
  },
  "compactionHistory": [
    {
      "timestamp": "ISO timestamp",
      "positionAtCompaction": "Where we were",
      "workspaceId": "main_a1b2c3d4"
    }
  ]
}
```

### feature-list.json

```json
{
  "workspaceId": "main_a1b2c3d4",
  "project": "project-name",
  "totalFeatures": 10,
  "completed": 3,
  "features": [
    {
      "id": "F001",
      "name": "Feature name",
      "description": "What this feature does",
      "status": "pending | in_progress | completed | blocked",
      "startedAt": "ISO timestamp (if started)",
      "completedAt": "ISO timestamp (if completed)",
      "files": ["files created/modified"]
    }
  ]
}
```

---

## Handling Special Cases

### After Context Compaction

When the PreCompact hook fires, it saves state automatically. After compaction:

1. This command detects compaction history
2. Reports: "Context was compacted at [timestamp]"
3. Reads full resumption context
4. Continues normally

### Blocked State

If status is "blocked":

1. Display blocker details prominently
2. Ask user to resolve blocker
3. Once resolved, update progress file
4. Continue work

### Completed State

If status is "completed":

1. Report: "This project was marked complete on [date]"
2. Display completion summary
3. Ask if user wants to:
   - Review what was done
   - Start new related work
   - Archive and close

---

## Usage Examples

```bash
# Resume work in current workspace
/resume

# List all tracked workspaces
/resume list

# Resume specific workspace
/resume main_a1b2c3d4

# Resume by project name (searches all workspaces)
/resume auth-feature

# Check status without continuing
/resume  # then choose "Just checking status"
```

## Integration with Other Commands

| After | Use /resume when |
|-------|------------------|
| `/spec-plan` | Planning was interrupted mid-workflow |
| `/spec-review` | Review was interrupted mid-workflow |
| `/spec-implement` | Implementation was interrupted mid-workflow |
| `/clear` | Cleared context but want to continue |
| Compaction | Context was automatically compacted |
| Session end | Starting new session next day |
| `git worktree add` | Switching to different worktree |

## Tips for Best Results

1. **Keep progress files updated**: The better the resumption context, the smoother the resume
2. **Commit frequently**: Git history supplements progress files
3. **Document decisions**: Future sessions need to understand past choices
4. **Update nextAction**: Be specific about what comes next
5. **List key files**: Include file:line references for quick context loading
6. **Use workspace IDs**: They uniquely identify branch + directory combinations

## Comparison with --continue Flag

| Aspect | `claude --continue` | `/resume` |
|--------|---------------------|-----------|
| Restores | Conversation history | Structured progress state |
| Scope | Last session in directory | Multi-session project state |
| Context | Full message history | Curated resumption context |
| Workspace aware | No | Yes |
| Best for | Recent interruptions | Long-running projects |

---

## Rules (L1 - Hard)

Critical for safe and accurate session resumption.

- ALWAYS validate git state before resuming (prevents silent data conflicts)
- MUST warn user if uncommitted changes exist
- MUST warn user if current branch doesn't match workspace
- NEVER proceed without user confirmation when git state differs from progress file
- MUST use AskUserQuestion when:
  - Uncommitted changes exist (ask: continue or commit first?)
  - Branch mismatch detected (ask: switch workspace or continue?)
  - Multiple workspaces match (ask: which one to resume?)
  - User requests "Start fresh" (confirm archival)
- NEVER silently discard progress — always archive before reset
- ALWAYS read progress files before any resumption work

## Defaults (L2 - Soft)

Important for quality resumption. Override with reasoning when appropriate.

- Sync TodoWrite with feature-list.json on resume
- Delegate key file reading to `code-explorer` agent for context summary
- Display progress bar with feature completion percentage
- Show last session summary for context

## Guidelines (L3)

Recommendations for effective session resumption.

- Consider showing compaction history if context was compacted
- Prefer displaying blockers prominently when status is "blocked"
- Consider offering workspace switching when multiple projects exist
