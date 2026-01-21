---
description: "Review and approve insights captured during development - process one by one interactively"
argument-hint: "[workspace-id | list]"
allowed-tools: Read, Write, Edit, AskUserQuestion, Bash, Glob
---

# /review-insights - Insight Review Workflow

Review insights captured during development and decide where to apply them. Each insight is processed interactively, one by one, with user confirmation.

## Design Principles

1. **User-driven**: Every decision requires explicit user approval
2. **One at a time**: Process insights individually to ensure thoughtful review
3. **Workspace isolation**: Each workspace has its own pending insights
4. **Graduated destinations**: From workspace-local to project-wide rules

---

## When to Use

- After completing a development session with captured insights
- When SessionStart notifies you of pending insights
- Periodically to review accumulated knowledge
- Before starting similar work to consolidate learnings

## Input Formats

```bash
# Review current workspace's insights
/review-insights

# Review specific workspace
/review-insights feature-auth_a1b2c3d4

# List all workspaces with pending insights
/review-insights list
```

---

## Execution Instructions

### Phase 1: Load Pending Insights

**Goal:** Identify workspace and load pending insights.

**If argument is "list":**

Use the Read tool to enumerate `.claude/workspaces/*/insights/pending.json` files and count pending insights in each. For each workspace directory found:

1. Read the `pending.json` file using the Read tool
2. Parse the JSON and count entries with `status: "pending"`
3. Display workspaces with count > 0

Display summary and exit.

**If argument is workspace-id:**

**IMPORTANT: Validate workspace ID before use:**
- Must match pattern `^[a-zA-Z0-9._-]+$`
- Must NOT contain `..` (path traversal)
- If validation fails, show error and exit

Use specified workspace after validation.

**If no argument:**

Determine current workspace ID using the same logic as `workspace_utils.sh`:
1. Get git branch: `git branch --show-current` (sanitize: replace `/` and space with `-`, keep only `a-zA-Z0-9._-`)
2. Get path hash: first 8 chars of MD5 hash of current directory
3. Combine: `{branch}_{hash}`

**Load pending insights:**

```bash
PENDING_FILE=".claude/workspaces/${WORKSPACE_ID}/insights/pending.json"
```

Read the file and filter for `status: "pending"`.

**If no pending insights:**

```
No pending insights in workspace: {workspace-id}

Run /review-insights list to see all workspaces with pending insights.
```

Exit.

### Phase 2: Interactive Review Loop

**Goal:** Process each insight one by one with user decisions.

**For each pending insight (process one at a time):**

**Display the insight:**

```markdown
---
## Insight Review ({current}/{total})

**ID**: {insight.id}
**Captured**: {insight.timestamp}
**Source**: {insight.source}

### Content
{insight.content}

---
```

**Ask for decision:**

```
Question: "What should we do with this insight?"
Header: "Action"
Options:
- "Approve: Add to CLAUDE.md (project-wide rule)"
- "Approve: Add to .claude/rules/ (category-specific)" (Recommended)
- "Approve: Keep in workspace only (this workspace)"
- "Skip for now (review later)"
- "Reject (not useful)"
```

**If "Approve: Add to CLAUDE.md":**

```
Question: "What rule level should this be?"
Header: "Level"
Options:
- "L1 (Hard Rule) - Security/safety critical, use NEVER/ALWAYS"
- "L2 (Soft Rule) - Best practice with exceptions, use should/by default" (Recommended)
- "L3 (Guideline) - Suggestion, use consider/prefer"
```

Then ask:

```
Question: "Which section of CLAUDE.md?"
Header: "Section"
Options:
- "Development Rules"
- "Content Guidelines"
- "Other (specify in follow-up)"
```

**If "Approve: Add to .claude/rules/":**

```
Question: "Which category?"
Header: "Category"
Options:
- "hooks - Hook development patterns"
- "agents - Agent design patterns"
- "skills - Skill development patterns"
- "workflows - Workflow improvements"
```

**If "Approve: Keep in workspace only":**

Move to `.claude/workspaces/{id}/insights/approved.json`

**If "Skip for now":**

Leave status as "pending", continue to next.

**If "Reject":**

Update status to "rejected" or move to archive.

### Phase 3: Apply Approved Insights

**Goal:** Write approved insights to their destinations.

**For CLAUDE.md additions:**

1. Read current CLAUDE.md
2. Find appropriate section
3. Format insight according to L1/L2/L3 style:
   - L1: `- **NEVER** do X` or `- **ALWAYS** do Y`
   - L2: `- X should Y` or `- By default, do Z`
   - L3: `- Consider X` or `- Prefer Y when Z`
4. Append to section
5. Update insight status to "applied"

**For .claude/rules/ additions:**

1. Check if `.claude/rules/{category}.md` exists
2. If not, create with header:
   ```markdown
   # {Category} Development Insights

   Insights captured during development for {category}.

   ---

   ```
3. Append formatted insight
4. Update insight status to "applied"

**For workspace-only:**

1. Create/update `.claude/workspaces/{id}/insights/approved.json`
2. Move insight from pending to approved
3. Update status to "workspace-approved"

**Update pending.json:**

Remove applied/rejected insights or update their status.

### Phase 4: Summary Report

**Goal:** Show what was done.

```markdown
## Insight Review Summary

### Workspace: {workspace-id}

| # | Insight | Decision | Destination |
|---|---------|----------|-------------|
| 1 | [first 50 chars...] | Approved | CLAUDE.md (L2) |
| 2 | [first 50 chars...] | Approved | .claude/rules/hooks.md |
| 3 | [first 50 chars...] | Workspace | approved.json |
| 4 | [first 50 chars...] | Skipped | - |
| 5 | [first 50 chars...] | Rejected | - |

### Statistics

- **Total reviewed**: 5
- **Added to CLAUDE.md**: 1
- **Added to .claude/rules/**: 1
- **Kept in workspace**: 1
- **Skipped**: 1
- **Rejected**: 1

### Files Modified

- `CLAUDE.md` - Added 1 rule
- `.claude/rules/hooks.md` - Added 1 insight

### Remaining

- **Pending in this workspace**: 1 (skipped)
- **Run `/review-insights` again to process skipped items**
```

---

## Insight Markers (For Reference)

Insights are captured when subagents output these markers:

| Marker | Use Case |
|--------|----------|
| `INSIGHT:` | General learning or discovery |
| `LEARNED:` | Something learned from experience |
| `DECISION:` | Important decision made |
| `PATTERN:` | Reusable pattern discovered |
| `ANTIPATTERN:` | Pattern to avoid |

Example:
```
INSIGHT: PreToolUse hooks with exit 1 are non-blocking - use JSON decision control + exit 0 for blocking
```

---

## Rules (L1 - Hard)

- ALWAYS process insights one by one with explicit user confirmation
- NEVER auto-approve or batch-approve without user decision per item
- NEVER modify CLAUDE.md without showing the change to user first
- ALWAYS preserve original insight content (user can edit destination text)

## Defaults (L2 - Soft)

- Default recommendation is ".claude/rules/" (prevents CLAUDE.md bloat)
- Default rule level is L2 (Soft Rule) for most insights
- Process insights in chronological order (oldest first)
- Show insight source (which agent/hook captured it)

## Guidelines (L3)

- Consider suggesting category based on insight content keywords
- Consider warning if CLAUDE.md is getting large (>500 lines)
- Consider grouping related insights if user prefers batch review
- Recommend L1 only for security/safety/data-integrity rules
