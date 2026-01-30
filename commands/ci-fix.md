---
description: "Diagnose and fix CI/CD pipeline failures with systematic log analysis and targeted fixes (Requires: GitHub CLI 'gh' for GitHub Actions)"
argument-hint: "[optional: CI URL, job name, or error message]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Task, TodoWrite, WebFetch
---

# /ci-fix - CI/CD Failure Resolution

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

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
- For complex feature implementation (use `/spec-plan`)
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
Use WebFetch to retrieve CI log content from the provided URL.
Supported CI platforms: GitHub Actions, GitLab CI, CircleCI, Jenkins, etc.
```

**If job name or error message provided:**

Delegate CI configuration discovery to code-explorer:

```
Launch code-explorer agent:
Task: Find CI configuration and recent changes
Analyze:
- CI configuration files (.github/workflows/, .gitlab-ci.yml, .circleci/, Jenkinsfile)
- Recent git history for CI-related changes
- Match job name or error message to configuration
Thoroughness: quick
Output: CI platform, relevant config files, recent CI-related commits
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

**Delegate log analysis to code-explorer:**

```
Launch code-explorer agent:
Task: Analyze CI log for failure patterns
Inputs: CI log content (from WebFetch or user)
Analyze:
- Exit codes (non-zero indicates failure point)
- Error messages with file:line references
- Stack traces
- "FAILED" or "ERROR" markers
- Difference between local and CI environment
Thoroughness: medium
Output: Failure category, specific error location, suggested resolution path
```

Use the agent's output for classification. Do NOT analyze logs manually.

### Phase 3A: Test Failure Resolution

**Goal:** Identify and fix failing tests.

**CRITICAL: Delegate ALL test analysis and reproduction to qa-engineer agent:**

```
Launch qa-engineer agent:
Task: Analyze and diagnose test failure from CI
Inputs:
  - CI log content (from Phase 2 analysis)
  - Test framework type (jest, pytest, etc.)
Do:
  1. Extract failing test info (file, name, expected vs actual, stack trace)
  2. Reproduce locally by running the specific failing test
  3. Analyze the difference (flaky, environment, recent code change)
  4. Check for flaky test indicators by running multiple times
  5. Categorize the issue (test logic, code bug, flaky test, environment)
Output:
  - Root cause analysis
  - Reproduction results
  - Recommended fix approach
  - If flaky: specific pattern detected and suggested fix
```

Do NOT extract test info or run tests directly in the parent context. Use the agent's output for next steps.

**Based on qa-engineer analysis:**

| Agent's Diagnosis | Next Step |
|-------------------|-----------|
| Test logic issue | Agent provides fix, review and apply |
| Code bug | Delegate to appropriate specialist with qa-engineer's analysis |
| Flaky test | Agent applies testing skill patterns (explicit waits, data isolation, mocking) |
| Environment issue | Proceed to Phase 3E |

**Flaky test reference:**
qa-engineer has the `testing` skill which includes:
- **Detection patterns**: Local and CI-based flaky test detection
- **Common causes and solutions**: Timing dependencies, shared state, race conditions
- **Fix strategies**: Explicit waits, test data isolation, time mocking, random seeding
- **Quarantine protocol**: How to skip flaky tests safely with proper tracking
- **CI retry strategies**: Framework-specific retry options

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

**Delegate environment comparison to code-explorer agent:**

```
Launch code-explorer agent:
Task: Compare local environment with CI configuration
Analyze:
  - CI configuration files (.github/workflows/, .gitlab-ci.yml, etc.)
  - Specified runtime versions (Node, Python, Go, etc.)
  - Environment variable usage
  - System dependency requirements
Compare with local:
  - Local runtime versions (node -v, python --version, etc.)
  - Differences in environment setup
Thoroughness: medium
Output:
  - Environment differences found
  - Specific version mismatches
  - Missing environment variables or dependencies
```

Do NOT read CI configuration files directly in the parent context. Use the agent's analysis for next steps.

**Common fixes (based on agent's analysis):**
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

**IMPORTANT:** ALWAYS delegate implementation to appropriate specialist agents.

```
Launch Task tool with appropriate specialist:

For test fixes → qa-engineer
For code changes → frontend-specialist or backend-specialist
For CI config changes → backend-specialist (model: haiku for simple fixes)

Prompt:
CI fix required.
File: [file path]
Issue: [error from CI log]
Fix needed: [specific change]

Include relevant CI log context in the prompt.
```

**Direct modification allowed ONLY for:**
- Single-line environment variable changes in CI config
- Version number updates (e.g., Node version in workflow)

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
| CI failure reveals code issue | `/ci-fix` diagnoses, then `/quick-impl` or `/spec-plan` to fix |
| CI fix needs review | After `/ci-fix`, run `/code-review staged` |
