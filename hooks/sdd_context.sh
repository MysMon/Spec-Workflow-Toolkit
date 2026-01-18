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

# --- Determine Role (Initializer vs Coding) ---
if [ -n "$PROGRESS_FILE" ]; then
    CURRENT_ROLE="CODING"
else
    CURRENT_ROLE="INITIALIZER"
fi

# --- Output Context ---
cat << 'EOF'
## SDD Toolkit v9.0.0 - Session Initialized

**Official References:**
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)

EOF

# --- Role-Specific Banner ---
if [ "$CURRENT_ROLE" = "CODING" ]; then
    cat << 'EOF'
### Current Role: CODING (Resuming Work)

Progress file detected. You are in **Coding Role**:
1. **Read** the progress file to understand current state
2. **Identify** the next incomplete feature/task
3. **Implement** ONE feature at a time (not all at once!)
4. **Test** thoroughly before moving on
5. **Update** progress file after each milestone
6. **Commit** working code with descriptive messages

EOF
else
    cat << 'EOF'
### Current Role: INITIALIZER (First Session)

No progress file detected. You are in **Initializer Role**:
1. **Analyze** the full task scope and break into features
2. **Create** `.claude/claude-progress.json` with project info
3. **Create** `.claude/feature-list.json` with all features (status: pending)
4. **Document** resumption context for future sessions
5. **Start** implementing the first feature

EOF
fi

cat << 'EOF'
### Core Principles (Spec-First Development)

1. **No Code Without Spec** - Never implement without approved specification
2. **Ambiguity Tolerance Zero** - If unclear, ask immediately using AskUserQuestion
3. **Protect Main Context** - Delegate complex work to subagents to preserve tokens

---

### ⚠️ ORCHESTRATOR RULES (NON-NEGOTIABLE)

**YOU ARE THE ORCHESTRATOR. YOU DO NOT DO THE WORK YOURSELF.**

**NEVER do these directly:**
- Use Grep/Glob for exploration (delegate to `code-explorer`)
- Read more than 3 files at once (delegate to subagents)
- Implement code (delegate to `frontend-specialist` or `backend-specialist`)
- Write tests (delegate to `qa-engineer`)
- Do security analysis (delegate to `security-auditor`)

**YOUR responsibilities:**
1. Orchestrate - Launch and coordinate subagents
2. Synthesize - Combine subagent outputs
3. Communicate - Present findings to user
4. Track Progress - Update TodoWrite and progress files

---

### Context Management (CRITICAL for Long Sessions)

From [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices):

> "Subagents use their own isolated context windows, and only send relevant information back to the orchestrator."

**DO NOT explore code yourself. ALWAYS delegate to subagents:**
- Subagents run in isolated context windows
- Only results/summaries return to main context (~500 tokens vs 10,000+)
- Main orchestrator stays clean and focused
- This enables long autonomous work sessions (hours, not minutes)

| Task Type | Delegate To | Model | Why |
|-----------|-------------|-------|-----|
| Codebase Exploration | `code-explorer` | Sonnet | Deep 4-phase analysis |
| Quick Lookups | Built-in `Explore` | Haiku | Fast, lightweight |
| Requirements | `product-manager` | **Opus** | Deep reasoning for ambiguous requests |
| System Design | `system-architect` | **Opus** | Complex reasoning for ADRs |
| Feature Design | `code-architect` | Sonnet | Implementation blueprints |
| Frontend | `frontend-specialist` | inherit | Uses your session model |
| Backend | `backend-specialist` | inherit | Uses your session model |
| Testing | `qa-engineer` | Sonnet | Test execution isolated |
| Security | `security-auditor` | Sonnet | Audit (read-only) |

### Long-Running Task Support (One Feature at a Time)

Based on [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

> "The agent tends to try to do too much at once—essentially attempting to one-shot the app."

**Solution**: Focus on ONE feature, complete it fully, then move to the next.

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

### Composable Patterns Applied

This toolkit implements Anthropic's 6 composable patterns:
- **Prompt Chaining**: 7-phase SDD workflow
- **Routing**: Model/agent selection by task type
- **Parallelization**: Multiple explorers/reviewers simultaneously
- **Orchestrator-Workers**: You coordinate, subagents execute
- **Evaluator-Optimizer**: Quality review with feedback loops
- **Augmented LLM**: Tools + memory + retrieval

### Key Skills Available

| Skill | Use For |
|-------|---------|
| \`tdd-workflow\` | Test-first development (Red-Green-Refactor) |
| \`evaluator-optimizer\` | Iterative quality improvement |
| \`error-recovery\` | Checkpoint and recovery patterns |
| \`subagent-contract\` | Standardized result formats |
| \`progress-tracking\` | JSON-based state persistence |

### Quick Reference

- **Specs location**: \`docs/specs/[feature-name].md\`
- **Progress files**: \`.claude/claude-progress.json\`, \`.claude/feature-list.json\`
- **Use \`/clear\`** frequently between major tasks
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
