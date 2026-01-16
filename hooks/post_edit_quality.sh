#!/bin/bash
# Post-Edit Quality Check Hook
# Runs appropriate linting/formatting based on detected stack
# Stack-agnostic: auto-detects tooling

set -e

# Get the file that was edited from stdin (JSON format)
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Run appropriate quality checks based on file type
case "$EXT" in
    ts|tsx|js|jsx|mjs|cjs)
        # JavaScript/TypeScript
        if [ -f "package.json" ]; then
            if command_exists npx; then
                # Try ESLint
                if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
                    npx eslint --fix "$FILE_PATH" 2>/dev/null || true
                fi
                # Try Prettier
                if [ -f ".prettierrc" ] || [ -f ".prettierrc.js" ] || [ -f "prettier.config.js" ]; then
                    npx prettier --write "$FILE_PATH" 2>/dev/null || true
                fi
            fi
        fi
        ;;

    py)
        # Python
        if command_exists ruff; then
            ruff check --fix "$FILE_PATH" 2>/dev/null || true
            ruff format "$FILE_PATH" 2>/dev/null || true
        elif command_exists black; then
            black "$FILE_PATH" 2>/dev/null || true
        fi
        ;;

    go)
        # Go
        if command_exists gofmt; then
            gofmt -w "$FILE_PATH" 2>/dev/null || true
        fi
        if command_exists goimports; then
            goimports -w "$FILE_PATH" 2>/dev/null || true
        fi
        ;;

    rs)
        # Rust
        if command_exists rustfmt; then
            rustfmt "$FILE_PATH" 2>/dev/null || true
        fi
        ;;

    java)
        # Java - typically handled by IDE/build tool
        # Just validate syntax
        :
        ;;

    json)
        # JSON - format with jq if available
        if command_exists jq; then
            TMP=$(mktemp)
            if jq . "$FILE_PATH" > "$TMP" 2>/dev/null; then
                mv "$TMP" "$FILE_PATH"
            else
                rm -f "$TMP"
            fi
        fi
        ;;

    yaml|yml)
        # YAML - just validate
        if command_exists python3; then
            python3 -c "import yaml; yaml.safe_load(open('$FILE_PATH'))" 2>/dev/null || true
        fi
        ;;

    md)
        # Markdown - prettier if available
        if command_exists npx && [ -f "package.json" ]; then
            if [ -f ".prettierrc" ] || [ -f ".prettierrc.js" ]; then
                npx prettier --write "$FILE_PATH" 2>/dev/null || true
            fi
        fi
        ;;
esac

exit 0
