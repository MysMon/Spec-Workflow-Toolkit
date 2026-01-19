---
description: "Resume work from progress files - restore context and continue from last checkpoint"
argument-hint: "[optional: project-name or 'list' to show all]"
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite
---

# /resume - Session Resumption Command

Resume long-running autonomous work from progress files, restoring context and continuing from the last checkpoint.

## Purpose

Based on Anthropic's Initializer + Coding Agent pattern from Effective Harnesses for Long-Running Agents.

**The Problem:** Context windows are limited. Complex tasks cannot be completed in a single session. When starting fresh, the agent has no memory of previous work.

**The Solution:** This command reads structured progress files to restore context and continue from exactly where work stopped.

## When to Use

- Starting a new session after `/sdd` was interrupted
- Continuing multi-day development work
- Recovering after context compaction
- Resuming after explicit `/clear`
- Checking status of in-progress work

## Progress File Locations

```
.claude/
├── claude-progress.json    # Resumption context, position, decisions
└── feature-list.json       # Task/feature status tracking
```

---

## Execution Instructions

### Phase 1: Progress Detection

**Goal:** Find and validate existing progress files.

**Check for progress files:**

```bash
ls -la .claude/claude-progress.json .claude/feature-list.json 2>/dev/null
```

**If argument is "list":**
- Search for all progress files across subdirectories
- Display summary of each project's status
- Exit after listing

**If argument is a project name:**
- Look for `.claude/claude-progress.json` with matching project name
- Or look in `[project-name]/.claude/claude-progress.json`

**If no progress files found:**
- Report: "No progress files found in this directory."
- Suggest: "Use `/sdd` to start a new tracked workflow."
- Exit

### Phase 2: State Analysis

**Goal:** Understand current state from progress files.

**Read and analyze progress file:**

```json
// Key fields to extract from claude-progress.json:
{
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

```bash
# Check for uncommitted changes
git status --porcelain

# Check recent commits
git log --oneline -5

# Check current branch
git branch --show-current
```

**If uncommitted changes exist:**
- Warn user about uncommitted work
- Ask if they want to continue or commit first

**If git state differs from progress file:**
- Report discrepancy
- Ask user how to proceed

### Phase 4: Context Restoration Display

**Goal:** Present clear resumption context to user.

**Display resumption summary:**

```markdown
## Resuming: [Project Name]

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
- Read and summarize key files
- Return to confirmation

**If "Start fresh":**
- Confirm: "This will archive current progress. Are you sure?"
- If confirmed: Move progress files to `.claude/archive/[timestamp]/`
- Exit with suggestion to run `/sdd`

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

**Read key files identified in resumption context:**

- Read up to 3 key files mentioned in `keyFiles`
- This provides necessary context for continuation

**Determine appropriate workflow:**

| Current Phase | Action |
|---------------|--------|
| Discovery | Resume requirements gathering |
| Exploration | Re-delegate to code-explorer |
| Design | Resume architecture discussion |
| Implementation | Delegate to specialist agent |
| Review | Re-run quality review |
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
  "id": [next session number],
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
  "project": "project-name",
  "started": "ISO timestamp",
  "lastUpdated": "ISO timestamp",
  "status": "in_progress | completed | blocked",
  "currentTask": "Current task description",
  "sessions": [
    {
      "id": 1,
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
      "positionAtCompaction": "Where we were"
    }
  ]
}
```

### feature-list.json

```json
{
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
# Resume work in current directory
/resume

# List all tracked projects
/resume list

# Resume specific project
/resume auth-feature

# Check status without continuing
/resume  # then choose "Just checking status"
```

## Integration with Other Commands

| After | Use /resume when |
|-------|------------------|
| `/sdd` | Work was interrupted mid-workflow |
| `/clear` | Cleared context but want to continue |
| Compaction | Context was automatically compacted |
| Session end | Starting new session next day |

## Tips for Best Results

1. **Keep progress files updated**: The better the resumption context, the smoother the resume
2. **Commit frequently**: Git history supplements progress files
3. **Document decisions**: Future sessions need to understand past choices
4. **Update nextAction**: Be specific about what comes next
5. **List key files**: Include file:line references for quick context loading

## Comparison with --continue Flag

| Aspect | `claude --continue` | `/resume` |
|--------|---------------------|-----------|
| Restores | Conversation history | Structured progress state |
| Scope | Last session in directory | Multi-session project state |
| Context | Full message history | Curated resumption context |
| Best for | Recent interruptions | Long-running projects |
