#!/bin/bash
# Session Summary Hook - Stop event
# Outputs a summary of changes made during the session via systemMessage
# Stack-agnostic
#
# Note: Stop hooks use JSON output with systemMessage for user visibility.
# Plain stdout is only shown in verbose mode.

# Source workspace utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# Build summary into a variable
SUMMARY=""

add_line() {
    SUMMARY="${SUMMARY}$1
"
}

add_line ""
add_line "═══════════════════════════════════════════════════"
add_line "                  SESSION SUMMARY                   "
add_line "═══════════════════════════════════════════════════"
add_line ""

# Display workspace info
if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)
    add_line "[WORKSPACE] $WORKSPACE_ID"

    # Check for progress file
    PROGRESS_FILE=$(get_progress_file "$WORKSPACE_ID")
    if [ -f "$PROGRESS_FILE" ]; then
        add_line "  [PROGRESS] Progress file: exists"
    fi
    add_line ""
fi

# Check if we're in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Git status summary
    add_line "[GIT STATUS]"
    add_line "──────────────"

    # Staged changes
    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    if [ "$STAGED" -gt 0 ]; then
        add_line "  [STAGED] Staged files: $STAGED"
        while IFS= read -r file; do
            add_line "     $file"
        done < <(git diff --cached --name-only 2>/dev/null | head -5)
        [ "$STAGED" -gt 5 ] && add_line "     ... and $((STAGED - 5)) more"
    fi

    # Unstaged changes
    UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    if [ "$UNSTAGED" -gt 0 ]; then
        add_line "  [MODIFIED] Modified files: $UNSTAGED"
        while IFS= read -r file; do
            add_line "     $file"
        done < <(git diff --name-only 2>/dev/null | head -5)
        [ "$UNSTAGED" -gt 5 ] && add_line "     ... and $((UNSTAGED - 5)) more"
    fi

    # Untracked files
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    if [ "$UNTRACKED" -gt 0 ]; then
        add_line "  [NEW] Untracked files: $UNTRACKED"
        while IFS= read -r file; do
            add_line "     $file"
        done < <(git ls-files --others --exclude-standard 2>/dev/null | head -5)
        [ "$UNTRACKED" -gt 5 ] && add_line "     ... and $((UNTRACKED - 5)) more"
    fi

    # Branch info
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        add_line ""
        add_line "  [BRANCH] Current branch: $BRANCH"

        # Check if ahead/behind remote
        AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
        [ "$AHEAD" -gt 0 ] && add_line "     ^ $AHEAD commit(s) ahead of remote"
        [ "$BEHIND" -gt 0 ] && add_line "     v $BEHIND commit(s) behind remote"
    fi

    # Recent commits in this session (last hour)
    RECENT=$(git log --oneline --since="1 hour ago" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$RECENT" -gt 0 ]; then
        add_line ""
        add_line "  [COMMITS] Recent commits:"
        while IFS= read -r commit; do
            add_line "     $commit"
        done < <(git log --oneline --since="1 hour ago" 2>/dev/null | head -5)
    fi
else
    add_line "[INFO] Not a git repository"
fi

add_line ""
add_line "═══════════════════════════════════════════════════"
add_line ""

# Output as JSON with systemMessage (will be shown to user)
# Use Python for proper JSON escaping of the summary
python3 -c "
import json
import sys
summary = '''$SUMMARY'''
print(json.dumps({'systemMessage': summary}))
" 2>/dev/null || echo '{"systemMessage": "Session ended"}'

exit 0
