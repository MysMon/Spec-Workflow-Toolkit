#!/bin/bash
# Session Summary Hook - Stop event
# Outputs a summary of changes made during the session
# Stack-agnostic

echo ""
echo "═══════════════════════════════════════════════════"
echo "                  SESSION SUMMARY                   "
echo "═══════════════════════════════════════════════════"
echo ""

# Check if we're in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Git status summary
    echo "📊 Git Status:"
    echo "──────────────"

    # Staged changes
    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
    if [ "$STAGED" -gt 0 ]; then
        echo "  ✅ Staged files: $STAGED"
        git diff --cached --name-only 2>/dev/null | head -5 | sed 's/^/     /'
        [ "$STAGED" -gt 5 ] && echo "     ... and $((STAGED - 5)) more"
    fi

    # Unstaged changes
    UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l)
    if [ "$UNSTAGED" -gt 0 ]; then
        echo "  📝 Modified files: $UNSTAGED"
        git diff --name-only 2>/dev/null | head -5 | sed 's/^/     /'
        [ "$UNSTAGED" -gt 5 ] && echo "     ... and $((UNSTAGED - 5)) more"
    fi

    # Untracked files
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
    if [ "$UNTRACKED" -gt 0 ]; then
        echo "  🆕 Untracked files: $UNTRACKED"
        git ls-files --others --exclude-standard 2>/dev/null | head -5 | sed 's/^/     /'
        [ "$UNTRACKED" -gt 5 ] && echo "     ... and $((UNTRACKED - 5)) more"
    fi

    # Branch info
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        echo ""
        echo "  🌿 Current branch: $BRANCH"

        # Check if ahead/behind remote
        AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
        [ "$AHEAD" -gt 0 ] && echo "     ↑ $AHEAD commit(s) ahead of remote"
        [ "$BEHIND" -gt 0 ] && echo "     ↓ $BEHIND commit(s) behind remote"
    fi

    # Recent commits in this session (last hour)
    RECENT=$(git log --oneline --since="1 hour ago" 2>/dev/null | wc -l)
    if [ "$RECENT" -gt 0 ]; then
        echo ""
        echo "  📜 Recent commits:"
        git log --oneline --since="1 hour ago" 2>/dev/null | head -5 | sed 's/^/     /'
    fi
else
    echo "📁 Not a git repository"
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo ""

exit 0
