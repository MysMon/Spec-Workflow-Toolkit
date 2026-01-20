---
description: "Diagnose and fix CI/CD pipeline failures with systematic log analysis and targeted fixes"
argument-hint: "[optional: CI URL, job name, or error message]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task, TodoWrite, WebFetch
---

# /ci-fix - CI/CD Failure Resolution

Systematically diagnose and fix CI/CD pipeline failures by analyzing logs, identifying root causes, and implementing targeted fixes.

## Purpose

CI failures are a common interruption in development workflows. This command provides a structured approach to:

1. **Analyze** - Parse CI logs to identify failure points
2. **Diagnose** - Determine root cause (test failure, lint error, build issue, environment problem)
3. **Fix** - Implement targeted fixes for identified issues
4. **Verify** - Confirm fixes locally before pushing

## When to Use

- CI pipeline failed after push
- Tests passing locally but failing in CI
- Build errors in CI environment
- Lint/format check failures
- Dependency resolution issues
- Environment-specific failures

## When NOT to Use

- For local-only issues (use `/debug` instead)
- For complex feature implementation (use `/sdd`)
- For urgent production issues (use `/hotfix`)

---

## Rules (L1 - Hard)

- NEVER push fixes without running tests locally first
- NEVER commit secrets or credentials exposed in CI logs
- ALWAYS verify the fix addresses the root cause, not just symptoms

## Defaults (L2 - Soft)

- Delegate code fixes to specialist agents (qa-engineer, frontend/backend-specialist)
- Run full CI check suite locally before pushing
- Document root cause in commit message

## Guidelines (L3)

- Consider if the CI failure reveals a larger systemic issue
- Prefer auto-fix tools (eslint --fix, black) for lint issues
- Check if failure is flaky before investing in fixes

---

## Execution Instructions

### Phase 1: Gather CI Context

**Goal:** Understand what failed and where.

**If URL provided (`$ARGUMENTS` contains URL):**

```
Use WebFetch to retrieve CI log content:
- GitHub Actions: https://github.com/owner/repo/actions/runs/ID
- GitLab CI: https://gitlab.com/owner/repo/-/jobs/ID
- CircleCI, Jenkins, etc.
```

**If job name or error message provided:**

Search for related CI configuration and recent runs:

```bash
# Find CI configuration files
ls -la .github/workflows/ 2>/dev/null || \
ls -la .gitlab-ci.yml 2>/dev/null || \
ls -la .circleci/ 2>/dev/null || \
ls -la Jenkinsfile 2>/dev/null

# Check recent git history for CI-related changes
git log --oneline -10 -- ".github/" ".gitlab-ci.yml" ".circleci/" "Jenkinsfile"
```

**If no argument:**

Ask user:
```
Question: "What CI failure do you need help with?"
Header: "CI Info"
Options:
- "Tests failing"
- "Build failing"
- "Lint/format errors"
- "Dependency issues"
```

### Phase 2: Failure Classification

**Goal:** Categorize the failure type for targeted resolution.

| Category | Indicators | Resolution Path |
|----------|------------|-----------------|
| **Test Failure** | `FAIL`, `AssertionError`, test framework output | Phase 3A |
| **Build Error** | `error:`, `Cannot find module`, compilation errors | Phase 3B |
| **Lint/Format** | `eslint`, `prettier`, `black`, style violations | Phase 3C |
| **Dependency** | `npm ERR!`, `pip install failed`, version conflicts | Phase 3D |
| **Environment** | `command not found`, path issues, missing env vars | Phase 3E |
| **Timeout** | `exceeded`, `timed out`, resource limits | Phase 3F |

**Analyze log patterns:**

```
Look for:
- Exit codes (non-zero indicates failure point)
- Error messages with file:line references
- Stack traces
- "FAILED" or "ERROR" markers
- Difference between local and CI environment
```

### Phase 3A: Test Failure Resolution

**Goal:** Identify and fix failing tests.

1. **Extract failing test info:**
   - Test file and name
   - Expected vs actual values
   - Stack trace location

2. **Reproduce locally:**
   ```bash
   # Run the specific failing test
   npm test -- --testNamePattern="failing test name"
   # or
   pytest path/to/test.py::test_name -v
   ```

3. **Analyze the difference:**
   - Is it a flaky test? (timing, randomness)
   - Environment difference? (CI has different config)
   - Recent code change? (check git blame)

4. **Check for flaky test:**

   Before investing in fixes, verify the test isn't flaky:

   ```bash
   # Run the failing test multiple times locally
   for i in {1..5}; do npm test -- --testNamePattern="suspect test" && echo "Pass $i" || echo "FAIL $i"; done

   # For pytest
   for i in {1..5}; do pytest path/to/test.py::test_name -x && echo "Pass $i" || echo "FAIL $i"; done
   ```

   **Flaky test indicators:**
   - Test passes some runs, fails others (without code changes)
   - Test fails only in CI but passes locally
   - Test mentions timing, sleep, or async operations
   - Different results when run in isolation vs full suite

   **If flaky test confirmed:**

   Load the `testing` skill which provides comprehensive flaky test management:
   - **Detection patterns**: Local and CI-based flaky test detection
   - **Common causes and solutions**: Timing dependencies, shared state, race conditions
   - **Fix strategies**: Explicit waits, test data isolation, time mocking, random seeding
   - **Quarantine protocol**: How to skip flaky tests safely with proper tracking
   - **CI retry strategies**: Framework-specific retry options

   Quick fixes to try first:
   - Replace `sleep()` with explicit wait conditions
   - Isolate test data (unique per test, not shared)
   - Mock time-dependent code
   - Seed random generators for reproducibility

5. **Delegate fix to appropriate agent:**
   ```
   If test logic issue → delegate to qa-engineer
   If code bug → delegate to appropriate specialist
   If flaky test → load testing skill, apply Flaky Test Management patterns
   ```

### Phase 3B: Build Error Resolution

**Goal:** Fix compilation or build errors.

1. **Identify build step:**
   - Compilation (TypeScript, Go, Rust, etc.)
   - Bundling (webpack, vite, etc.)
   - Docker build

2. **Common patterns:**

   | Error Type | Typical Cause | Fix |
   |------------|---------------|-----|
   | Type errors | Missing types, wrong imports | Fix type definitions |
   | Module not found | Missing dependency, wrong path | Check imports, install deps |
   | Syntax error | Invalid code | Fix syntax at indicated line |
   | Memory exceeded | Large build, inefficient bundling | Optimize or increase limit |

3. **Reproduce locally:**
   ```bash
   # Match CI environment
   npm ci  # Clean install
   npm run build
   ```

### Phase 3C: Lint/Format Error Resolution

**Goal:** Fix code style violations.

1. **Run linter locally:**
   ```bash
   npm run lint
   # or
   python -m black --check .
   python -m flake8
   ```

2. **Auto-fix if possible:**
   ```bash
   npm run lint -- --fix
   # or
   python -m black .
   ```

3. **For remaining issues:**
   - Review each violation
   - Fix manually or add justified ignore comment

### Phase 3D: Dependency Resolution

**Goal:** Fix package/dependency issues.

1. **Common issues:**

   | Issue | Diagnosis | Resolution |
   |-------|-----------|------------|
   | Version conflict | Multiple packages need different versions | Update or use resolutions |
   | Missing peer dep | Peer dependency not installed | Install explicitly |
   | Lock file mismatch | package-lock.json out of sync | Regenerate lock file |
   | Private package | Auth issue in CI | Check CI secrets |

2. **Verify lock file:**
   ```bash
   # Regenerate lock file
   rm -rf node_modules package-lock.json
   npm install

   # Or for yarn
   rm -rf node_modules yarn.lock
   yarn install
   ```

### Phase 3E: Environment Issues

**Goal:** Fix CI environment configuration.

1. **Check environment differences:**
   - Node/Python/Go version
   - Environment variables
   - File system paths
   - Available commands

2. **Compare with CI config:**
   ```
   Read CI configuration file
   Check specified versions and environment setup
   ```

3. **Common fixes:**
   - Pin runtime version in CI config
   - Add missing environment variables to CI secrets
   - Install required system dependencies

### Phase 3F: Timeout/Resource Issues

**Goal:** Optimize or increase resource limits.

1. **Identify bottleneck:**
   - Which step is slow?
   - Memory or CPU bound?

2. **Options:**
   - Parallelize tests
   - Add caching
   - Increase timeout/memory limit
   - Split into multiple jobs

---

### Phase 4: Implement Fix

**Goal:** Apply the identified fix.

**IMPORTANT:** Use appropriate specialist agents for implementation.

```
For test fixes → delegate to qa-engineer
For code changes → delegate to frontend-specialist or backend-specialist
For config changes → can modify directly (CI config is usually simple)
```

**After implementing:**

1. Run the same checks locally that CI runs
2. Verify the fix addresses the root cause
3. Check for any side effects

### Phase 5: Local Verification

**Goal:** Confirm fix works before pushing.

```bash
# Run the CI checks locally
npm ci && npm run lint && npm run test && npm run build

# Or the equivalent for your stack
```

**If verification passes:**

```markdown
## CI Fix Summary

### Failure Type
[Category from Phase 2]

### Root Cause
[Brief explanation of why CI was failing]

### Fix Applied
| File | Change |
|------|--------|
| `path/to/file` | [Description] |

### Verification
- [ ] Local tests pass
- [ ] Local build succeeds
- [ ] Local lint passes

### Ready to Push
The fix has been verified locally. Push to trigger CI again.
```

### Phase 6: User Decision

Ask user:
```
Question: "CI fix ready. What would you like to do?"
Header: "Action"
Options:
- "Commit and push" (Recommended)
- "Show me the changes first"
- "Run more local tests"
- "I'll push manually"
```

---

## CI Platform-Specific Tips

### GitHub Actions

```bash
# View workflow runs
gh run list

# View specific run logs
gh run view [run-id] --log

# Re-run failed jobs
gh run rerun [run-id] --failed
```

### GitLab CI

```bash
# Check pipeline status
glab ci status

# View job logs
glab ci trace [job-id]
```

---

## Common CI Failure Patterns

| Pattern | Likely Cause | Quick Check |
|---------|--------------|-------------|
| Works locally, fails in CI | Environment diff | Compare versions, env vars |
| Intermittent failures | Flaky test, race condition | Run test multiple times |
| Fails on specific file | That file has issues | Focus on changed lines |
| All tests fail | Setup issue, config problem | Check CI setup steps |
| Timeout | Slow tests, resource limit | Profile test duration |

---

## Integration with Other Commands

| Scenario | Command |
|----------|---------|
| CI failure needs deeper debugging | Start with `/ci-fix`, escalate to `/debug` |
| CI failure reveals code issue | `/ci-fix` diagnoses, then `/quick-impl` or `/sdd` to fix |
| CI fix needs review | After `/ci-fix`, run `/code-review staged` |
