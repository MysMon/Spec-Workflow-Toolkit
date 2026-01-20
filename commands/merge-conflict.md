---
description: "Resolve git merge conflicts systematically - analyze both versions, choose strategy, and verify resolution"
argument-hint: "[file path or --all]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite
---

# /merge-conflict - Systematic Merge Conflict Resolution

A structured workflow to analyze, resolve, and verify git merge conflicts using subagent delegation.

## Design Principles

1. **Understand before resolving**: Analyze both versions before making decisions
2. **Preserve intent**: Maintain the purpose of changes from both branches
3. **Verify resolution**: Always test after resolving conflicts
4. **Document decisions**: Record why specific resolutions were chosen

---

## When to Use

- Git merge resulted in conflicts
- Git rebase encountered conflicts
- Cherry-pick failed due to conflicts
- Need systematic approach to complex conflicts

## Input Formats

```bash
# Resolve conflicts in specific file
/merge-conflict src/components/Auth.tsx

# Resolve all current conflicts
/merge-conflict --all

# Interactive mode (list and choose)
/merge-conflict
```

---

## Execution Instructions

### Phase 1: Conflict Detection

**Goal:** Identify all files with conflicts and their scope.

**Detect conflicts:**

```bash
# List conflicted files
git diff --name-only --diff-filter=U

# Get conflict summary
git status --porcelain | grep "^UU\|^AA\|^DD"
```

**If no conflicts detected:**
- Inform user no conflicts exist
- Suggest checking `git status` for current state

**Create TodoWrite list** with each conflicted file.

### Phase 2: Conflict Analysis

**Goal:** Understand the changes from both sides for each conflict.

**For each conflicted file, launch parallel agents:**

```
Launch code-explorer agents in parallel:

Agent 1 (Ours): Analyze the "ours" (current branch) version
- What changes were made?
- What is the intent of these changes?
- What dependencies exist?

Agent 2 (Theirs): Analyze the "theirs" (incoming branch) version
- What changes were made?
- What is the intent of these changes?
- What dependencies exist?

Thoroughness: medium
```

**Extract conflict markers:**

```bash
# Show conflict sections
grep -n "^<<<<<<< \|^=======$\|^>>>>>>> " <file>
```

**Categorize conflict type:**

| Type | Pattern | Resolution Approach |
|------|---------|---------------------|
| **Additive** | Both sides add different code | Usually keep both |
| **Modificative** | Both modify same lines | Need semantic merge |
| **Deletive** | One deletes, one modifies | Decide which intent prevails |
| **Structural** | Refactoring conflicts | May need manual rewrite |

### Phase 3: Resolution Strategy

**Goal:** Choose the best resolution approach for each conflict.

**Present analysis to user:**

```markdown
## Conflict: [filename]

### Ours (current branch)
[Summary of changes and intent]

### Theirs (incoming branch)
[Summary of changes and intent]

### Conflict Type: [type]

### Recommended Resolution: [recommendation]
```

**Ask user for resolution strategy:**

```
Question: "How should I resolve this conflict?"
Header: "Strategy"
Options:
- "Keep ours (current branch)"
- "Keep theirs (incoming branch)"
- "Combine both changes" (Recommended for additive conflicts)
- "Let me specify manually"
```

### Phase 4: Resolution Implementation

**Goal:** Apply the chosen resolution strategy.

**For "Keep ours":**
```bash
git checkout --ours <file>
git add <file>
```

**For "Keep theirs":**
```bash
git checkout --theirs <file>
git add <file>
```

**For "Combine both":**

```
DELEGATE to code-architect:

Merge these two versions preserving both intents:

Ours version:
[code from ours]

Theirs version:
[code from theirs]

Requirements:
- Preserve functionality from both changes
- Resolve any logical conflicts
- Maintain code style consistency
- Remove conflict markers
```

**After resolution:**
- Remove conflict markers
- Stage the resolved file: `git add <file>`
- Mark TodoWrite item as completed

### Phase 5: Verification

**Goal:** Ensure resolution doesn't break functionality.

**Run verification checks:**

```bash
# Check no conflict markers remain
grep -r "^<<<<<<< \|^=======$\|^>>>>>>> " <resolved-files>

# Discover and run linter
npm run lint  # or equivalent

# Discover and run type check
npm run typecheck  # or tsc

# Discover and run tests
npm test  # or equivalent
```

**If verification fails:**
- Report which check failed
- Ask user how to proceed
- Consider reverting to re-resolve

### Phase 6: Completion

**Goal:** Finalize the merge and document resolution.

**Check merge status:**

```bash
git status
```

**If all conflicts resolved:**

```
Question: "All conflicts resolved and verified. How should I proceed?"
Header: "Complete"
Options:
- "Continue merge/rebase" (Recommended)
- "Show me the final diff first"
- "I'll complete manually"
```

**Complete merge:**

```bash
# For merge
git merge --continue

# For rebase
git rebase --continue

# For cherry-pick
git cherry-pick --continue
```

### Phase 7: Summary Report

**Goal:** Document what was resolved and how.

```markdown
## Merge Conflict Resolution Summary

### Operation: [merge/rebase/cherry-pick]
### Branch: [current] <- [incoming]

### Resolved Files

| File | Conflict Type | Resolution | Verified |
|------|---------------|------------|----------|
| `path/file1.ts` | Additive | Combined both | Tests pass |
| `path/file2.ts` | Modificative | Kept theirs | Lint pass |

### Resolution Decisions

#### file1.ts
- **Conflict**: Both branches added imports
- **Resolution**: Kept both import sets, removed duplicates
- **Reasoning**: Both imports are needed for respective features

#### file2.ts
- **Conflict**: Different validation logic
- **Resolution**: Used theirs (more comprehensive)
- **Reasoning**: Theirs includes additional edge cases

### Verification Results

- [ ] No conflict markers remain
- [ ] Lint passes
- [ ] Type check passes
- [ ] Tests pass

### Next Steps

1. Review the merged changes
2. Run full test suite
3. Push when ready
```

---

## Conflict Resolution Patterns

### Pattern 1: Import Conflicts

```
<<<<<<< HEAD
import { AuthService } from './auth';
import { UserService } from './user';
=======
import { AuthService } from './auth';
import { LogService } from './log';
>>>>>>> feature-branch
```

**Resolution**: Combine imports, remove duplicates:
```typescript
import { AuthService } from './auth';
import { UserService } from './user';
import { LogService } from './log';
```

### Pattern 2: Function Modification Conflicts

Both branches modified the same function differently. Resolution requires understanding both intents and creating a unified implementation.

### Pattern 3: Deletion vs Modification

One branch deleted code another modified. Ask user which intent should prevail.

---

## Rules (L1 - Hard)

- ALWAYS verify no conflict markers remain after resolution
- NEVER auto-resolve without understanding both sides
- ALWAYS run verification before completing merge
- NEVER force push after resolving conflicts on shared branches

## Defaults (L2 - Soft)

- Use parallel agent analysis for understanding both versions
- Stage files immediately after resolving each conflict
- Run lint and type check as minimum verification
- Document resolution decisions for complex conflicts

## Guidelines (L3)

- Consider resolving simpler conflicts first to build context
- Prefer combining changes over choosing one side when possible
- Consider asking original authors for complex semantic conflicts
- Run full test suite for critical code paths
