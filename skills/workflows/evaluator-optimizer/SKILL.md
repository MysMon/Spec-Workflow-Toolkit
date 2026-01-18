---
name: evaluator-optimizer
description: |
  Iterative improvement pattern using evaluator-optimizer feedback loops.
  One of Anthropic's 6 composable patterns for building effective agents.

  Use when:
  - Output quality matters and iteration improves results
  - Clear evaluation criteria exist
  - User wants "refine", "improve", "iterate"
  - Complex outputs like documentation, designs, or algorithms
  - Multi-round optimization is acceptable (latency trade-off)

  Trigger phrases: iterate, refine, improve quality, feedback loop, evaluate and optimize, keep improving
allowed-tools: Read, Write, Edit, Glob, Grep, Task, TodoWrite, AskUserQuestion
model: sonnet
user-invocable: true
---

# Evaluator-Optimizer Pattern

An iterative improvement pattern where one agent generates output while another evaluates and provides feedback, continuing until quality criteria are met.

From Building Effective Agents:

> "One LLM generates responses while another evaluates and provides feedback iteratively. Effective for literary translation refinement and multi-round search tasks requiring judgment on whether further investigation is warranted."

## Core Concept

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌───────────┐    output    ┌───────────┐                      │
│  │           │─────────────▶│           │                      │
│  │ GENERATOR │              │ EVALUATOR │                      │
│  │  (Agent)  │◀─────────────│  (Agent)  │                      │
│  │           │   feedback   │           │                      │
│  └───────────┘              └───────────┘                      │
│       │                           │                            │
│       │ (if approved)             │                            │
│       ▼                           │                            │
│  ┌─────────┐                      │                            │
│  │ FINAL   │◀─────────────────────┘                            │
│  │ OUTPUT  │     (pass/fail + score)                           │
│  └─────────┘                                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## When to Use

### Good Fit

| Scenario | Why Evaluator-Optimizer Works |
|----------|------------------------------|
| Documentation | Clarity, completeness can be iteratively improved |
| Code refactoring | Quality metrics guide optimization |
| API design | Usability and consistency refinable |
| UI/UX copy | Tone, clarity, engagement tunable |
| Complex algorithms | Performance/correctness verifiable |

### Poor Fit

| Scenario | Why Not |
|----------|---------|
| Simple CRUD | Overhead not justified |
| Time-critical tasks | Iteration adds latency |
| No clear criteria | Can't evaluate effectively |
| Binary correct/incorrect | Single pass sufficient |

## Implementation Pattern

### 1. Generator Agent

Creates initial output based on requirements.

```markdown
## Generator Task

Create: [description of output]
Requirements: [specific requirements]
Format: [expected format]

## Output Format

Provide your output with clear sections:
- Main content
- Self-assessment of quality
- Areas of uncertainty
```

### 2. Evaluator Agent

Reviews output against criteria and provides actionable feedback.

```markdown
## Evaluator Task

Review the following output:
[generator output]

Evaluation Criteria:
1. Correctness: Does it meet the requirements?
2. Completeness: Are all aspects covered?
3. Clarity: Is it understandable?
4. Quality: Does it follow best practices?

## Output Format

Score: [0-100]
Pass: [true/false] (threshold: 80)

Strengths:
- [what works well]

Issues:
- [Issue 1]: [specific problem]
  Fix: [actionable improvement]
- [Issue 2]: [specific problem]
  Fix: [actionable improvement]

Verdict: [PASS / NEEDS_REVISION]
```

### 3. Optimization Loop

```python
# Conceptual flow
max_iterations = 3
iteration = 0
passed = False

while iteration < max_iterations and not passed:
    # Generate
    output = generator.create(requirements, feedback)

    # Evaluate
    evaluation = evaluator.review(output, criteria)

    if evaluation.score >= threshold:
        passed = True
    else:
        feedback = evaluation.issues
        iteration += 1

return output, evaluation
```

## Subagent Configuration

### Generator Subagent

```yaml
name: generator
model: sonnet  # or inherit for complex tasks
tools: Read, Write, Edit, Glob, Grep
permissionMode: acceptEdits
```

### Evaluator Subagent

```yaml
name: evaluator
model: sonnet  # Use same or stronger model
tools: Read, Glob, Grep  # Read-only evaluation
permissionMode: plan
disallowedTools: Write, Edit, Bash
```

## Practical Examples

### Example 1: Documentation Optimization

```markdown
## Iteration 1

### Generator Output
```typescript
/**
 * Creates a user
 * @param data - user data
 */
function createUser(data: UserData): User { ... }
```

### Evaluator Feedback
Score: 65
Issues:
- Missing: Parameter documentation incomplete
- Missing: Return value description
- Missing: Error conditions
- Missing: Example usage

### Iteration 2

### Generator Output (Improved)
```typescript
/**
 * Creates a new user account with the provided data.
 *
 * @param data - The user creation data
 * @param data.email - Valid email address (must be unique)
 * @param data.password - Password (min 8 chars, hashed before storage)
 * @param data.name - Display name (optional)
 *
 * @returns The created User object with generated ID
 *
 * @throws {DuplicateEmailError} If email already exists
 * @throws {ValidationError} If data fails validation
 *
 * @example
 * const user = await createUser({
 *   email: 'john@example.com',
 *   password: 'securePass123'
 * });
 */
function createUser(data: UserData): Promise<User> { ... }
```

### Evaluator Feedback
Score: 92
Verdict: PASS
```

### Example 2: Algorithm Optimization

```markdown
## Iteration 1

### Generator Output
function findDuplicates(arr) {
  const duplicates = [];
  for (let i = 0; i < arr.length; i++) {
    for (let j = i + 1; j < arr.length; j++) {
      if (arr[i] === arr[j] && !duplicates.includes(arr[i])) {
        duplicates.push(arr[i]);
      }
    }
  }
  return duplicates;
}

### Evaluator Feedback
Score: 55
Issues:
- Performance: O(n²) time complexity, O(n) for includes
- Correctness: Works but inefficient
Fix: Use Set or Map for O(n) solution

### Iteration 2

### Generator Output (Improved)
function findDuplicates(arr) {
  const seen = new Set();
  const duplicates = new Set();

  for (const item of arr) {
    if (seen.has(item)) {
      duplicates.add(item);
    } else {
      seen.add(item);
    }
  }

  return [...duplicates];
}

### Evaluator Feedback
Score: 95
Verdict: PASS
Strengths:
- O(n) time complexity
- O(n) space complexity (optimal for this problem)
- Clean, readable implementation
```

## Integration with SDD Workflow

In Phase 4 (Architecture Design) and Phase 6 (Quality Review):

### Architecture Design Optimization

```
1. code-architect generates initial design
2. Evaluator checks against:
   - Codebase patterns
   - Scalability requirements
   - Security considerations
3. Iterate until design scores >= 85
```

### Quality Review Optimization

```
1. Implementation complete (Phase 5)
2. qa-engineer evaluates test coverage
3. If coverage < 80%, iterate:
   - Identify gaps
   - Add tests
   - Re-evaluate
```

## Stopping Conditions

### Must Stop When

| Condition | Action |
|-----------|--------|
| Score >= threshold | Accept output |
| Max iterations reached | Return best attempt with warning |
| Evaluator stuck in loop | Break with human review request |
| Fundamental flaw detected | Escalate to user |

### Recommended Limits

| Context | Max Iterations | Score Threshold |
|---------|----------------|-----------------|
| Documentation | 3 | 80 |
| Code quality | 3 | 85 |
| Algorithm | 4 | 90 |
| Security-critical | 5 | 95 |

## Anti-Patterns

| Anti-Pattern | Why Bad | Instead |
|--------------|---------|---------|
| No stopping condition | Infinite loop risk | Set max iterations |
| Same model evaluates own output | Bias toward approval | Use separate agent |
| Vague criteria | Can't converge | Define specific rubrics |
| Ignoring feedback | No improvement | Generator must address issues |
| Over-optimizing | Diminishing returns | Accept "good enough" |

## Advanced: Multi-Evaluator

For complex outputs, use multiple specialized evaluators:

```
Generator Output
      │
      ├──▶ Correctness Evaluator
      │
      ├──▶ Style Evaluator
      │
      ├──▶ Performance Evaluator
      │
      └──▶ Security Evaluator

Combined Score = weighted average
Feedback = aggregated from all evaluators
```

## Rules

- ALWAYS define clear evaluation criteria before starting
- ALWAYS set maximum iteration limits
- NEVER let generator evaluate its own output (use separate agent)
- ALWAYS provide actionable feedback (not just "needs improvement")
- ALWAYS track iteration count and score progression
- NEVER ignore evaluation feedback in subsequent iterations
- ALWAYS return best attempt if max iterations reached
