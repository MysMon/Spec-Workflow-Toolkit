#!/bin/bash
# Post-Edit Quality Check Hook
# Runs appropriate linting/formatting based on detected stack
# Stack-agnostic: auto-detects tooling and package managers

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

# Detect JavaScript/Node.js package manager
detect_js_package_manager() {
    if [ -f "bun.lockb" ] && command_exists bun; then
        echo "bunx"
    elif [ -f "pnpm-lock.yaml" ] && command_exists pnpm; then
        echo "pnpm exec"
    elif [ -f "yarn.lock" ] && command_exists yarn; then
        echo "yarn"
    elif command_exists npx; then
        echo "npx"
    else
        echo ""
    fi
}

# Check for ESLint config
has_eslint_config() {
    [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.cjs" ] || \
    [ -f ".eslintrc.yaml" ] || [ -f ".eslintrc.yml" ] || [ -f ".eslintrc" ] || \
    [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ] || [ -f "eslint.config.cjs" ]
}

# Check for Prettier config
has_prettier_config() {
    [ -f ".prettierrc" ] || [ -f ".prettierrc.js" ] || [ -f ".prettierrc.cjs" ] || \
    [ -f ".prettierrc.json" ] || [ -f ".prettierrc.yaml" ] || [ -f ".prettierrc.yml" ] || \
    [ -f "prettier.config.js" ] || [ -f "prettier.config.cjs" ] || [ -f "prettier.config.mjs" ]
}

# Check for Biome config
has_biome_config() {
    [ -f "biome.json" ] || [ -f "biome.jsonc" ]
}

# Run appropriate quality checks based on file type
case "$EXT" in
    ts|tsx|js|jsx|mjs|cjs|vue|svelte)
        # JavaScript/TypeScript (including Vue/Svelte SFCs)
        if [ -f "package.json" ]; then
            PKG_RUNNER=$(detect_js_package_manager)
            if [ -n "$PKG_RUNNER" ]; then
                # Try Biome first (fast all-in-one)
                if has_biome_config; then
                    $PKG_RUNNER biome check --write "$FILE_PATH" 2>/dev/null || true
                else
                    # Try ESLint
                    if has_eslint_config; then
                        $PKG_RUNNER eslint --fix "$FILE_PATH" 2>/dev/null || true
                    fi
                    # Try Prettier
                    if has_prettier_config; then
                        $PKG_RUNNER prettier --write "$FILE_PATH" 2>/dev/null || true
                    fi
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
            if command_exists isort; then
                isort "$FILE_PATH" 2>/dev/null || true
            fi
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

    java|kt|kts)
        # Java / Kotlin
        if command_exists google-java-format && [ "$EXT" = "java" ]; then
            google-java-format --replace "$FILE_PATH" 2>/dev/null || true
        elif command_exists ktlint && [ "$EXT" = "kt" ] || [ "$EXT" = "kts" ]; then
            ktlint --format "$FILE_PATH" 2>/dev/null || true
        fi
        ;;

    cs)
        # C# - dotnet format if available
        if command_exists dotnet; then
            dotnet format --include "$FILE_PATH" 2>/dev/null || true
        fi
        ;;

    php)
        # PHP
        if command_exists php-cs-fixer; then
            php-cs-fixer fix "$FILE_PATH" 2>/dev/null || true
        elif [ -f "vendor/bin/pint" ]; then
            ./vendor/bin/pint "$FILE_PATH" 2>/dev/null || true
        elif [ -f "vendor/bin/php-cs-fixer" ]; then
            ./vendor/bin/php-cs-fixer fix "$FILE_PATH" 2>/dev/null || true
        fi
        ;;

    rb)
        # Ruby
        if command_exists rubocop; then
            rubocop -a "$FILE_PATH" 2>/dev/null || true
        elif [ -f "bin/rubocop" ]; then
            ./bin/rubocop -a "$FILE_PATH" 2>/dev/null || true
        fi
        ;;

    swift)
        # Swift
        if command_exists swiftformat; then
            swiftformat "$FILE_PATH" 2>/dev/null || true
        fi
        ;;

    json)
        # JSON - format with jq, biome, or prettier
        if [ -f "package.json" ] && has_biome_config; then
            PKG_RUNNER=$(detect_js_package_manager)
            [ -n "$PKG_RUNNER" ] && $PKG_RUNNER biome check --write "$FILE_PATH" 2>/dev/null || true
        elif [ -f "package.json" ] && has_prettier_config; then
            PKG_RUNNER=$(detect_js_package_manager)
            [ -n "$PKG_RUNNER" ] && $PKG_RUNNER prettier --write "$FILE_PATH" 2>/dev/null || true
        elif command_exists jq; then
            TMP=$(mktemp)
            if jq . "$FILE_PATH" > "$TMP" 2>/dev/null; then
                mv "$TMP" "$FILE_PATH"
            else
                rm -f "$TMP"
            fi
        fi
        ;;

    yaml|yml)
        # YAML - validate and optionally format
        if [ -f "package.json" ] && has_prettier_config; then
            PKG_RUNNER=$(detect_js_package_manager)
            [ -n "$PKG_RUNNER" ] && $PKG_RUNNER prettier --write "$FILE_PATH" 2>/dev/null || true
        elif command_exists python3; then
            python3 -c "import yaml; yaml.safe_load(open('$FILE_PATH'))" 2>/dev/null || true
        fi
        ;;

    md)
        # Markdown
        if [ -f "package.json" ]; then
            PKG_RUNNER=$(detect_js_package_manager)
            if [ -n "$PKG_RUNNER" ] && has_prettier_config; then
                $PKG_RUNNER prettier --write "$FILE_PATH" 2>/dev/null || true
            fi
        fi
        ;;

    toml)
        # TOML - taplo if available
        if command_exists taplo; then
            taplo format "$FILE_PATH" 2>/dev/null || true
        fi
        ;;

    sql)
        # SQL - sqlfluff if available
        if command_exists sqlfluff; then
            sqlfluff fix --force "$FILE_PATH" 2>/dev/null || true
        fi
        ;;

    sh|bash)
        # Shell scripts - shfmt if available
        if command_exists shfmt; then
            shfmt -w "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
esac

exit 0
