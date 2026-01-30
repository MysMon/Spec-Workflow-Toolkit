---
description: "Quick implementation for well-defined, small tasks that don't need the full plan→review→implement flow"
argument-hint: "<task description>"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, TodoWrite
---

# /quick-impl - Quick Implementation

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

For small, well-defined tasks that don't require the full plan→review→implement flow. Use when:
- Task is clearly defined (not vague)
- Scope is small (1-3 files)
- No architectural decisions needed
- Risk is low

## Guardrails

Even quick implementations follow core principles:

1. **Understand before coding** - Read related files first
2. **Test your changes** - Run existing tests, add if needed
3. **Security check** - No secrets, no vulnerabilities
4. **Quality check** - Lint/format after changes

## Execution Instructions

### Step 1: Validate Scope (MUST DO BEFORE ANY IMPLEMENTATION)

**CRITICAL (L1): Validate scope BEFORE starting any work.**

Check if this is actually a quick task:

**Proceed ONLY if ALL criteria are met:**
- [ ] Task is clearly defined in `$ARGUMENTS`
- [ ] Affects 3 or fewer files
- [ ] No database schema changes
- [ ] No API contract changes
- [ ] No security-sensitive code

**MUST escalate to /spec-plan if ANY of these apply:**
- Task is vague or ambiguous
- Multiple components affected
- Architectural decisions needed
- Security implications

**MUST use AskUserQuestion if task is unclear:**

| User Says | Ask About |
|-----------|-----------|
| "Fix the bug" | Which bug? Where? What's the expected behavior? |
| "Add validation" | Which field? What rules? What error messages? |
| "Improve this" | Improve what aspect? Performance? UX? Readability? |
| "Make it work" | What's broken? What's the expected behavior? |

**NEVER proceed with vague tasks — clarify first.**

### Step 2: Context Gathering

Before implementing:

1. **Detect stack** (via Task tool with subagent_type=Explore, or read config files like package.json, pyproject.toml)
2. **Read related files** - Understand existing code
3. **Check for tests** - Know what to update

```
Launch Task tool with subagent_type=Explore (quick mode) to find:
- Files related to [task]
- Existing patterns for similar functionality
- Test files to update
```

### Step 3: Implementation

**IMPORTANT:** ALWAYS delegate implementation to appropriate specialist agent.

```
Launch Task tool with appropriate specialist (model: haiku for simple tasks):

- Frontend code → frontend-specialist
- Backend code → backend-specialist
- Tests → qa-engineer

Prompt:
Quick implementation task.
Task: [task description]
Files: [related files]
Patterns: [existing patterns to follow]
Test file: [path if applicable]

Constraints:
- Follow existing code patterns
- Minimal change scope
```

**Direct modification allowed ONLY for:**
- Single-line typo fixes in comments or strings
- Single config value changes (e.g., timeout: 30 → timeout: 60)
- Import statement additions (single line)

**Examples of what requires delegation:**
- Any logic changes (even "simple" ones)
- Multiple file modifications
- New functions, classes, or modules
- API or interface changes

### Step 4: Verification

Quick verification checklist:

```bash
# Run linters (auto-detected)
# Run tests
npm test  # or pytest, go test, cargo test, etc.

# Check for secrets
# (automatic via prevent_secret_leak hook)
```

### Step 5: Summary

Brief summary:
- What was changed
- Files modified
- Tests status
- Any follow-up needed

## Usage Examples

```bash
# Fix a typo
/quick-impl Fix typo in README.md - "recieve" should be "receive"

# Add a config value
/quick-impl Add CACHE_TTL environment variable with default 3600

# Simple refactor
/quick-impl Rename getUserById to findUserById across the codebase

# Add a simple utility
/quick-impl Add formatCurrency utility function that formats numbers as USD
```

## Escalation Triggers

**CRITICAL (L1): STOP immediately if any of these occur during implementation:**

- Scope is larger than expected (more files affected)
- Architectural questions arise
- Security concerns emerge
- Requirements become unclear

**MUST inform the user using AskUserQuestion:**

```
Question: "This task is more complex than initially expected because [reason]. How should we proceed?"
Header: "Escalate"
Options:
- "Switch to /spec-plan for proper planning"
- "Proceed anyway (I understand the risks)"
- "Abandon and reassess requirements"
```

**NEVER continue implementing when scope becomes unclear.**

## Comparison with /spec-plan

| Aspect | /quick-impl | /spec-plan |
|--------|-------------|------------|
| When | Clear, small tasks | Vague or complex features |
| Phases | 1 (implement) | Plan→Review→Implement |
| Spec | Not required | Required |
| Review | Basic checks | Interactive + optional auto review |
| Time | Minutes | Hours to days |
| Risk | Low scope only | Any complexity |

---

## Rules (L1 - Hard)

Critical for preventing scope creep and ensuring safe quick implementations.

- MUST validate scope BEFORE starting implementation (check all criteria in Step 1)
- MUST escalate to `/spec-plan` if:
  - Task is vague or ambiguous
  - Affects more than 3 files
  - Requires architectural decisions
  - Involves security-sensitive code
  - Database schema or API contract changes needed
- NEVER start implementation if scope is ambiguous — use AskUserQuestion first
- MUST use AskUserQuestion when:
  - Task description contains vague terms ("improve", "fix", "make it work")
  - Multiple interpretations of the task are possible
  - Scope boundaries are unclear
- NEVER guess user intent — ask first
- ALWAYS run tests before completing

## Defaults (L2 - Soft)

Important for quality. Override with reasoning when appropriate.

- Delegate non-trivial changes to specialist agents
- Run linter/formatter after changes
- Provide brief summary of changes at completion

## Guidelines (L3)

Recommendations for effective quick implementations.

- Consider detecting stack before implementation
- Prefer reading related files before making changes
