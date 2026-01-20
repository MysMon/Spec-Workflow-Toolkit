---
name: tdd-workflow
description: |
  Test-Driven Development workflow with Red-Green-Refactor cycle.
  Based on Anthropic's recommended TDD patterns for agentic coding.

  Use when:
  - Implementing new features with clear acceptance criteria
  - Bug fixes where test-first approach prevents regression
  - User says "TDD", "write tests first", "red-green-refactor"
  - Refactoring existing code (need tests before changes)
  - Features that are easily verifiable with tests

  Trigger phrases: TDD, test-driven, test first, red-green-refactor, write tests before code
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, TodoWrite, AskUserQuestion
model: sonnet
user-invocable: true
---

# Test-Driven Development Workflow

A disciplined TDD approach for Claude Code that ensures quality through the Red-Green-Refactor cycle.

From Claude Code Best Practices:

> "Test-driven development (TDD) becomes even more powerful with agentic coding: Ask Claude to write tests based on expected input/output pairs."

> "It's crucial to be explicit that you are doing TDD, which helps Claude avoid creating mock implementations or stubbing out imaginary code prematurely."

## Core Principles

### 1. Tests ALWAYS Come First

**RULE**: Never write implementation code without a failing test.

If asked to "create a feature," respond: "Let me write a test first."

### 2. Minimal Implementation

**RULE**: Write the simplest code that passes the current test.

- No premature optimization
- No speculative features
- No "just in case" code

### 3. Refactor Only When Green

**RULE**: Refactoring happens ONLY when all tests pass.

- Improve structure without changing behavior
- Run tests after each refactor step
- Keep refactoring atomic and reversible

## Red-Green-Refactor Cycle

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌─────────┐      ┌─────────┐      ┌──────────┐               │
│  │   RED   │─────▶│  GREEN  │─────▶│ REFACTOR │───┐           │
│  │         │      │         │      │          │   │           │
│  │ Write   │      │ Write   │      │ Improve  │   │           │
│  │ failing │      │ minimal │      │ code     │   │           │
│  │ test    │      │ code to │      │ quality  │   │           │
│  │         │      │ pass    │      │          │   │           │
│  └─────────┘      └─────────┘      └──────────┘   │           │
│       ▲                                            │           │
│       │                                            │           │
│       └────────────────────────────────────────────┘           │
│                      Next Feature                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 1: RED - Write Failing Test

### Steps

1. **Understand the requirement** clearly
2. **Write a test** that expresses the expected behavior
3. **Run the test** and confirm it FAILS
4. **Document the failure** - this proves the test is valid

### Test Writing Guidelines

```typescript
// GOOD: Descriptive, specific, tests one behavior
describe('UserService', () => {
  describe('createUser', () => {
    it('should hash password before storing', async () => {
      const plainPassword = 'password123';
      const user = await userService.createUser({
        email: 'test@example.com',
        password: plainPassword
      });

      expect(user.password).not.toBe(plainPassword);
      expect(await bcrypt.compare(plainPassword, user.password)).toBe(true);
    });
  });
});

// BAD: Vague, tests multiple things
it('should create user', async () => {
  // Tests too many things at once
});
```

### Failure Verification (CRITICAL)

**Always confirm the test fails for the right reason:**

```
Expected: 'hashed_password_value'
Received: undefined
       ↑ This tells us the function doesn't exist yet - GOOD!

vs.

TypeError: Cannot read property 'hash' of undefined
       ↑ This is an infrastructure problem - FIX FIRST!
```

## Phase 2: GREEN - Make It Pass

### Steps

1. **Write minimal code** to pass the test - nothing more
2. **Run the test** and confirm it PASSES
3. **Run all tests** to ensure no regressions
4. **If any test fails**, fix immediately before proceeding

### Minimal Implementation Rules

| DO | DON'T |
|----|-------|
| Return hardcoded value if one test | Implement full algorithm |
| Use simple data structures | Create complex abstractions |
| Focus on the current test | Think about future tests |
| Use obvious, readable code | Optimize prematurely |

### Example: Minimal Implementation

```typescript
// Test:
it('should return greeting with name', () => {
  expect(greet('World')).toBe('Hello, World!');
});

// Minimal GREEN implementation:
function greet(name: string): string {
  return `Hello, ${name}!`;
}

// NOT THIS (premature complexity):
function greet(name: string, locale: string = 'en'): string {
  const greetings = { en: 'Hello', es: 'Hola', fr: 'Bonjour' };
  return `${greetings[locale] || 'Hello'}, ${name}!`;
}
```

## Phase 3: REFACTOR - Improve Quality

### When to Refactor

Only refactor when:
- All tests are GREEN
- Code works but could be cleaner
- Duplication exists
- Names could be clearer

### Refactoring Checklist

- [ ] All tests passing before starting
- [ ] Make ONE small change
- [ ] Run tests after change
- [ ] Commit if still green
- [ ] Repeat until satisfied

### Safe Refactoring Patterns

| Pattern | When to Apply |
|---------|---------------|
| Extract method | Long function, repeated logic |
| Rename | Unclear names |
| Extract constant | Magic numbers/strings |
| Simplify conditional | Complex if/else chains |
| Remove duplication | Copy-paste code |

## TodoWrite Integration

Track TDD progress with TodoWrite:

```
1. [in_progress] RED: Write failing test for user registration
2. [pending] GREEN: Implement minimal registration logic
3. [pending] REFACTOR: Extract validation logic
4. [pending] RED: Write test for email uniqueness
5. [pending] GREEN: Add unique email check
...
```

**RULE**: Each Red-Green-Refactor cycle is 3 todos.

## Subagent Delegation

### qa-engineer for Test Writing

```
Delegate to qa-engineer:

Task: Write failing tests for [feature]
Requirements:
- Test file: tests/[feature].test.ts
- Cover: [acceptance criteria from spec]
- Include: Edge cases, error conditions
- Format: Jest/Vitest with describe/it blocks

Expected output:
- Test file created
- Tests run and FAIL (confirm RED state)
- Failure reasons documented
```

### frontend/backend-specialist for Implementation

```
Delegate to [specialist]:

Task: Make tests pass for [feature]
Tests: tests/[feature].test.ts
Constraints:
- MINIMAL implementation only
- No extra features
- No premature optimization
- All tests must pass

Expected output:
- Implementation created
- ALL tests passing
- No new failing tests introduced
```

## TDD with Specifications

### From Spec to Tests

```markdown
## Specification: User Registration

**Acceptance Criteria:**
1. User can register with email and password
2. Email must be unique
3. Password must be at least 8 characters
4. Password must be hashed before storage

## Derived Tests:

1. `it('should create user with valid email and password')`
2. `it('should reject duplicate email')`
3. `it('should reject password shorter than 8 characters')`
4. `it('should hash password before storing')`
```

## Common Anti-Patterns

| Anti-Pattern | Why It's Bad | Instead |
|--------------|--------------|---------|
| Writing implementation first | No proof tests catch bugs | Always RED first |
| Writing multiple tests at once | Unclear which test drives which code | One test at a time |
| Making tests pass with mocks | Tests don't prove real behavior | Use real implementations |
| Skipping REFACTOR | Technical debt accumulates | Refactor while context is fresh |
| Testing implementation details | Tests break on refactoring | Test behavior, not internals |

## TDD for Bug Fixes

### Bug Fix Workflow

1. **Write a test that reproduces the bug**
   - Test should FAIL with current code
   - Failure message should describe the bug

2. **Confirm the test fails**
   - This proves the bug exists
   - This proves your test catches it

3. **Fix the bug**
   - Minimal change to make test pass
   - Don't fix "nearby" issues

4. **Run all tests**
   - Original test now passes
   - No regressions introduced

## Integration with SDD Workflow

In Phase 5 (Implementation) of `/sdd`:

```
1. Read specification and design
2. Extract acceptance criteria
3. For each criterion:
   a. RED: Write failing test
   b. GREEN: Implement minimally
   c. REFACTOR: Clean up
4. Run full test suite
5. Update progress files
6. Commit working code
```

## Rules (L1 - Hard)

Core TDD discipline. Violations undermine the entire methodology.

- NEVER write implementation before test (defeats TDD purpose)
- NEVER skip the RED confirmation step (proves test validity)
- NEVER refactor on RED (changing code while tests fail)
- ALWAYS run all tests before committing (catch regressions)

## Defaults (L2 - Soft)

Important for test quality. Override with reasoning when appropriate.

- Keep tests fast and focused (slow tests get skipped)
- Test behavior, not implementation details (fragile tests)
- Write one test at a time (clearer cause-and-effect)
- Each Red-Green-Refactor cycle should be 3 todos

## Guidelines (L3)

Recommendations for effective TDD practice.

- Consider documenting why a test exists in comments or test name
- Prefer real implementations over mocks when practical
- Consider extracting test fixtures for reuse
