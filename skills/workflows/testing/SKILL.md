---
name: testing
description: |
  Test strategy, patterns, and best practices applicable to any technology stack. Use when:
  - Writing unit, integration, or E2E tests
  - Developing test strategies or improving coverage
  - Learning testing best practices
  - Debugging failing or flaky tests
  - Setting up test data, mocks, or fixtures
  Trigger phrases: write tests, unit test, integration test, E2E test, test coverage, test strategy, mock, fixture, test data
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
model: sonnet
user-invocable: true
---

# Testing

Stack-adaptive testing patterns and practices. This skill defines **testing principles and methodologies**, not specific framework commands.

## Design Principles

1. **Discover, don't assume**: Detect what testing tools the project uses
2. **Project-first**: Use the project's configured test commands
3. **Patterns over tools**: Teach testing concepts that apply to any framework

---

## Test Pyramid

```
         /\
        /E2E\        Few: Critical user journeys (5-10%)
       /------\
      / Integ  \     Some: Service boundaries (15-25%)
     /----------\
    /   Unit     \   Many: Business logic (65-80%)
   /--------------\
```

## Test Structure

### Arrange-Act-Assert (AAA)

Universal pattern for all test frameworks:

```
Arrange: Set up test data and dependencies
Act:     Execute the code under test
Assert:  Verify expected outcomes
```

### Naming Convention

```
[unit_being_tested]_[scenario]_[expected_result]

Examples:
- createUser_withValidData_returnsUser
- calculateTotal_withEmptyCart_returnsZero
- login_withInvalidCredentials_throwsAuthError
```

---

## Framework Detection

### Step 1: Discover Test Configuration

Look for test configuration files in the project:

```bash
# List potential test config files
ls -la *test*.config.* *jest*.* *vitest*.* pytest.ini setup.cfg pyproject.toml 2>/dev/null

# Check for test directories
ls -d tests/ test/ __tests__/ spec/ *_test/ 2>/dev/null

# Check package.json/pyproject.toml for test scripts
grep -A 5 '"test"' package.json 2>/dev/null
grep -A 5 '\[tool.pytest' pyproject.toml 2>/dev/null
```

### Step 2: Use Project's Test Commands

**Always prefer project-defined scripts:**

```bash
# Check for defined test scripts
grep -E '"test":|"test:' package.json 2>/dev/null    # JavaScript
grep -A 3 '\[scripts\]' pyproject.toml 2>/dev/null   # Python
cat Makefile 2>/dev/null | grep -E '^test:'          # Any language
```

**Run using the project's configured command:**
- If `npm test` is configured → use `npm test`
- If `make test` exists → use `make test`
- Otherwise, search for the standard command for the detected framework

### Step 3: Research Framework Commands

If the test framework is unfamiliar, use WebSearch:

```
WebSearch: "[framework name] run tests command [year]"
WebFetch: [official docs] → "Extract test execution commands"
```

---

## Unit Testing Principles

### What to Unit Test

- Business logic and algorithms
- Edge cases and boundary conditions
- Error conditions and exception handling
- Input validation
- Pure functions (no side effects)

### What NOT to Unit Test

- Framework/library code
- Simple getters/setters
- Implementation details (test behavior, not structure)
- Third-party integrations (use integration tests)

### Mocking Guidelines

**When to Mock:**
- External services (APIs, databases)
- Time-dependent operations (dates, timers)
- Random number generation
- File system operations
- Network requests

**When NOT to Mock:**
- The code under test itself
- Simple utility functions
- Internal domain logic
- Anything that's fast and deterministic

---

## Integration Testing

### API Testing Pattern

```
1. Set up test database/state
2. Make HTTP request to endpoint
3. Assert response status code
4. Assert response body structure and values
5. Assert side effects (database state changes)
6. Clean up test data
```

### Database Testing Strategies

| Strategy | Description | Use When |
|----------|-------------|----------|
| Transaction rollback | Run test in transaction, rollback after | Fast isolation needed |
| Test database | Separate database for tests | Full integration testing |
| Seed and clean | Load fixtures, clean after | Realistic data scenarios |
| Containers | Ephemeral DB per test run | CI/CD environments |

---

## E2E Testing

### Locator Priority

Best practices for finding elements (applies to most E2E frameworks):

1. **Accessibility roles** - Most robust, works like users interact
2. **Labels** - For form inputs
3. **Text content** - For visible content
4. **Test IDs** - Last resort, explicit for testing

### Page Object Model

Organize E2E tests with page abstractions:

```
pages/
  login.page.[ext]
  dashboard.page.[ext]
  settings.page.[ext]

tests/
  login.spec.[ext]
  dashboard.spec.[ext]
```

### E2E Best Practices

- Test critical user journeys, not everything
- Use realistic but consistent test data
- Avoid flaky selectors (prefer stable identifiers)
- Keep E2E test count low (pyramid principle)
- Run E2E tests in isolated environments

---

## Test Data Management

### Factories

Use factories for dynamic test data:
- Generate realistic data programmatically
- Override specific fields as needed
- Avoid hardcoded magic values in tests

### Fixtures

Use fixtures for stable scenarios:
- Predefined user accounts for login tests
- Reference data sets that don't change
- Configuration presets for different scenarios

---

## Coverage Guidelines

### Target Thresholds

| Metric | Suggested Target |
|--------|------------------|
| Statements | 80% |
| Branches | 80% |
| Functions | 80% |
| Lines | 80% |

### Coverage Commands

Discover coverage commands from project configuration:

```bash
# Check for coverage scripts
grep -E 'coverage|cov' package.json 2>/dev/null
grep -E 'coverage|cov' pyproject.toml 2>/dev/null
grep -E 'coverage|cov' Makefile 2>/dev/null
```

If no coverage script exists, search for the framework's coverage option:
```
WebSearch: "[test framework name] code coverage command"
```

---

## Test Quality Checklist

- [ ] Tests are independent (no shared mutable state)
- [ ] Tests are deterministic (same result every run)
- [ ] Tests clean up after themselves
- [ ] Tests are fast (unit < 100ms typical)
- [ ] Test names describe what they verify
- [ ] Tests cover both success and error cases
- [ ] No hardcoded paths or environment-specific values

---

## Debugging Failing Tests

### Process

1. **Read the failure message** - Understand expected vs actual
2. **Run test in isolation** - Verify it's not dependent on other tests
3. **Add logging** - Print intermediate values
4. **Check test setup** - Verify preconditions are met
5. **Verify mocks** - Ensure mocks return expected values
6. **Check for flakiness** - Run multiple times

### Flaky Test Indicators

- Test passes/fails inconsistently
- Test depends on timing or order
- Test uses real external services
- Test has race conditions in async code

---

## Rules (L1 - Hard)

Critical for test reliability and safety.

- NEVER share mutable state between tests (causes flakiness)
- NEVER use hardcoded delays (use proper async waiting)
- ALWAYS write tests BEFORE fixing bugs (reproduce first)

## Defaults (L2 - Soft)

Important for effective testing. Override with reasoning when appropriate.

- Discover the project's test framework before running tests
- Use the project's configured test commands
- Test edge cases and error conditions
- Test behavior, not implementation details
- Document reason when skipping tests

## Guidelines (L3)

Recommendations for comprehensive test coverage.

- Consider using AAA pattern (Arrange-Act-Assert) for clarity
- Prefer factories for dynamic test data
- Consider coverage targets around 80%
