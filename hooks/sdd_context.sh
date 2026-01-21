#!/bin/bash
# SessionStart Hook: Inject SDD context, detect progress files, and support resumable workflows
# This hook runs once at session start to provide plugin context to the user's project
# Based on:
# - https://www.anthropic.com/engineering/claude-code-best-practices
# - https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
# - https://code.claude.com/docs/en/common-workflows (Git worktrees)

# Source workspace utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# --- Workspace Detection ---
WORKSPACE_ID=""
WORKSPACE_DIR=""
PROGRESS_FILE=""
FEATURE_FILE=""
RESUMPTION_INFO=""

# Get current workspace ID and paths
if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)
    WORKSPACE_DIR=$(get_workspace_dir "$WORKSPACE_ID")
    PROGRESS_FILE=$(get_progress_file "$WORKSPACE_ID")
    FEATURE_FILE=$(get_feature_file "$WORKSPACE_ID")
fi

# Verify progress file exists (clear if not)
if [ -n "$PROGRESS_FILE" ] && [ ! -f "$PROGRESS_FILE" ]; then
    PROGRESS_FILE=""
fi

# Verify feature file exists (clear if not)
if [ -n "$FEATURE_FILE" ] && [ ! -f "$FEATURE_FILE" ]; then
    FEATURE_FILE=""
fi

# Extract resumption context if progress file exists
if [ -n "$PROGRESS_FILE" ] && [ -f "$PROGRESS_FILE" ]; then
    # Try to extract key information using basic tools
    # Use environment variable to safely pass file path to Python
    if command -v python3 &> /dev/null; then
        RESUMPTION_INFO=$(PROGRESS_FILE_PATH="$PROGRESS_FILE" python3 -c "
import json
import os
import sys
try:
    progress_file = os.environ.get('PROGRESS_FILE_PATH', '')
    if not progress_file:
        sys.exit(0)
    with open(progress_file, 'r') as f:
        data = json.load(f)
    ctx = data.get('resumptionContext', {})
    status = data.get('status', 'unknown')
    current = data.get('currentTask', 'None')
    position = ctx.get('position', 'Not specified')
    next_action = ctx.get('nextAction', 'Not specified')
    blockers = ctx.get('blockers', [])
    workspace_id = data.get('workspaceId', 'Not set')

    print(f'Workspace: {workspace_id}')
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
# Use environment variable to safely pass file path to Python
FEATURE_PROGRESS=""
if [ -n "$FEATURE_FILE" ] && [ -f "$FEATURE_FILE" ]; then
    if command -v python3 &> /dev/null; then
        FEATURE_PROGRESS=$(FEATURE_FILE_PATH="$FEATURE_FILE" python3 -c "
import json
import os
try:
    feature_file = os.environ.get('FEATURE_FILE_PATH', '')
    if not feature_file:
        exit(0)
    with open(feature_file, 'r') as f:
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

# List available workspaces
AVAILABLE_WORKSPACES=""
if [ -d ".claude/workspaces" ]; then
    AVAILABLE_WORKSPACES=$(ls -1 ".claude/workspaces" 2>/dev/null | head -10)
fi

# --- Determine Role (Initializer vs Coding) ---
if [ -n "$PROGRESS_FILE" ] && [ -f "$PROGRESS_FILE" ]; then
    CURRENT_ROLE="CODING"
else
    CURRENT_ROLE="INITIALIZER"
fi

# --- Output Context ---
cat << 'EOF'
## SDD Toolkit - Session Initialized

**Official References:**
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)

EOF

# --- Workspace Info ---
if [ -n "$WORKSPACE_ID" ]; then
    echo "### Current Workspace"
    echo ""
    echo "**Workspace ID**: \`$WORKSPACE_ID\`"
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$CURRENT_BRANCH" ]; then
        echo "**Branch**: \`$CURRENT_BRANCH\`"
    elif git rev-parse --git-dir > /dev/null 2>&1; then
        # Git repo exists but HEAD is detached
        echo "**Branch**: \`detached HEAD\`"
        echo ""
        echo "> **Note**: You are in detached HEAD state. Consider checking out a branch for proper workspace isolation."
    else
        # Not a git repository
        echo "**Git**: Not initialized"
        echo ""
        echo "> **Note**: This is not a Git repository. Progress tracking will use directory-based workspace ID. Consider running \`git init\` for full feature support."
    fi
    echo "**Working Directory**: \`$(pwd)\`"
    echo ""
fi

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
2. **Create** workspace progress files:
   - `.claude/workspaces/{workspace-id}/claude-progress.json`
   - `.claude/workspaces/{workspace-id}/feature-list.json`
3. **Document** resumption context for future sessions
4. **Start** implementing the first feature

EOF
fi

cat << 'EOF'
### Core Principles (Spec-First Development)

1. **No Code Without Spec** - Never implement without approved specification
2. **Ambiguity Tolerance Zero** - If unclear, ask immediately using AskUserQuestion
3. **Protect Main Context** - Delegate complex work to subagents to preserve tokens

---

### Multi-Project Isolation

This plugin uses workspace-based isolation for concurrent project support:

```
.claude/workspaces/
├── main_a1b2c3d4/          # main branch workspace
│   ├── claude-progress.json
│   ├── feature-list.json
│   └── logs/
└── feature-auth_e5f6g7h8/  # feature branch workspace
    ├── claude-progress.json
    └── logs/
```

**Workspace ID Format**: `{branch}_{path-hash}`

Each git worktree gets its own isolated workspace. Use `/resume list` to see all workspaces.

---

### ORCHESTRATOR RULES (NON-NEGOTIABLE)

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

**State Files (per workspace):**
- `.claude/workspaces/{id}/claude-progress.json` - Progress log with resumption context
- `.claude/workspaces/{id}/feature-list.json` - Feature/task status tracking
- `.claude/workspaces/{id}/logs/` - Session and subagent logs

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
| `/resume` | Resume work from progress files |
| `/resume list` | List all available workspaces |

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
| `tdd-workflow` | Test-first development (Red-Green-Refactor) |
| `evaluator-optimizer` | Iterative quality improvement |
| `error-recovery` | Checkpoint and recovery patterns |
| `subagent-contract` | Standardized result formats |
| `progress-tracking` | JSON-based state persistence |

### Quick Reference

- **Specs location**: `docs/specs/[feature-name].md`
- **Progress files**: `.claude/workspaces/{id}/claude-progress.json`
- **Use `/clear`** frequently between major tasks
- **Ask questions** rather than assume requirements
- **Confidence threshold**: 80% (only report issues >= 80 confidence)

EOF

# --- Output Resumption Context if Available ---
if [ -n "$PROGRESS_FILE" ] && [ -f "$PROGRESS_FILE" ]; then
    echo ""
    echo "### Resumable Work Detected"
    echo ""
    echo "**Workspace ID**: \`$WORKSPACE_ID\`"
    echo "**Progress File**: \`$PROGRESS_FILE\`"
    if [ -n "$FEATURE_FILE" ] && [ -f "$FEATURE_FILE" ]; then
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

# --- Output Available Workspaces if Multiple ---
if [ -n "$AVAILABLE_WORKSPACES" ]; then
    WORKSPACE_COUNT=$(echo "$AVAILABLE_WORKSPACES" | wc -l)
    if [ "$WORKSPACE_COUNT" -gt 1 ]; then
        echo ""
        echo "### Available Workspaces"
        echo ""
        echo "Multiple workspaces detected. Use \`/resume list\` to see details."
        echo ""
        echo "\`\`\`"
        echo "$AVAILABLE_WORKSPACES"
        echo "\`\`\`"
        echo ""
    fi
fi

# --- Check for Pending Insights ---
if command -v count_pending_insights &> /dev/null && [ -n "$WORKSPACE_ID" ]; then
    PENDING_COUNT=$(count_pending_insights "$WORKSPACE_ID")
    if [ "$PENDING_COUNT" -gt 0 ]; then
        echo ""
        echo "### Pending Insights"
        echo ""
        echo "**$PENDING_COUNT insight(s)** captured during previous sessions are awaiting review."
        echo ""
        echo "Run \`/review-insights\` to evaluate and apply them."
        echo ""
        # Show preview of first few insights (read from individual files)
        PENDING_DIR=$(get_pending_insights_dir "$WORKSPACE_ID")
        if [ -d "$PENDING_DIR" ] && command -v python3 &> /dev/null; then
            PREVIEW=$(PENDING_DIR_VAR="$PENDING_DIR" python3 << 'PYEOF'
import json
import os
import glob

pending_dir = os.environ.get('PENDING_DIR_VAR', '')
if not pending_dir or not os.path.isdir(pending_dir):
    exit(0)

try:
    # Get up to 3 most recent insight files (sorted by filename which includes timestamp)
    files = sorted(glob.glob(os.path.join(pending_dir, '*.json')), reverse=True)[:3]
    for i, filepath in enumerate(files, 1):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                ins = json.load(f)
            content = ins.get('content', '')[:60]
            if len(ins.get('content', '')) > 60:
                content += '...'
            category = ins.get('category', 'insight')
            print(f"  {i}. [{category}] {content}")
        except (json.JSONDecodeError, IOError):
            continue  # Skip corrupt files
except Exception:
    pass  # Silent fail for preview display is acceptable
PYEOF
)
            if [ -n "$PREVIEW" ]; then
                echo "**Recent insights:**"
                echo "$PREVIEW"
                echo ""
            fi
        fi
    fi
fi

# Explicit exit for clarity
exit 0
