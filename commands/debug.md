---
description: "Systematic debugging workflow - analyze errors, trace root causes, and implement fixes with subagent delegation"
argument-hint: "<error-message or --test 'TestName' or --file 'path'>"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite
---

# /debug - Systematic Debugging Command

A structured debugging workflow that leverages subagent delegation to analyze errors, trace root causes, and implement verified fixes.

## Purpose

From Claude Code Best Practices: "Describe a bug or paste an error message. Claude Code will analyze your codebase, identify the problem, and implement a fix."

This command formalizes that process with:
- Parallel analysis using `code-explorer` agents
- Root cause isolation before fixing
- TDD-style verification (reproduce, fix, verify)
- Clear context preservation for complex bugs

## When to Use

- Runtime errors with stack traces
- Test failures
- Unexpected behavior
- Performance issues
- Build/compilation errors

## Input Formats

```bash
# Error message
/debug "TypeError: Cannot read property 'id' of undefined"

# Stack trace (paste directly)
/debug
[paste stack trace]

# Failing test
/debug --test "UserService.login should return token"

# Suspicious file
/debug --file src/services/auth.ts

# Behavior description
/debug "Login works but logout doesn't clear the session"
```

---

## Execution Instructions

### Phase 1: Error Classification

**Goal:** Understand the type and scope of the error.

**Parse input to identify:**

| Input Type | Indicators | Analysis Approach |
|------------|------------|-------------------|
| Stack trace | File paths, line numbers, function calls | Trace execution path |
| Error message | Error type, message text | Search for similar patterns |
| Test failure | Test name, assertion | Run test, analyze failure |
| Behavior | Description of expected vs actual | Explore related code |

**Classify error category:**

```
Categories:
1. Runtime Error - Code crashes during execution
2. Logic Error - Wrong result, no crash
3. Test Failure - Automated test fails
4. Build Error - Compilation/bundling fails
5. Integration Error - External service interaction fails
6. Performance - Slow or resource-intensive
```

**Output:** Error classification and initial hypothesis.

### Phase 2: Context Gathering

**Goal:** Gather relevant context using subagent delegation.

**DELEGATE to `code-explorer` agent:**

```
Launch code-explorer agent to analyze:

Error context: [error message/stack trace]
Classification: [error category]

Tasks:
1. Locate the error source (file:line from stack trace if available)
2. Trace the execution path leading to the error
3. Identify related functions and data flow
4. Find similar patterns in codebase that work correctly
5. Check recent changes (git log) to affected files

Thoroughness: medium
Output:
- Error location with file:line
- Execution path
- Related code patterns
- Potential causes ranked by likelihood
```

**For test failures, also run:**

```bash
# Run the failing test with verbose output
npm test -- --testNamePattern="[test name]" --verbose
# or
pytest -xvs -k "[test name]"
```

**Collect environmental context:**

```bash
# Check recent changes
git log --oneline -10

# Check if issue is in uncommitted changes
git diff

# Check dependencies
npm list --depth=0 2>/dev/null || pip list 2>/dev/null
```

### Phase 3: Root Cause Analysis

**Goal:** Isolate the root cause before attempting fixes.

**Analyze code-explorer findings:**

Based on the agent's output, identify:

1. **Immediate Cause**: What directly triggered the error
2. **Root Cause**: Why that situation occurred
3. **Contributing Factors**: Other conditions that enabled the bug

**Ask clarifying questions if needed:**

```
Question: "I found potential causes. Which scenario matches your situation?"
Header: "Root Cause"
Options:
- "[Cause A]: [Description]" (Most likely based on analysis)
- "[Cause B]: [Description]"
- "[Cause C]: [Description]"
- "None of these / Need more investigation"
```

**Document root cause:**

```markdown
## Root Cause Analysis

### Immediate Cause
[What directly caused the error]
File: `src/services/auth.ts:45`

### Root Cause
[Why the immediate cause happened]

### Evidence
- [Evidence 1]
- [Evidence 2]

### Related Code
- `src/services/auth.ts:45` - Error occurs here
- `src/controllers/login.ts:23` - Calls the failing function
- `src/models/user.ts:12` - Data structure involved
```

### Phase 4: Fix Planning

**Goal:** Design a fix strategy before implementation.

**Determine fix approach:**

| Root Cause Type | Fix Approach |
|-----------------|--------------|
| Null/undefined check missing | Add defensive check |
| Wrong logic/algorithm | Correct the logic |
| Missing error handling | Add try/catch and handling |
| Type mismatch | Fix type or conversion |
| Race condition | Add synchronization |
| Missing dependency | Add import/installation |
| Configuration error | Fix config values |

**Consider TDD approach:**

```
TDD Flow (Recommended for non-trivial bugs):

1. Write a test that reproduces the bug
2. Verify the test fails
3. Implement the fix
4. Verify the test passes
5. Run full test suite for regressions
```

**Ask user about approach:**

```
Question: "How should I proceed with the fix?"
Header: "Fix Approach"
Options:
- "TDD: Write reproducing test first" (Recommended)
- "Direct fix: Implement fix immediately"
- "Explore more: Need additional analysis"
- "Explain only: Don't modify code"
```

### Phase 5: Fix Implementation

**Goal:** Implement the fix with appropriate agent delegation.

**⚠️ ORCHESTRATOR RULE: Do not implement the fix yourself. Delegate.**

**For TDD approach:**

```
Step 1: DELEGATE to qa-engineer
Task: Write a test that reproduces this bug:
- Bug: [description]
- Root cause: [root cause]
- Expected: Test should FAIL with current code
- File: Create in appropriate test file

Step 2: Verify test fails
Run the new test, confirm it reproduces the bug

Step 3: DELEGATE to appropriate specialist
Task: Fix the bug to make this test pass:
- Test file: [test file path]
- Bug location: [file:line]
- Root cause: [root cause]
- Constraint: Minimal change, don't break other tests

Step 4: Verify fix
Run the new test, confirm it PASSES
Run full test suite, confirm no regressions
```

**For direct fix approach:**

```
DELEGATE to appropriate specialist:
- Frontend bug → frontend-specialist
- Backend bug → backend-specialist
- Build/config → devops-sre
- Test issue → qa-engineer

Task: Fix this bug:
- Location: [file:line]
- Root cause: [root cause]
- Expected behavior: [what should happen]
- Constraint: Minimal change to fix the issue
```

**After implementation:**

1. Run relevant tests
2. Verify the original error no longer occurs
3. Check for regressions

### Phase 6: Verification

**Goal:** Confirm the fix works and doesn't introduce new issues.

**Run verification steps:**

```bash
# Run specific test (if TDD)
npm test -- --testNamePattern="[test name]"

# Run related test suite
npm test -- [test file]

# Run full test suite
npm test

# Check for lint/type errors
npm run lint
npm run typecheck
```

**If tests fail after fix:**

1. Analyze the new failure
2. Determine if it's a regression or unrelated
3. If regression: iterate on fix
4. If unrelated: note for separate investigation

**If all tests pass:**

Proceed to summary.

### Phase 7: Summary

**Goal:** Document what was done and any follow-up needed.

**Display fix summary:**

```markdown
## Debug Summary

### Bug
[Original error/description]

### Root Cause
[What caused the bug]
File: `[file:line]`

### Fix Applied
[What was changed]

### Files Modified
| File | Changes |
|------|---------|
| `src/services/auth.ts` | Added null check at line 45 |

### Verification
- [x] Reproducing test created: `auth.test.ts:123`
- [x] Test passes after fix
- [x] Full test suite passes
- [x] No regressions detected

### Recommendations
[Any follow-up actions or related improvements]
```

**Ask about commit:**

```
Question: "The fix is verified. Would you like to commit?"
Header: "Commit"
Options:
- "Yes, commit the fix"
- "No, I'll review first"
- "Show me the diff first"
```

---

## Error-Specific Workflows

### Stack Trace Debugging

```
1. Parse stack trace for:
   - Error type and message
   - File paths and line numbers
   - Function call sequence

2. Start from the top (most recent call)
3. Read the code at each level
4. Identify where expectation diverged from reality
```

### Test Failure Debugging

```
1. Run test with verbose output
2. Identify:
   - Expected value
   - Actual value
   - Assertion that failed
3. Trace back from assertion to find divergence
4. Check test setup/teardown
5. Verify mocks are correct
```

### "It Works Locally" Debugging

```
1. Compare environments:
   - Node/Python version
   - Dependencies versions
   - Environment variables
   - Database state

2. Check for:
   - Hardcoded paths
   - Missing env vars
   - Platform-specific code
```

### Performance Debugging

```
1. Identify the slow operation
2. Add timing measurements
3. Profile if available:
   - Node: --inspect + Chrome DevTools
   - Python: cProfile
4. Look for:
   - N+1 queries
   - Unnecessary loops
   - Memory leaks
   - Blocking operations
```

---

## Integration with Progress Tracking

For complex bugs requiring multiple sessions:

**Create checkpoint:**

```json
// Add to .claude/workspaces/{workspace-id}/claude-progress.json
{
  "workspaceId": "{workspace-id}",
  "currentTask": "Debugging: [error description]",
  "resumptionContext": {
    "position": "Debug Phase 3 - Root cause identified",
    "nextAction": "Implement fix in src/services/auth.ts:45",
    "keyFiles": [
      "src/services/auth.ts:45",
      "src/controllers/login.ts:23"
    ],
    "decisions": [
      "Root cause: null user object not checked",
      "Fix approach: Add early return with error"
    ],
    "blockers": []
  }
}
```

Use `/resume` to continue debugging in next session.

---

## Usage Examples

```bash
# Debug a runtime error
/debug "TypeError: Cannot read property 'name' of undefined at UserService.getProfile"

# Debug a test failure
/debug --test "UserService.getProfile should return user data"

# Debug unexpected behavior
/debug "The login endpoint returns 200 but the session cookie isn't set"

# Debug a build error
/debug "Module not found: Can't resolve './components/Button'"

# Debug with a file focus
/debug --file src/services/user.service.ts
```

## Tips for Best Results

1. **Provide complete error messages**: Include the full stack trace if available
2. **Describe expected vs actual**: Be clear about what should happen
3. **Choose TDD approach**: Writing a reproducing test prevents regressions
4. **Be patient with analysis**: Root cause identification prevents wasted effort
5. **Check recent changes**: `git log` and `git diff` are invaluable

## Comparison with Ad-hoc Debugging

| Aspect | Ad-hoc | /debug |
|--------|--------|--------|
| Analysis | Manual | Structured via code-explorer |
| Fix verification | Optional | Required (TDD encouraged) |
| Documentation | None | Automatic summary |
| Regression check | Often skipped | Always run |
| Context for resume | Lost | Preserved in progress files |
