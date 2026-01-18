---
name: think-tool
description: |
  Structured reasoning pattern for complex decision-making during tool chains.
  Based on Anthropic's "think" tool pattern for improved agent performance.

  Use when:
  - Processing tool outputs before taking action
  - Policy compliance verification is important
  - Sequential decisions where errors are costly
  - Complex multi-step reasoning is needed
  - Long tool call chains require careful analysis

  Trigger phrases: think through, analyze carefully, verify before acting, structured reasoning, complex decision
allowed-tools: Read, Glob, Grep
model: haiku
user-invocable: false
---

# Think Tool Pattern

A structured reasoning technique that gives agents dedicated space to pause and think during complex tasks. Different from extended thinking, this operates *after* response generation begins.

From Anthropic's "The think tool" engineering blog:

> "With the 'think' tool, we're giving Claude the ability to include an additional thinking step—complete with its own designated space—as part of getting to its final answer."

## Core Concept

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Tool Call 1 ──▶ Tool Result 1                             │
│                       │                                     │
│                       ▼                                     │
│              ┌─────────────────┐                           │
│              │   THINK TOOL    │  ◀── Structured pause     │
│              │  Analyze result │                           │
│              │  Plan next step │                           │
│              │  Verify policy  │                           │
│              └────────┬────────┘                           │
│                       │                                     │
│                       ▼                                     │
│  Tool Call 2 ──▶ Tool Result 2                             │
│                       │                                     │
│                       ▼                                     │
│              ┌─────────────────┐                           │
│              │   THINK TOOL    │  ◀── Verify before final  │
│              └────────┬────────┘                           │
│                       │                                     │
│                       ▼                                     │
│                 Final Response                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## When to Use

### Good Fit

| Scenario | Why Think Tool Works |
|----------|---------------------|
| Tool output analysis | Need to process results before next action |
| Policy compliance | Must verify actions against complex guidelines |
| Sequential decisions | Each step builds on prior ones, errors compound |
| Multi-step workflows | Need to maintain coherent reasoning across steps |
| Security-sensitive tasks | Must verify before taking irreversible actions |

### Poor Fit

| Scenario | Why Not |
|----------|---------|
| Non-sequential tasks | No benefit from pausing |
| Simple instruction following | Overhead not justified |
| Single-shot operations | No decision chain to manage |

## Implementation

### Basic Think Tool Definition

```json
{
  "name": "think",
  "description": "Use the tool to think about something. It will not obtain new information or change the database, but just append the thought to the log. Use it when complex reasoning or some cache memory is needed.",
  "input_schema": {
    "type": "object",
    "properties": {
      "thought": {
        "type": "string",
        "description": "A thought to think about."
      }
    },
    "required": ["thought"]
  }
}
```

### Enhanced Domain-Specific Version

```json
{
  "name": "think",
  "description": "Pause to analyze information, verify policy compliance, and plan next steps. Use before taking consequential actions or when processing complex tool outputs.",
  "input_schema": {
    "type": "object",
    "properties": {
      "analysis": {
        "type": "string",
        "description": "Analysis of current state and information gathered"
      },
      "policy_check": {
        "type": "string",
        "description": "Verification against relevant policies or constraints"
      },
      "next_step": {
        "type": "string",
        "description": "Planned next action and rationale"
      }
    },
    "required": ["analysis"]
  }
}
```

## Prompting for Effective Think Tool Usage

### Basic Prompting

```markdown
When processing tool outputs or making decisions:
1. Use the think tool to analyze results before acting
2. Consider policy implications
3. Plan your next step explicitly
```

### Optimized Prompting (54% improvement in τ-Bench)

```markdown
## Decision Protocol

Before taking any consequential action:

1. **Analyze**: Use think tool to process gathered information
2. **Verify**: Check compliance with policies and constraints
3. **Plan**: Explicitly state next step and rationale

Think tool usage is REQUIRED when:
- Processing tool outputs that inform next actions
- Making decisions that affect user data or system state
- Encountering ambiguous or conflicting information
```

## Performance Results

From Anthropic's testing on τ-Bench:

| Domain | Baseline | With Think Tool | Improvement |
|--------|----------|-----------------|-------------|
| Airline | 0.370 | 0.570 | **54% relative** |
| Retail | 0.783 | 0.812 | 3.7% relative |

## Integration with SDD Workflow

### Phase 5: Implementation

```markdown
During complex implementation sequences:

1. Read existing code
2. **Think**: Analyze patterns, identify integration points
3. Make code changes
4. **Think**: Verify changes follow established patterns
5. Continue to next file
```

### Phase 6: Quality Review

```markdown
When reviewing for quality:

1. Gather code and test information
2. **Think**: Analyze coverage gaps, security implications
3. Make recommendations
4. **Think**: Verify recommendations are actionable
5. Report findings
```

## Agent Integration

### Recommended for These Agents

| Agent | Think Tool Value |
|-------|------------------|
| `security-auditor` | **High** - Policy verification critical |
| `qa-engineer` | **High** - Test coverage decisions matter |
| `code-architect` | **Medium** - Design decisions benefit from structured analysis |
| `backend-specialist` | **Medium** - Data handling requires careful reasoning |

### Implementation in Agent Prompts

Add to agent's workflow section:

```markdown
## Structured Reasoning

Use the think tool pattern when:
- Processing codebase analysis results
- Verifying security policies
- Planning multi-step implementations
- Making decisions with significant impact

Think format:
- Analysis: [what you learned]
- Policy: [relevant constraints]
- Decision: [planned action and rationale]
```

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Think on every tool call | Unnecessary overhead | Only for consequential decisions |
| Empty or trivial thoughts | No value added | Require substantive analysis |
| Skipping think in complex chains | Errors compound | Mandate for policy-sensitive tasks |
| Over-reliance on think tool | Slows execution | Use extended thinking for upfront planning |

## Relationship to Extended Thinking

| Aspect | Extended Thinking | Think Tool |
|--------|-------------------|------------|
| Timing | Before response begins | During response generation |
| Purpose | Initial planning | Mid-execution reasoning |
| Best for | Complex upfront decisions | Tool chain management |
| Cost | Separate thinking budget | Part of main response |

**Recommendation**: Use extended thinking for initial task understanding, think tool for execution-time decisions.

## Rules

- ALWAYS use think tool before consequential actions in policy-heavy environments
- ALWAYS include substantive analysis (not placeholder thoughts)
- NEVER use think tool for simple, single-step operations
- ALWAYS connect thoughts to subsequent actions
- NEVER replace extended thinking entirely (use both appropriately)
- ALWAYS track decision rationale for audit purposes
