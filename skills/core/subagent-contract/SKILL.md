---
name: subagent-contract
description: |
  Standardized communication protocol for orchestrators AND subagents.
  Defines rules, responsibilities, and result formats for the delegation system.

  Use when:
  - Writing or maintaining command files (orchestrator rules)
  - Defining new subagent behaviors (subagent rules)
  - Aggregating results from multiple agents
  - Understanding delegation constraints
  - Handling agent failures (error handling section)

  Trigger phrases: subagent format, agent output, result format, orchestrator rules, delegation protocol

  This skill defines the CONTRACT between orchestrator and subagents - both sides.
allowed-tools: Read
model: sonnet
user-invocable: false
---

# Subagent Communication Contract

A standardized protocol for subagent inputs, outputs, and error handling to ensure consistent orchestration.

## Why Standardization Matters

From Claude Code Best Practices:

> "Subagents use their own isolated context windows, and only send relevant information back to the orchestrator."

Standardized formats enable:
- Efficient aggregation of multiple agent outputs
- Consistent error handling
- Predictable parsing and processing
- Clear expectations for both agents

## Result Format Specification

### Universal Result Structure

All subagent results MUST follow this structure:

```markdown
## [Agent Name] Result

### Status
[SUCCESS | PARTIAL | FAILED]

### Summary
[2-3 sentence summary of what was accomplished or found]

### Findings
[Structured content specific to agent type - see below]

### Key References
| Item | Location | Relevance |
|------|----------|-----------|
| [Name] | `file:line` | [Why important] |

### Confidence
[0-100] - [Brief justification]

### Issues (if any)
- [Issue 1]: [Description] | Severity: [critical/important/minor]
- [Issue 2]: [Description] | Severity: [critical/important/minor]

### Next Steps (if applicable)
1. [Recommended action 1]
2. [Recommended action 2]

### Blockers (if any)
- [Blocker description] | Resolution: [What's needed]
```

## Agent-Specific Formats

See `reference.md` for detailed examples for each agent type:
- Exploration Agents (code-explorer, Explore)
- Design Agents (code-architect, system-architect)
- Review Agents (qa-engineer, security-auditor)
- Implementation Agents (frontend-specialist, backend-specialist)
- Error Result Format

## Confidence Score Guidelines

| Score | Meaning | Evidence Required |
|-------|---------|-------------------|
| 95-100 | Certain | Direct code evidence, verified by execution |
| 85-94 | High | Clear code evidence, consistent patterns |
| 75-84 | Moderate | Some evidence, reasonable inference |
| 60-74 | Low | Limited evidence, assumptions made |
| <60 | Uncertain | Speculation, should request clarification |

## Aggregation Protocol

When orchestrator receives multiple subagent results:

### 1. Status Aggregation

```
All SUCCESS → Continue to next phase
Any FAILED → Handle error, possibly retry
Any PARTIAL → Review findings, decide path
```

### 2. Issue Deduplication

```
Same file:line + same category → Keep highest confidence
Multiple agents report same issue → Boost confidence +10 (max 100)
Conflicting findings → Flag for human review
```

### 3. Confidence Weighting

```
Combined confidence = weighted average by agent expertise

Example:
- security-auditor says SEC-001 (conf: 95)
- qa-engineer also flags (conf: 78)
- Combined: (95 + 78) / 2 + 10 (agreement bonus) = 96.5
```

## Rules for Orchestrators

The orchestrator (command executor) has specific responsibilities and constraints to maintain efficient context usage and delegation consistency.

### Rules (L1 - Hard)

Critical for context protection and delegation consistency.

- **MUST delegate bulk Grep/Glob operations to `code-explorer`** - Use directly only for single targeted lookups (≤3 files)
- **NEVER read more than 3 files directly** - Delegate bulk reading to subagents
- **NEVER implement code yourself** - Delegate to specialist agents (frontend-specialist, backend-specialist, qa-engineer)
- **NEVER write tests yourself** - Delegate to `qa-engineer`
- **NEVER do security analysis yourself** - Delegate to `security-auditor`
- **NEVER edit spec/design files directly** - Delegate to `product-manager` (exception: TRIVIAL edits, see below)
- **ALWAYS wait for subagent completion** before synthesizing results
- **ALWAYS use subagent output** for context - do not re-read files the subagent already analyzed

### Quick Lookup Definition (L1 - Required)

**Quick lookup** is the ONLY direct file read allowed for orchestrators. ALL conditions must be met:

| Criterion | Limit | Rationale |
|-----------|-------|-----------|
| **File count** | ≤3 files | Beyond 3 files = delegate to agent |
| **Line count per file** | ≤200 lines | Beyond 200 lines = delegate to agent |
| **Total lines read** | ≤300 lines | Aggregate limit for context protection |
| **Purpose** | Single value/section confirmation | NOT analysis, NOT comprehension |
| **Time** | <10 seconds | If longer, should have been delegated |

**Examples of quick lookups (ALLOWED):**
- Confirming a timeout value: "What's the CACHE_TTL setting?"
- Checking a specific function exists: "Is `validateEmail` defined here?"
- Verifying acceptance criteria for ONE feature
- Reading a single config section

**Examples that are NOT quick lookups (MUST DELEGATE):**
- Understanding overall architecture
- Analyzing trade-offs or design decisions
- Identifying integration points across features
- Reading multiple related files for context
- Summarizing a document

**Unified line limits across commands:**
| Context | Direct Read Limit |
|---------|-------------------|
| Fallback after agent failure | ≤200 lines per file, ≤3 files |
| Quick reference during phase | ≤200 lines per file, ≤3 files |
| Progress/metadata files | No limit (not project content) |
| Presentation to user | ≤300 lines total (show, don't analyze) |

### TRIVIAL Edit Definition (L1 - Required)

**TRIVIAL edit** is the ONLY direct spec/design edit allowed for orchestrators. ALL conditions must be met:

| Criterion | Requirement | Rationale |
|-----------|-------------|-----------|
| **Line count** | ≤2 lines | Beyond 2 lines = delegate to product-manager |
| **Semantic impact** | None | Meaning must be identical before and after |
| **Judgment required** | None | Change must be obvious correction |

**Examples of TRIVIAL edits (ALLOWED with delegation-first):**

| Change Type | Example | Why TRIVIAL |
|-------------|---------|-------------|
| Typo fix | "recieve" → "receive" | Spelling error, meaning unchanged |
| Version metadata | "1.0.0" → "1.0.1" | Metadata update, no behavior change |
| Date metadata | "2025-01-01" → "2025-01-31" | Metadata update |
| Formatting only | Fix markdown bullet indent | Visual only, no content change |

**Examples that are NOT TRIVIAL (MUST delegate to product-manager):**

| Change Type | Example | Why NOT TRIVIAL |
|-------------|---------|-----------------|
| Numeric values | `timeout: 30` → `timeout: 60` | May affect implementation behavior |
| Wording strength | "should" → "must" | Changes requirement strength |
| Content addition | Adding a new bullet point | New requirement |
| Clarification | "Fast response" → "Response under 100ms" | Adds specificity |

**Gray zone - ALWAYS delegate to product-manager:**
- Any numeric value change (even small: `maxRetries: 3` → `maxRetries: 5`)
- Removing "(optional)" from a field
- Word changes that could shift meaning ("error message" → "error notification")

**Execution preference:**
1. **Default**: Delegate to `product-manager` (delegation-first principle)
2. **Fallback**: Direct edit ONLY if:
   - User explicitly requests direct edit for speed
   - Agent retry failed (after one retry attempt)
   - Change is purely formatting (whitespace, markdown syntax only)

**Post-edit verification (required):**
- Run `git diff` to confirm only intended lines changed
- If more lines affected, warn user and offer to revert

**Rule of thumb:** If the change affects any numeric value or could influence implementation behavior, delegate to product-manager. When in doubt, always delegate.

See `spec-revise.md` for detailed examples and phase-specific handling.

### Defaults (L2 - Soft)

Important for orchestration quality. Override with reasoning when appropriate.

- Launch parallel agents when tasks are independent
- Use appropriate model for agent tasks (haiku for simple lookups, sonnet for analysis, opus for complex PRD)
- Present subagent results to user before proceeding to next phase
- Update progress files at each phase completion

### Guidelines (L3)

Recommendations for effective orchestration.

- Consider splitting large tasks across multiple agents
- Prefer asking user questions over guessing intent
- Document agent failures in progress files for debugging

### Orchestrator Responsibilities

The orchestrator's ONLY responsibilities are:

1. **Orchestrate** - Launch and coordinate subagents
2. **Synthesize** - Combine subagent outputs into coherent summaries
3. **Communicate** - Present findings and ask user questions
4. **Track Progress** - Update TodoWrite and progress files
5. **Verify Minimally** - Read specific files identified by subagents (max 3 at a time) only when necessary

### Error Handling for Orchestrators

When a subagent fails or times out:

1. **Check partial output** for usable findings
2. **Retry once** with reduced scope if critical
3. **Fallback to direct read** if context-loading agent fails (see below)
4. **Proceed with available results** if non-critical, documenting the gap
5. **Escalate to user** if critical agent fails after retry

Add to progress file when agents fail:
```json
"warnings": ["Agent X failed, results may be incomplete"]
```

### Fallback Mechanism (L1 - Required)

**Why fallback is mandatory:**
1. **Resilience**: Users should not be blocked by agent timeouts
2. **Graceful degradation**: Partial progress is better than total failure
3. **Consistency**: All commands use the same error recovery pattern

**Fallback rules:**
- **Primary path**: Always delegate to agent first
- **Fallback trigger**: Agent timeout OR failure after retry
- **Fallback action**: Direct file read (≤3 files, ≤200 lines each)
- **Documentation**: Warn user and log in progress file

**Anti-pattern (NEVER do this):**
```markdown
# BAD: Skip agent based on task clarity
If task is clear → Read file directly, skip agent

# GOOD: Agent first, fallback second
Always → Delegate to agent
If agent fails → Fallback to direct read + warn user
```

**Why delegation-first, not direct-read-first:**
1. **Context Protection**: Agent reads don't consume orchestrator context
2. **Consistency**: Same pattern across all commands
3. **Expertise**: Agents apply stack-detector and pattern recognition
4. **Fallback Safety**: Direct read is safety net, not primary path

### Orchestrator Exceptions Reference (L1)

All orchestrator exceptions to the delegation-first principle are defined here. Commands should reference this section instead of duplicating explanations.

| Exception | Conditions | Context Cost | Alternative Cost | Justification |
|-----------|------------|--------------|------------------|---------------|
| **Quick Lookup** | ≤3 files, ≤200 lines/file, ≤300 total | ~100 tokens | ~700 tokens (agent) | Single value confirmation doesn't warrant agent overhead |
| **Fallback Read** | After agent timeout/failure + 1 retry | ~200 tokens | User blocked | Resilience: users must not be blocked by agent failures |
| **TRIVIAL Edit** | ≤2 lines, no semantic impact, no judgment | ~50 tokens | ~1000 tokens (agent) | Obvious corrections don't warrant agent overhead |
| **Progress/Metadata Read** | Orchestrator state files only | ~30 tokens | ~500 tokens (agent) | Not project content; orchestrator's own state |

**Common principle:** All exceptions follow delegation-first. Direct action is fallback, not primary path.

**When exceptions apply:**
1. Exceptions are **allowed**, not **required** - delegation is always acceptable
2. Exceptions require **all conditions met** - partial match = delegate
3. Exceptions require **post-action verification** - confirm scope was as expected

**Anti-patterns to avoid:**
- Using exceptions to skip agents for convenience
- Applying exceptions without verifying all conditions
- Not documenting when exceptions were used

---

## Rules for Subagents

### Rules (L1 - Hard)

Critical for orchestration consistency and context protection.

- ALWAYS use the standardized result format (enables aggregation)
- NEVER exceed ~500 tokens for summaries (context protection critical)
- ALWAYS report blockers that prevent completion (orchestrator needs to know)
- ALWAYS complete Pre-Submission Verification checklist before returning results (see below)
- ALWAYS verify file:line references exist before submitting (prevents hallucinations)
- NEVER submit results with hallucinated file paths or line numbers
- MUST include confidence breakdown (verified_confidence + inferred_confidence) when confidence >= 75

### Defaults (L2 - Soft)

Important for quality and usability. Override with reasoning when appropriate.

- Include file:line references for all findings (aids navigation)
- Provide confidence scores with justification (enables prioritization)
- Summarize exploration results, don't return raw output
- Categorize issues by severity (critical/important/minor)

### Guidelines (L3)

Recommendations for better results.

- Include next steps when applicable
- Suggest recovery options for errors
- Note trade-offs considered in design decisions
- Reference patterns found for architectural consistency

## Self-Verification Checklist
Before submitting results, subagents MUST verify their output quality to prevent hallucinations and ensure accuracy.

### Pre-Submission Verification (L1 - Required)

All subagents must complete this checklist before returning results:

```markdown
### Verification Completed
- [ ] **File References Valid**: All `file:line` references have been verified to exist
- [ ] **Code Snippets Accurate**: Any quoted code matches the actual file content
- [ ] **No Hallucinated Paths**: No file paths were assumed or invented
- [ ] **Evidence Documented**: Each finding has supporting evidence cited
```

### Confidence Breakdown (L1 Required for confidence >= 75)

Report confidence as two components:
- **verified_confidence**: Based on direct code evidence (file read, test output)
- **inferred_confidence**: Based on pattern analysis and reasonable assumptions
- **combined_confidence**: (verified + inferred) / 2

Example:
- verified_confidence: 90 (read the exact function, saw the bug)
- inferred_confidence: 70 (similar pattern likely exists elsewhere)
- combined_confidence: 80

### Confidence Justification (L2 - Required for Confidence >= 85)

When reporting high confidence (85+), provide explicit justification:

```markdown
### Confidence Justification
**Score**: [X]
**Evidence Count**: [N findings with direct code evidence]
**Verification Method**: [How findings were verified]
**Potential Blind Spots**: [What might have been missed]
```

### Cross-Verification Triggers (L2)

Request additional verification when:

| Condition | Action |
|-----------|--------|
| Single source of evidence | Flag as "needs corroboration" |
| Conflicting findings | Escalate to orchestrator |
| Confidence < 70 | Include "Uncertainty" section |
| Security-related finding | Require code evidence |

### Anti-Hallucination Practices

1. **Never invent file paths** - If unsure, use Glob/Grep to verify
2. **Never quote code without reading** - Always Read the file first
3. **Never assume implementation details** - Verify with actual code
4. **Flag uncertainty explicitly** - Use "uncertain" or "assumed" labels

### Example: Verified vs Unverified Output

**Unverified (BAD)**:
```
Found authentication in src/auth/login.ts:45
```

**Verified (GOOD)**:
```
Found authentication in src/auth/login.ts:45
- Verified: Read tool confirmed file exists
- Code match: `export async function authenticate()`
- Confidence: 95 (direct code evidence)
```
