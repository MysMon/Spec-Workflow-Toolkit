---
name: context-engineering
description: |
  Context engineering principles for AI agents based on Anthropic's official guidance.
  Critical for managing long-running sessions and maximizing agent effectiveness.

  Use when:
  - Managing context in long-running sessions
  - Optimizing information flow to agents
  - Designing subagent architectures
  - Understanding why context management matters
  - Preventing "context rot" in extended sessions
allowed-tools: Read, Task
model: sonnet
user-invocable: true
---

# Context Engineering for AI Agents

Based on Anthropic's Effective Context Engineering for AI Agents.

> "Context engineering involves strategically curating tokens available to LLMs to optimize performance within finite attention budgets."

## Core Principle: Context is a Finite Resource

**Critical Insight**: LLMs experience "context rot" - accuracy diminishes as token count increases.

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTEXT WINDOW CAPACITY                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│  ^                  ^                                     ^      │
│  │                  │                                     │      │
│  Start              Context Rot                          Limit   │
│  (100% accuracy)    Begins (~50%)                     (degraded)│
│                                                                  │
│  Every token depletes attention budget like RAM filling up       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Matters for Long-Running Sessions

| Session Length | Without Context Management | With Context Management |
|----------------|---------------------------|------------------------|
| 30 minutes | Works fine | Works fine |
| 2 hours | Starts degrading | Maintains quality |
| 8+ hours | Likely fails | Continues working |

## The Five Principles

### 1. Treat Context as Finite Resource

**Every token counts.** Budget tokens like memory in a computer program.

```
Good: Return 500-token summaries from subagents
Bad: Return full 10,000+ token exploration results to main context
```

**Quantified Impact:**
- Direct orchestrator exploration: 10,000+ tokens consumed
- Subagent exploration with summary: ~500 tokens returned
- **Savings: 95% context preservation**

### 2. Right Altitude for Instructions

Strike a balance between extremes:

| Too Low (Brittle) | Right Altitude | Too High (Vague) |
|-------------------|----------------|------------------|
| "Use exactly 3 spaces" | "Follow existing style" | "Make it good" |
| Breaks on edge cases | Adapts to context | Assumes too much |

**Good example from this toolkit:**
```markdown
## Context Management (CRITICAL)

From Claude Code Best Practices:

> "Subagents use their own isolated context windows..."

YOUR responsibilities:
1. Orchestrate - don't do work yourself
2. Delegate exploration to subagents
3. Only read specific files identified by subagents
```

### 3. Tool Design Efficiency

Create self-contained, unambiguous tools with minimal overlap.

| Principle | Example |
|-----------|---------|
| Single purpose | `code-explorer` = analysis only, no edits |
| Clear boundaries | `qa-engineer` tests, `security-auditor` audits |
| Minimal overlap | Don't have 3 agents that all do "general review" |

**This toolkit's approach:**
- 12 specialized agents with clear domains
- Each agent has specific `tools` and `disallowedTools`
- `permissionMode` enforces boundaries

### 4. Progressive Disclosure

Allow agents to incrementally discover context through exploration.

```
Step 1: Agent receives high-level task description
    ↓
Step 2: Agent explores, discovers relevant files
    ↓
Step 3: Agent reads specific files as needed
    ↓
Step 4: Agent returns focused summary
```

**Not this:**
```
Step 1: Dump entire codebase context upfront
Step 2: Agent drowns in irrelevant information
Step 3: Context rot kicks in
Step 4: Poor results
```

### 5. Just-in-Time Retrieval

Maintain lightweight identifiers, dynamically load data at runtime.

```markdown
## Instead of loading full files:

Store references:
- "AuthService is at src/services/auth.ts:8"
- "JWT config at src/config/jwt.ts:5"

Load on demand:
- When implementing auth, THEN read auth.ts
- When fixing JWT, THEN read jwt.ts
```

## Information Retrieval Strategies

### Strategy 1: Subagent Isolation

```
┌─────────────────────────────────────────────────────────────────┐
│                      MAIN ORCHESTRATOR                           │
│                      (Clean context)                             │
│                                                                  │
│  Receives: 500-token summaries                                   │
│  Maintains: Global plan, compact state                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │Subagent1│    │Subagent2│    │Subagent3│
    │         │    │         │    │         │
    │ Isolated│    │ Isolated│    │ Isolated│
    │ Context │    │ Context │    │ Context │
    │         │    │         │    │         │
    │ 10,000+ │    │ 10,000+ │    │ 10,000+ │
    │ tokens  │    │ tokens  │    │ tokens  │
    │ (local) │    │ (local) │    │ (local) │
    └─────────┘    └─────────┘    └─────────┘
```

### Strategy 2: Structured Note-Taking (Agentic Memory)

Enable agents to maintain persistent notes outside context windows.

**This toolkit implements this via:**
- `.claude/claude-progress.json` - Progress and resumption context
- `.claude/feature-list.json` - Task status tracking
- `git commit` messages - Decision history

```json
// .claude/claude-progress.json
{
  "project": "user-auth",
  "status": "in_progress",
  "currentTask": "Implementing OAuth",
  "resumptionContext": {
    "position": "Phase 5 - OAuth callback handler",
    "nextAction": "Add token exchange logic",
    "keyFiles": [
      "src/services/oauth.ts:45",
      "src/config/oauth.ts:12"
    ],
    "decisions": [
      "Using Authorization Code flow (not Implicit)",
      "Storing tokens in Redis with 24h TTL"
    ]
  }
}
```

### Strategy 3: Compaction

Summarize conversation contents when approaching context limits.

**When to compact:**
- Approaching 50-70% of context window
- PreCompact hook triggers automatically
- After completing major phases

**What to preserve:**
- Architectural decisions
- Key file references (`file:line` format)
- Current progress state
- Blockers and open questions

**What to discard:**
- Full file contents (can be re-read)
- Verbose exploration logs
- Redundant confirmations

## Integration with SDD Toolkit

### SessionStart Hook

The `sdd_context.sh` hook implements context engineering:

1. **Detects progress files** - Restores state without full history
2. **Determines role** - INITIALIZER vs CODING (fresh vs resuming)
3. **Injects compact context** - Key principles, not full documentation

### Subagent Architecture

Every subagent follows context engineering:

```yaml
# Every agent definition includes:
skills: stack-detector, subagent-contract

# subagent-contract enforces:
# - 500-token summary limit
# - Structured output format
# - file:line references
# - Confidence scores
```

### PreCompact Hook

The `pre_compact_save.sh` hook:

1. **Saves progress** to `.claude/claude-progress.json`
2. **Records compaction** timestamp and context
3. **Outputs reminder** for post-compaction recovery

## Context Engineering Checklist

Before starting long-running work:

- [ ] Progress files initialized (`.claude/claude-progress.json`)
- [ ] Feature list created (`.claude/feature-list.json`)
- [ ] Subagent delegation planned (not direct exploration)
- [ ] One feature at a time approach confirmed

During work:

- [ ] Delegating exploration to subagents
- [ ] Receiving summaries, not full results
- [ ] Updating progress files at milestones
- [ ] Using `file:line` references, not full file contents

After compaction:

- [ ] Read progress file to restore context
- [ ] Check feature-list for current status
- [ ] Continue from documented position

## Anti-Patterns

| Anti-Pattern | Why Bad | Instead |
|--------------|---------|---------|
| Loading all files upfront | Context rot | Progressive disclosure |
| Returning full exploration | Pollutes main context | 500-token summaries |
| No progress tracking | Can't resume | JSON state files |
| Direct orchestrator exploration | Context consumption | Delegate to subagents |
| Ignoring compaction | Session fails | Use PreCompact hook |

Delegate exploration to subagents (never explore directly), limit subagent summaries to ~500 tokens, use `file:line` references instead of pasting code, update progress files at milestones, and always read progress files after compaction.
