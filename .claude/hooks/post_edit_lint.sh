#!/bin/bash
# Post-Edit Lint Hook for Claude Code
# Runs linting on edited files to catch issues early

set -e

# Read input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('tool_input', {}).get('file_path', data.get('tool_input', {}).get('path', '')))" 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
    echo '{"status": "skipped", "reason": "No file path found"}'
    exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Check if npm is available and package.json exists
if [ -f "package.json" ] && command -v npm &> /dev/null; then
    case "$EXT" in
        ts|tsx|js|jsx)
            # Check if eslint is configured
            if [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ] || [ -f "eslint.config.js" ]; then
                # Run eslint on the specific file (non-blocking)
                npm run lint -- --fix "$FILE_PATH" 2>/dev/null || true
            fi
            ;;
        css|scss)
            # Check if stylelint is configured
            if [ -f ".stylelintrc.json" ] || [ -f ".stylelintrc" ]; then
                npm run stylelint -- --fix "$FILE_PATH" 2>/dev/null || true
            fi
            ;;
    esac
fi

# Run prettier if available
if [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]; then
    if command -v npx &> /dev/null; then
        npx prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
fi

echo "{\"status\": \"completed\", \"file\": \"$FILE_PATH\"}"
exit 0
