---
name: error-recovery
description: |
  Error handling, checkpoint management, and recovery patterns for resilient agent workflows.
  Based on Anthropic's guidance for long-running agents and graceful degradation.

  Use when:
  - Implementing complex workflows that may fail
  - Need checkpoint/resume capabilities
  - Handling tool failures gracefully
  - Managing agent errors and retries
  - Building robust automation

  Trigger phrases: error handling, recovery, checkpoint, resume, graceful degradation, retry, fallback
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, TodoWrite
model: sonnet
user-invocable: true
---

# Error Recovery Patterns

Strategies for building resilient agent workflows that handle errors gracefully, checkpoint progress, and enable recovery from failures.

From Building Effective Agents:

> "Agents should gain ground truth from the environment at each step (such as tool call results or code execution) to assess its progress."

> "Agents can then pause for human feedback at checkpoints or when encountering blockers."

## Core Principles

### 1. Fail Fast, Recover Quickly

Detect errors early, checkpoint frequently, resume from last known good state.

### 2. Ground Truth Verification

Always verify the result of each action before proceeding to the next.

### 3. Graceful Degradation

When ideal path fails, fall back to alternative approaches rather than complete failure.

## Checkpoint System

### When to Checkpoint

| Event | Checkpoint Action |
|-------|------------------|
| Feature completed | Update feature-list.json, commit |
| Significant file change | Update progress log |
| Before risky operation | Document current state |
| After successful test | Record passing state |
| Before external API calls | Save request context |

### Checkpoint Format

```json
{
  "checkpointId": "CP-001",
  "timestamp": "2025-01-16T14:30:00Z",
  "position": {
    "phase": "Implementation",
    "feature": "F003",
    "step": "Writing AuthService"
  },
  "state": {
    "filesModified": ["src/services/auth.ts"],
    "testsStatus": "passing",
    "lastSuccessfulAction": "Created AuthService class"
  },
  "recovery": {
    "nextAction": "Add login method to AuthService",
    "dependencies": ["User model exists", "Database connected"],
    "rollbackTo": "git commit abc123"
  }
}
```

### Checkpoint Implementation

```markdown
## After each significant action:

1. **Verify Success**
   - Check tool output for errors
   - Run quick validation (lint, type check)
   - Confirm file was written correctly

2. **Record State**
   - Update .claude/workspaces/{workspace-id}/claude-progress.json
   - Add entry to progress log
   - Note files modified

3. **Document Recovery Path**
   - What to do if next step fails
   - How to roll back if needed
   - Dependencies for resumption
```

## Error Categories and Responses

### Category 1: Transient Errors

Temporary failures that may succeed on retry.

| Error Type | Example | Response |
|------------|---------|----------|
| Network timeout | API call failed | Retry with exponential backoff |
| Rate limiting | Too many requests | Wait and retry |
| Temporary file lock | File in use | Wait briefly, retry |

**Retry Strategy:**

```
max_retries = 3
base_delay = 1s

for attempt in 1..max_retries:
    result = try_operation()
    if success:
        return result
    wait(base_delay * 2^attempt)

escalate_to_user("Operation failed after 3 retries")
```

### Category 2: Recoverable Errors

Errors that require different approach but can be handled.

| Error Type | Example | Response |
|------------|---------|----------|
| File not found | Expected file missing | Search for alternatives |
| Permission denied | Can't write to directory | Request user permission |
| Dependency missing | Package not installed | Install or use alternative |
| Test failure | New code breaks test | Analyze failure, fix code |

**Recovery Strategy:**

```markdown
1. Log the error with full context
2. Analyze root cause
3. Determine alternative approach
4. If alternative exists:
   - Document deviation from original plan
   - Execute alternative
   - Verify success
5. If no alternative:
   - Document blocker
   - Ask user for guidance
```

### Category 3: Fatal Errors

Errors that require human intervention.

| Error Type | Example | Response |
|------------|---------|----------|
| Authentication required | Missing API key | Ask user to provide |
| Data corruption | Invalid state | Stop and alert user |
| Security concern | Suspicious operation | Halt and report |
| Scope creep | Request exceeds boundaries | Clarify with user |

**Fatal Error Protocol:**

```markdown
1. STOP all operations immediately
2. Checkpoint current state
3. Document error with full context:
   - What was attempted
   - What failed
   - Current state of files
   - Potential impact
4. Present clear options to user:
   - Fix and continue
   - Roll back and retry
   - Abort workflow
```

## Graceful Degradation Patterns

### Pattern 1: Fallback Chain

Try primary approach, fall back to alternatives.

```
Primary: Use preferred library
   │
   └─ (failed) ─▶ Fallback 1: Use alternative library
                      │
                      └─ (failed) ─▶ Fallback 2: Manual implementation
                                          │
                                          └─ (failed) ─▶ Ask user
```

### Pattern 2: Partial Success

Complete what's possible, report what's not.

```markdown
## Partial Success Report

### Completed (3/5 features)
- [x] User registration
- [x] User login
- [x] Password reset

### Failed (2/5 features)
- [ ] OAuth integration - Error: Missing client_id
- [ ] 2FA - Error: SMS provider not configured

### Next Steps
1. Provide OAuth client_id in .env
2. Configure SMS provider in settings
3. Re-run /sdd for remaining features
```

### Pattern 3: Safe Mode

Continue with reduced functionality when errors occur.

```markdown
Normal Mode:
- Full implementation with all features
- Complete test coverage
- Performance optimization

Safe Mode (on error):
- Core functionality only
- Basic tests
- Skip optimization
- Document what was skipped for later
```

## Recovery Workflows

### Workflow 1: Resume After Crash

```markdown
1. Identify current workspace ID (branch + path hash)
2. Read .claude/workspaces/{workspace-id}/claude-progress.json
3. Identify last checkpoint:
   - Position: "Phase 5, Feature F003, step 2"
   - Last action: "Created AuthService class"
   - Next action: "Add login method"
4. Verify file state:
   - Run `git status` to check uncommitted changes
   - Compare files to checkpoint expectation
5. If state is valid:
   - Continue from documented next action
6. If state is corrupted:
   - Roll back to last commit: `git checkout -- .`
   - Resume from that checkpoint
```

### Workflow 2: Test Failure Recovery

```markdown
1. Test fails after implementation
2. Analyze failure:
   - Read error message
   - Identify failing assertion
   - Trace to code change
3. Determine fix:
   - If bug in new code: Fix and re-run
   - If bug in test: Review test expectations
   - If design issue: Consult architect
4. Apply fix
5. Run full test suite
6. Update checkpoint only when all tests pass
```

### Workflow 3: Merge Conflict Recovery

```markdown
1. Conflict detected during pull/merge
2. Checkpoint current branch state
3. Analyze conflicts:
   - List conflicting files
   - Understand both versions
4. Resolve conflicts:
   - For each file, decide correct version
   - Test resolution locally
5. Commit resolution
6. Continue workflow
```

## Integration with Progress Tracking

### Error Logging in Progress File

```json
{
  "log": [
    {
      "timestamp": "2025-01-16T14:30:00Z",
      "action": "Attempted OAuth integration",
      "status": "failed",
      "error": {
        "type": "ConfigurationError",
        "message": "Missing OAUTH_CLIENT_ID in environment",
        "recoverable": true,
        "resolution": "User must provide OAuth credentials"
      }
    }
  ],
  "blockers": [
    {
      "id": "B001",
      "description": "OAuth credentials required",
      "status": "waiting_for_user",
      "createdAt": "2025-01-16T14:30:00Z"
    }
  ]
}
```

### Blocker Management

```markdown
## Blocker Protocol

1. **Detect**: Identify that progress is blocked
2. **Document**: Add to blockers array in progress file
3. **Notify**: Inform user with clear description
4. **Wait**: Do not proceed past blocker
5. **Resolve**: Once user provides resolution:
   - Mark blocker as resolved
   - Log resolution action
   - Continue workflow

## Blocker States

| State | Meaning |
|-------|---------|
| waiting_for_user | User input/action required |
| investigating | Analyzing potential solutions |
| resolved | Blocker cleared |
| escalated | Requires external help |
```

## Claude Code Specific Features

### Using Checkpoints

Claude Code automatically creates checkpoints before each edit.

- **Safe experimentation**: Try approaches without fear
- **Use `/rewind`**: Roll back to previous state if needed
- **Esc twice**: Cancel current operation and discuss

### Recovery Commands

| Command | Use When |
|---------|----------|
| `/rewind` | Need to undo recent changes |
| `/clear` | Context too polluted, restart clean |
| `git checkout -- file` | Discard specific file changes |
| `git stash` | Temporarily save work in progress |

## Anti-Patterns

| Anti-Pattern | Why Bad | Instead |
|--------------|---------|---------|
| Ignoring errors | Problems compound | Handle immediately |
| No checkpoints | Can't recover | Checkpoint frequently |
| Retry without backoff | May worsen issue | Use exponential backoff |
| Silent failures | Problems hidden | Always log and report |
| Continuing past blockers | Invalid state | Stop and resolve |

## Rules (L1 - Hard)

Critical for reliable recovery and data safety.

- ALWAYS checkpoint before risky operations (enables rollback)
- ALWAYS verify success after each significant action (ground truth)
- NEVER ignore error messages or warnings (problems compound)
- NEVER continue past a blocker without user confirmation
- NEVER lose work - commit early and often

## Defaults (L2 - Soft)

Important for operational quality. Override with reasoning when appropriate.

- Document errors with full context (aids debugging)
- Provide recovery options when reporting errors
- Use exponential backoff for retries
- Log all failure attempts with timestamps

## Guidelines (L3)

Recommendations for robust error handling.

- Consider testing recovery paths during development
- Prefer graceful degradation over complete failure
- Consider using Claude Code's `/rewind` for quick rollbacks
