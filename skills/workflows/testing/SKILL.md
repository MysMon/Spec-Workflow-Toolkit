---
name: testing
description: |
  Test strategy, unit testing, integration testing, and E2E testing patterns across any stack. Use when:
  - Writing unit, integration, or E2E tests
  - Developing test strategies or improving coverage
  - Using Jest, Vitest, pytest, Go testing, or Rust testing
  - Setting up Playwright or Cypress for E2E
  - Debugging failing tests or flaky tests
  - Asked about mocking, fixtures, or test data
  Trigger phrases: write tests, unit test, integration test, E2E test, test coverage, pytest, jest, vitest, playwright, cypress, mock, fixture
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
model: sonnet
user-invocable: true
---

# Testing

Stack-adaptive testing patterns and practices.

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

```
// All languages follow this pattern
Arrange: Set up test data and dependencies
Act: Execute the code under test
Assert: Verify expected outcomes
```

### Naming Convention

```
[unit_being_tested]_[scenario]_[expected_result]

Examples:
- createUser_withValidData_returnsUser
- calculateTotal_withEmptyCart_returnsZero
- login_withInvalidCredentials_throwsAuthError
```

## Framework Detection & Commands

### Detect Test Framework

```bash
# JavaScript
ls vitest.config.* jest.config.* 2>/dev/null

# Python
grep -q pytest pyproject.toml requirements.txt 2>/dev/null

# Go (built-in)
ls *_test.go 2>/dev/null

# Rust (built-in)
grep -q "#\[test\]" src/*.rs 2>/dev/null

# Java
ls pom.xml build.gradle 2>/dev/null
```

### Run Tests

| Language | Command |
|----------|---------|
| JavaScript (Vitest) | `npm test` or `npx vitest` |
| JavaScript (Jest) | `npm test` or `npx jest` |
| Python (pytest) | `pytest` or `python -m pytest` |
| Go | `go test ./...` |
| Rust | `cargo test` |
| Java (Maven) | `mvn test` |
| Java (Gradle) | `./gradlew test` |

### Coverage Reports

| Language | Command |
|----------|---------|
| JavaScript | `npm run test:coverage` |
| Python | `pytest --cov=src` |
| Go | `go test -cover ./...` |
| Rust | `cargo tarpaulin` |

## Unit Testing Patterns

### What to Unit Test

- Business logic
- Edge cases
- Error conditions
- Input validation
- Pure functions

### What NOT to Unit Test

- Framework code
- External libraries
- Simple getters/setters
- Implementation details

### Mocking Guidelines

**When to Mock:**
- External services (APIs, databases)
- Time-dependent operations
- Random number generation
- File system operations

**When NOT to Mock:**
- The code under test
- Simple utilities
- Domain logic

## Integration Testing

### API Testing Pattern

```
1. Set up test database/state
2. Make HTTP request
3. Assert response status
4. Assert response body
5. Assert side effects (database state)
6. Clean up
```

### Database Testing

```
Strategies:
- Use test database
- Transaction rollback
- Seed and clean per test
- Use containers (testcontainers)
```

## E2E Testing

### Locator Priority (Playwright/Cypress)

1. `getByRole()` - Most accessible
2. `getByLabel()` - Form inputs
3. `getByText()` - Content
4. `getByTestId()` - Last resort

### Page Object Model

```
pages/
  login.page.ts
  dashboard.page.ts
  settings.page.ts

tests/
  login.spec.ts
  dashboard.spec.ts
```

### E2E Best Practices

- Test critical user journeys
- Use realistic test data
- Avoid flaky selectors
- Don't test everything E2E

## Test Data Management

### Factories

```
Use factories for dynamic test data:
- Generate realistic data
- Override specific fields
- Avoid hardcoded values
```

### Fixtures

```
Use fixtures for stable scenarios:
- Predefined user accounts
- Reference data sets
- Configuration presets
```

## Coverage Targets

| Type | Target |
|------|--------|
| Statements | 80% |
| Branches | 80% |
| Functions | 80% |
| Lines | 80% |

## Test Quality Checklist

- [ ] Tests are independent (no shared state)
- [ ] Tests are deterministic (same result every run)
- [ ] Tests clean up after themselves
- [ ] Tests are fast (unit < 100ms)
- [ ] Test names describe what they test
- [ ] Tests cover happy path and error cases

## Rules

- ALWAYS write tests BEFORE fixing bugs
- ALWAYS test edge cases
- NEVER test implementation details
- NEVER share state between tests
- ALWAYS clean up test data
- NEVER use sleep/delays (use proper waits)
- ALWAYS prefer real implementations when fast
