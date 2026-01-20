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

## Evaluation Metrics

From Anthropic's "Demystifying evals for AI agents" engineering blog:

### Key Metrics for Non-Deterministic Evaluation

| Metric | Formula | Use Case |
|--------|---------|----------|
| **pass@k** | P(at least 1 success in k trials) | "Can it succeed?" |
| **pass^k** | P(all k trials succeed) | "Is it consistent?" |

### Interpreting Metrics

```
pass@k = 1 - (1 - p)^k  where p = per-trial success rate

Example with p = 0.7:
- pass@1 = 0.70  (70% chance of success on single try)
- pass@3 = 0.97  (97% chance at least one succeeds)
- pass^3 = 0.34  (34% chance all three succeed)
```

**Use pass@k** for evaluating capability (can the agent do this task?)
**Use pass^k** for evaluating reliability (will the agent consistently do this?)

### Three Types of Graders

| Grader Type | Pros | Cons | Best For |
|-------------|------|------|----------|
| **Code-based** | Fast, cheap, objective | Brittle to valid variations | Format validation, syntax checks |
| **Model-based** | Flexible, scalable | Non-deterministic, needs calibration | Nuanced quality assessment |
| **Human** | Gold-standard quality | Expensive, slow | Final validation, edge cases |

### Grader Selection Strategy

```
1. Start with code-based graders for objective criteria
   - JSON schema validation
   - Required field presence
   - Format compliance

2. Add model-based graders for subjective criteria
   - Code quality assessment
   - Documentation clarity
   - Design appropriateness

3. Reserve human graders for:
   - Calibrating model-based graders
   - Edge case evaluation
   - Final sign-off on critical outputs
```

### Evaluation Best Practices

| Practice | Description |
|----------|-------------|
| Start early | Begin with 20-50 tasks from real failures, not 100+ perfect tasks |
| Grade outcomes | Evaluate results, not specific solution paths |
| Avoid class imbalance | Balance positive and negative cases |
| Read transcripts | Regularly verify graders measure what matters |
| Monitor saturation | Add harder tasks when current ones are consistently passed |

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

## Rules (L1 - Hard)

Critical for effective optimization loops.

- ALWAYS define clear evaluation criteria before starting (otherwise cannot converge)
- ALWAYS set maximum iteration limits (prevent infinite loops)
- NEVER let generator evaluate its own output (bias toward approval)
- NEVER ignore evaluation feedback in subsequent iterations

## Defaults (L2 - Soft)

Important for quality results. Override with reasoning when appropriate.

- Provide actionable feedback (not just "needs improvement")
- Track iteration count and score progression
- Return best attempt if max iterations reached
- Use separate agent instances for generator and evaluator

## Guidelines (L3)

Recommendations for better optimization.

- Consider using multiple specialized evaluators for complex outputs
- Prefer score thresholds of 80+ for production-quality outputs
- Consider diminishing returns beyond 3-4 iterations
