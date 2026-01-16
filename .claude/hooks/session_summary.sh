#!/bin/bash
# Session Summary Hook for Claude Code
# Provides a summary of changes made during the session

set -e

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo '{"status": "skipped", "reason": "Not a git repository"}'
    exit 0
fi

# Get git status summary
STAGED=$(git diff --cached --stat 2>/dev/null | tail -1 || echo "")
UNSTAGED=$(git diff --stat 2>/dev/null | tail -1 || echo "")
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

# Create summary JSON
cat << EOF
{
  "status": "completed",
  "summary": {
    "staged_changes": "${STAGED:-No staged changes}",
    "unstaged_changes": "${UNSTAGED:-No unstaged changes}",
    "untracked_files": $UNTRACKED
  },
  "reminder": "Remember to commit your changes if needed"
}
EOF

exit 0
