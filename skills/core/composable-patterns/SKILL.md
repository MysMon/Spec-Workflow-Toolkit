---
name: composable-patterns
description: |
  Anthropic's 6 composable patterns for building effective agents.
  Fundamental building blocks for all agent workflows in this toolkit.

  Use when:
  - Designing new agent workflows
  - Understanding why certain patterns are used
  - Selecting appropriate orchestration strategy
  - Building custom automation

  Reference: https://www.anthropic.com/research/building-effective-agents
allowed-tools: Read, Task
model: sonnet
user-invocable: true
---

# Anthropic's 6 Composable Patterns

The foundational patterns for building effective AI agents, as defined by Anthropic's research. These patterns form the basis of all workflows in this toolkit.

## Official Source

From [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents):

> "Consistently, the most successful implementations weren't using complex frameworks or specialized libraries. Instead, they were building with simple, composable patterns."

## Pattern Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                  ANTHROPIC'S 6 COMPOSABLE PATTERNS              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ 1. PROMPT       │  │ 2. ROUTING      │  │ 3. PARALLEL-    │ │
│  │    CHAINING     │  │                 │  │    IZATION      │ │
│  │                 │  │                 │  │                 │ │
│  │ A → B → C       │  │    ┌─▶ B       │  │   ┌─ B ─┐       │ │
│  │                 │  │ A ─┼─▶ C       │  │ A ─┼─ C ─┼─▶ D  │ │
│  │                 │  │    └─▶ D       │  │   └─ D ─┘       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ 4. ORCHESTRATOR │  │ 5. EVALUATOR-   │  │ 6. AUGMENTED    │ │
│  │    WORKERS      │  │    OPTIMIZER    │  │    LLM          │ │
│  │                 │  │                 │  │                 │ │
│  │      ┌─ W1      │  │ G ──▶ E ──┐    │  │  LLM + Tools    │ │
│  │ O ───┼─ W2      │  │ ▲         │    │  │  + Memory       │ │
│  │      └─ W3      │  │ └─────────┘    │  │  + Retrieval    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Pattern 1: Prompt Chaining

**Definition**: Decompose a task into sequential steps where each LLM call processes the previous output.

### When to Use

- Tasks that can be cleanly decomposed into fixed subtasks
- Each step's output is input for the next
- Need to verify/gate between steps

### SDD Toolkit Examples

- **7-Phase SDD Workflow**: Discovery → Exploration → Clarification → Design → Implementation → Review → Summary
- **TDD Cycle**: RED (write test) → GREEN (implement) → REFACTOR (clean up)

### Implementation

```
Input
  │
  ▼
┌─────────┐     ┌─────────┐     ┌─────────┐
│ Phase 1 │────▶│ Phase 2 │────▶│ Phase 3 │
│Discovery│     │ Explore │     │ Design  │
└─────────┘     └─────────┘     └─────────┘
      │              │              │
      ▼              ▼              ▼
   [Gate:         [Gate:         [Gate:
    User OK?]      Complete?]     Approved?]
```

### Key Principles

- Each step has focused, specific prompt
- Gates prevent proceeding on incomplete work
- Chain can be stopped and resumed at any gate

---

## Pattern 2: Routing

**Definition**: Classify inputs and direct them to specialized handlers.

### When to Use

- Different input types need different processing
- Optimization by matching complexity to model capability
- Separating concerns for maintainability

### SDD Toolkit Examples

- **Model Selection**: Opus for architecture decisions, Sonnet for implementation, Haiku for scoring
- **Command Routing**: `/sdd` for complex features, `/quick-impl` for simple tasks
- **Agent Selection**: Frontend vs Backend vs DevOps specialist

### Implementation

```
Input: "Add OAuth login"
  │
  ▼
┌─────────────┐
│ Classifier  │
└─────────────┘
      │
      ├─ "backend" ──▶ backend-specialist (inherit)
      │
      ├─ "frontend" ─▶ frontend-specialist (inherit)
      │
      ├─ "system" ───▶ system-architect (Opus)
      │
      └─ "simple" ───▶ quick-impl (Haiku)
```

### Key Principles

- Classification should be fast and reliable
- Routes should be mutually exclusive
- Each route can have optimized prompts/models

---

## Pattern 3: Parallelization

**Definition**: Run LLMs simultaneously with outputs aggregated.

### Two Variations

1. **Sectioning**: Break task into independent parallel subtasks
2. **Voting**: Run same task multiple times for diverse outputs

### SDD Toolkit Examples

- **Codebase Exploration**: 3 code-explorer agents analyze different aspects simultaneously
- **Code Review**: qa-engineer + security-auditor + style-checker in parallel
- **Confidence Scoring**: Multiple Haiku agents score same issue for consensus

### Implementation

```
Task: Review auth module

┌─────────────────────────────────────────────┐
│                                             │
│  ┌─────────────┐  ┌─────────────┐          │
│  │ qa-engineer │  │ security-   │          │
│  │             │  │ auditor     │          │
│  └──────┬──────┘  └──────┬──────┘          │
│         │                │                  │
│         └───────┬────────┘                  │
│                 │                           │
│                 ▼                           │
│        ┌───────────────┐                   │
│        │  Aggregator   │                   │
│        │ (Orchestrator)│                   │
│        └───────────────┘                   │
│                 │                           │
│                 ▼                           │
│          Combined Report                    │
│                                             │
└─────────────────────────────────────────────┘
```

### Key Principles

- Tasks must be truly independent (no dependencies)
- Aggregation strategy must be defined upfront
- Limit to 3-4 parallel agents for manageability

---

## Pattern 4: Orchestrator-Workers

**Definition**: Central LLM dynamically breaks down tasks, delegates to workers, synthesizes results.

### When to Use

- Complex tasks where subtasks can't be predicted upfront
- Need flexibility in work distribution
- Multi-step processes requiring coordination

### SDD Toolkit Examples

- **Main Orchestrator**: Coordinates all phases and agents
- **Implementation Phase**: Orchestrator delegates features to specialists one by one
- **Quality Review**: Orchestrator launches review agents, aggregates findings

### Implementation

```
User Request: "Add user authentication"
        │
        ▼
┌───────────────────────┐
│     ORCHESTRATOR      │
│   (Main Agent)        │
│                       │
│ Responsibilities:     │
│ - Plan decomposition  │
│ - Delegate to workers │
│ - Synthesize results  │
│ - Track progress      │
│ - Communicate w/user  │
└───────────────────────┘
        │
        ├─▶ code-explorer: "Analyze existing auth patterns"
        │         │
        │         └─▶ Returns: "JWT pattern at src/auth.ts:45"
        │
        ├─▶ code-architect: "Design OAuth integration"
        │         │
        │         └─▶ Returns: Design document
        │
        └─▶ backend-specialist: "Implement AuthService"
                  │
                  └─▶ Returns: Implementation + tests
```

### Key Principles

- Orchestrator maintains global plan and state
- Workers have focused, single-goal tasks
- Orchestrator NEVER does worker work itself (context protection)
- Workers return only essential results (~500 tokens)

---

## Pattern 5: Evaluator-Optimizer

**Definition**: One LLM generates, another evaluates and provides feedback iteratively.

### When to Use

- Output quality matters and iteration improves results
- Clear evaluation criteria exist
- Willing to trade latency for quality

### SDD Toolkit Examples

- **Documentation Improvement**: Generator writes docs, Evaluator scores clarity/completeness
- **Algorithm Refinement**: Generator implements, Evaluator checks performance/correctness
- **Code Quality**: Implementation reviewed and refined until meets standards

### Implementation

```
Requirements
     │
     ▼
┌──────────────────────────────────────────┐
│                                          │
│  ┌───────────┐        ┌───────────┐     │
│  │           │ output │           │     │
│  │ Generator │───────▶│ Evaluator │     │
│  │           │◀───────│           │     │
│  └───────────┘feedback└───────────┘     │
│       │                    │            │
│       │  (if score >= 80)  │            │
│       ▼                    │            │
│  ┌─────────┐               │            │
│  │ OUTPUT  │◀──────────────┘            │
│  └─────────┘    (approved)              │
│                                          │
└──────────────────────────────────────────┘

Max iterations: 3
Threshold: 80
```

### Key Principles

- Set maximum iterations to prevent infinite loops
- Define clear scoring rubric
- Different agents for generate vs evaluate (avoid self-approval bias)

---

## Pattern 6: Augmented LLM

**Definition**: LLM enhanced with retrieval, tools, and memory.

### When to Use

- Need access to external information
- Require tool execution (code, APIs, databases)
- Must maintain state across interactions

### SDD Toolkit Examples

- **Tool Access**: All agents have defined tool sets (Read, Write, Edit, Bash, etc.)
- **Retrieval**: stack-detector reads project files to understand tech stack
- **Memory**: Progress files (.claude/claude-progress.json) persist state

### Implementation

```
┌─────────────────────────────────────────────┐
│              AUGMENTED LLM                   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │              LLM CORE               │   │
│  │                                     │   │
│  │  Reasoning, Generation, Planning    │   │
│  │                                     │   │
│  └──────────────────┬──────────────────┘   │
│                     │                       │
│    ┌────────────────┼────────────────┐     │
│    │                │                │     │
│    ▼                ▼                ▼     │
│ ┌──────┐       ┌──────┐        ┌──────┐   │
│ │Tools │       │Memory│        │Retrieval│ │
│ │      │       │      │        │       │  │
│ │Bash  │       │JSON  │        │Glob   │  │
│ │Edit  │       │Files │        │Grep   │  │
│ │Write │       │      │        │Read   │  │
│ └──────┘       └──────┘        └──────┘   │
│                                             │
└─────────────────────────────────────────────┘
```

### Key Principles

- Tools must have clear documentation and interfaces
- Memory should be structured (JSON preferred over free text)
- Retrieval should be targeted, not exhaustive

---

## Pattern Composition in SDD Toolkit

The real power comes from combining patterns:

### /sdd Command Pattern Composition

```
/sdd "Add OAuth login"

1. PROMPT CHAINING
   Phase 1 → Phase 2 → Phase 3 → ... → Phase 7

2. ROUTING (within phases)
   Input type → appropriate agent

3. PARALLELIZATION (Phase 2, 4, 6)
   Multiple code-explorers in parallel
   Multiple reviewers in parallel

4. ORCHESTRATOR-WORKERS (throughout)
   Main agent coordinates all subagents
   Never does work itself

5. EVALUATOR-OPTIMIZER (Phase 6)
   Quality review with iteration

6. AUGMENTED LLM (all agents)
   Tools, memory, retrieval for each agent
```

### Pattern Selection Guide

| Scenario | Primary Pattern | Supporting Patterns |
|----------|-----------------|---------------------|
| New feature | Prompt Chaining | Orchestrator-Workers, Parallelization |
| Code review | Parallelization | Routing (by file type) |
| Bug fix | Prompt Chaining | Evaluator-Optimizer (verify fix) |
| Architecture | Orchestrator-Workers | Parallelization (multiple perspectives) |
| Optimization | Evaluator-Optimizer | Augmented LLM (profiling tools) |

## When NOT to Use Agents

From Anthropic:

> "For many applications, optimizing single LLM calls with retrieval and in-context examples is usually enough."

Use simpler approaches when:
- Task is well-defined with single correct answer
- Latency is critical
- Cost must be minimized
- Single context window is sufficient

## Rules

- ALWAYS start with the simplest pattern that could work
- ALWAYS combine patterns thoughtfully, not reflexively
- NEVER add complexity without clear benefit
- ALWAYS document which patterns are being used and why
- NEVER let agents operate without appropriate guardrails
