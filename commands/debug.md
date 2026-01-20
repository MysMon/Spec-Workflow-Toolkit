---
description: "Systematic debugging workflow - analyze errors, trace root causes, and implement fixes with subagent delegation"
argument-hint: "<error-message or --test 'TestName' or --file 'path'>"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite
---

# /debug - Systematic Debugging Command

A structured debugging workflow that leverages subagent delegation to analyze errors, trace root causes, and implement verified fixes.

## Design Principles

1. **Stack-agnostic**: Works for any language/framework
2. **Discover before assuming**: Detect project's test/build commands
3. **Root cause first**: Identify cause before implementing fix
4. **Verify fixes**: Always test that the fix works

---

## When to Use

- Runtime errors with stack traces
- Test failures
- Unexpected behavior
- Performance issues
- Build/compilation errors

## Input Formats

```bash
# Error message
/debug "Error: Something went wrong"

# Stack trace (paste directly)
/debug
[paste stack trace]

# Failing test
/debug --test "TestName"

# Suspicious file
/debug --file path/to/file

# Behavior description
/debug "Expected X but got Y"
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

**For test failures:**

First, discover the project's test command:

```bash
# Check for test scripts
grep -E '"test"' package.json 2>/dev/null
grep -E '^test:' Makefile 2>/dev/null
ls pytest.ini setup.cfg pyproject.toml 2>/dev/null
```

Then run with verbose output using the discovered command.

**Collect environmental context:**

```bash
# Check recent changes
git log --oneline -10

# Check if issue is in uncommitted changes
git diff --stat

# Check for dependency issues (discover package manager first)
ls package-lock.json yarn.lock pnpm-lock.yaml requirements.txt Pipfile.lock go.sum 2>/dev/null
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
File: `[file:line]`

### Root Cause
[Why the immediate cause happened]

### Evidence
- [Evidence 1]
- [Evidence 2]
```

### Phase 4: Fix Planning

**Goal:** Design a fix strategy before implementation.

**Determine fix approach based on cause, not technology:**

| Root Cause Type | Fix Approach |
|-----------------|--------------|
| Missing validation | Add defensive check |
| Wrong logic/algorithm | Correct the logic |
| Missing error handling | Add error handling |
| Type/data mismatch | Fix type or conversion |
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

**DELEGATE to appropriate specialist based on code location, not assumed technology:**

```
DELEGATE to code-explorer first to determine:
- What type of code is this? (frontend/backend/test/config)
- What patterns does this codebase use?

Then DELEGATE to appropriate specialist:
- Frontend code → frontend-specialist
- Backend code → backend-specialist
- Infrastructure → devops-sre
- Test code → qa-engineer
```

**For TDD approach:**

```
Step 1: DELEGATE to qa-engineer
Task: Write a test that reproduces this bug

Step 2: Verify test fails
Run the new test using project's test command

Step 3: DELEGATE to appropriate specialist
Task: Fix the bug to make this test pass

Step 4: Verify fix
Run the new test, confirm it PASSES
Run full test suite, confirm no regressions
```

### Phase 6: Verification

**Goal:** Confirm the fix works.

**Discover and run verification commands:**

```bash
# Discover test command
grep -E '"test"' package.json 2>/dev/null && echo "npm test"
grep -E '^test:' Makefile 2>/dev/null && echo "make test"
ls pytest.ini 2>/dev/null && echo "pytest"

# Discover build command
grep -E '"build"' package.json 2>/dev/null && echo "npm run build"
grep -E '^build:' Makefile 2>/dev/null && echo "make build"

# Discover lint command
grep -E '"lint"' package.json 2>/dev/null && echo "npm run lint"
```

Run discovered commands to verify fix.

**If tests fail after fix:**

1. Analyze the new failure
2. Determine if it's a regression or unrelated
3. If regression: iterate on fix
4. If unrelated: note for separate investigation

### Phase 7: Summary

**Goal:** Document what was done.

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
| `[path]` | [description] |

### Verification
- [ ] Reproducing test created (if TDD)
- [ ] Test passes after fix
- [ ] Full test suite passes
- [ ] No regressions detected

### Recommendations
[Any follow-up actions]
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
1. Discover and run test with verbose output
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
   - Runtime version
   - Dependency versions
   - Environment variables
   - Database/service state

2. Check for:
   - Hardcoded paths
   - Missing env vars
   - Platform-specific code
```

### Performance Debugging

```
1. Identify the slow operation
2. Add timing measurements
3. Check for profiling tools in project
4. Look for common issues:
   - N+1 queries
   - Unnecessary loops
   - Memory leaks
   - Blocking operations
```

---

## Rules (L1 - Hard)

Critical for effective debugging and avoiding damage.

- ALWAYS identify root cause before implementing fix (prevents wrong fixes)
- NEVER skip root cause analysis (surface symptoms mislead)
- NEVER commit without verification (may introduce more bugs)
- NEVER ignore regressions (compounds problems)
- NEVER assume specific framework commands (discover them)

## Defaults (L2 - Soft)

Important for quality debugging. Override with reasoning when appropriate.

- Discover project's test/build commands before running them
- Verify fix with tests
- Delegate implementation to appropriate specialist
- Document root cause analysis for future reference

## Guidelines (L3)

Recommendations for thorough debugging.

- Consider using TDD approach (write failing test first)
- Prefer examining recent git changes when investigating
