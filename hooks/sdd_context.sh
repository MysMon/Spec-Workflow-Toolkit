#!/bin/bash
# SessionStart Hook: Inject SDD context, detect progress files, and support resumable workflows
# This hook runs once at session start to provide plugin context to the user's project
# Based on:
# - https://www.anthropic.com/engineering/claude-code-best-practices
# - https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents

# --- Progress File Detection ---
PROGRESS_FILE=""
FEATURE_FILE=""
RESUMPTION_INFO=""

# Check for progress tracking files
if [ -f ".claude/claude-progress.json" ]; then
    PROGRESS_FILE=".claude/claude-progress.json"
elif [ -f "claude-progress.json" ]; then
    PROGRESS_FILE="claude-progress.json"
fi

if [ -f ".claude/feature-list.json" ]; then
    FEATURE_FILE=".claude/feature-list.json"
elif [ -f "feature-list.json" ]; then
    FEATURE_FILE="feature-list.json"
fi

# Extract resumption context if progress file exists
if [ -n "$PROGRESS_FILE" ]; then
    # Try to extract key information using basic tools
    if command -v python3 &> /dev/null; then
        RESUMPTION_INFO=$(python3 -c "
import json
import sys
try:
    with open('$PROGRESS_FILE', 'r') as f:
        data = json.load(f)
    ctx = data.get('resumptionContext', {})
    status = data.get('status', 'unknown')
    current = data.get('currentTask', 'None')
    position = ctx.get('position', 'Not specified')
    next_action = ctx.get('nextAction', 'Not specified')
    blockers = ctx.get('blockers', [])

    print(f'Status: {status}')
    print(f'Current Task: {current}')
    print(f'Position: {position}')
    print(f'Next Action: {next_action}')
    if blockers:
        print(f\"Blockers: {', '.join(blockers)}\")
except Exception as e:
    print(f'Error reading progress: {e}')
" 2>/dev/null)
    fi
fi

# Extract feature progress if feature file exists
FEATURE_PROGRESS=""
if [ -n "$FEATURE_FILE" ]; then
    if command -v python3 &> /dev/null; then
        FEATURE_PROGRESS=$(python3 -c "
import json
try:
    with open('$FEATURE_FILE', 'r') as f:
        data = json.load(f)
    total = data.get('totalFeatures', len(data.get('features', [])))
    completed = data.get('completed', 0)
    features = data.get('features', [])

    # Count statuses
    pending = sum(1 for f in features if f.get('status') == 'pending')
    in_progress = sum(1 for f in features if f.get('status') == 'in_progress')
    done = sum(1 for f in features if f.get('status') == 'completed')

    print(f'Total: {total} | Completed: {done} | In Progress: {in_progress} | Pending: {pending}')

    # Show current in-progress feature
    current = [f for f in features if f.get('status') == 'in_progress']
    if current:
        print(f\"Current: {current[0].get('name', 'Unknown')}\")
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null)
    fi
fi

# --- Output Context ---
cat << 'EOF'
## SDD Toolkit v8.1 - Session Initialized

### Core Principles (Spec-First Development)

1. **No Code Without Spec** - Never implement without approved specification
2. **Ambiguity Tolerance Zero** - If unclear, ask immediately using AskUserQuestion
3. **Protect Main Context** - Delegate complex work to subagents to preserve tokens

### Context Management (Critical for Long Sessions)

**ALWAYS delegate to subagents** for multi-step or exploratory work:
- Subagents run in isolated context windows
- Only results/summaries return to main context
- Main orchestrator stays clean and focused

| Task Type | Delegate To | Model | Why |
|-----------|-------------|-------|-----|
| Codebase Exploration | `code-explorer` | Sonnet | Deep 4-phase analysis |
| Requirements | `product-manager` | Sonnet | Exploration isolated |
| System Design | `system-architect` | **Opus** | Complex reasoning for ADRs |
| Feature Design | `code-architect` | Sonnet | Implementation blueprints |
| Frontend | `frontend-specialist` | inherit | Uses your session model |
| Backend | `backend-specialist` | inherit | Uses your session model |
| Testing | `qa-engineer` | Sonnet | Test execution isolated |
| Security | `security-auditor` | Sonnet | Audit (read-only) |

### Long-Running Task Support (Initializer + Coding Pattern)

Based on [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

**Two-Role Pattern:**
| Role | When | Responsibility |
|------|------|----------------|
| **Initializer** | First session, no progress file | Create progress files, break down features, set up state |
| **Coding** | Progress file exists | Read progress, implement ONE feature, test, update progress |

**CRITICAL**: Focus on ONE feature at a time. Avoid trying to do too much at once.

**State Files:**
- `.claude/claude-progress.json` - Progress log with resumption context
- `.claude/feature-list.json` - Feature/task status tracking

**TodoWrite Integration:**
1. Read feature-list.json to populate TodoWrite
2. Mark todos as you work (only ONE in_progress at a time)
3. Update JSON files at milestones
4. Mark complete IMMEDIATELY (don't batch)

### Available Commands

| Command | Use When |
|---------|----------|
| `/sdd` | New features, complex changes (7-phase workflow) |
| `/spec-review` | Validate specifications before implementation |
| `/code-review` | Review code before committing (parallel agents) |
| `/quick-impl` | Small, clear tasks with obvious scope |

### Parallel Agent Execution

For independent reviews or analyses, launch multiple agents simultaneously:
```
Launch these agents in parallel:
1. code-explorer - Trace execution paths (very thorough)
2. qa-engineer - Test coverage analysis
3. security-auditor - Security review (read-only)
```

### Quick Reference

- **Specs location**: `docs/specs/[feature-name].md`
- **Progress files**: `.claude/claude-progress.json`, `.claude/feature-list.json`
- **Use `/clear`** frequently between major tasks
- **Ask questions** rather than assume requirements
- **Confidence threshold**: 80% (only report issues >= 80 confidence)

EOF

# --- Output Resumption Context if Available ---
if [ -n "$PROGRESS_FILE" ]; then
    echo ""
    echo "### Resumable Work Detected"
    echo ""
    echo "**Progress File**: \`$PROGRESS_FILE\`"
    if [ -n "$FEATURE_FILE" ]; then
        echo "**Feature File**: \`$FEATURE_FILE\`"
    fi
    echo ""
    if [ -n "$RESUMPTION_INFO" ]; then
        echo "**Resumption Context:**"
        echo "\`\`\`"
        echo "$RESUMPTION_INFO"
        echo "\`\`\`"
    fi
    if [ -n "$FEATURE_PROGRESS" ]; then
        echo ""
        echo "**Feature Progress:**"
        echo "\`\`\`"
        echo "$FEATURE_PROGRESS"
        echo "\`\`\`"
    fi
    echo ""
    echo "To resume: Read the progress file and continue from the documented position."
    echo ""
fi
