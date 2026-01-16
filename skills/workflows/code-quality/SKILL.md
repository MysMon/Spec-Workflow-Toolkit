---
name: code-quality
description: |
  Runs linting, formatting, and type checking across any language stack. Use when:
  - After writing or editing code to ensure quality standards
  - Fixing lint errors or formatting issues
  - Running ESLint, Prettier, Ruff, gofmt, rustfmt, or similar tools
  - Type checking with TypeScript, mypy, or pyright
  - Code is failing CI quality checks
  Trigger phrases: lint, format code, run eslint, fix formatting, type check, code style, prettier, ruff, clippy
allowed-tools: Bash, Read, Glob
model: haiku
user-invocable: true
---

# Code Quality

Stack-adaptive linting, formatting, and type checking.

## Workflow

### Step 1: Detect Tooling

First, identify the project's quality tools:

```bash
# Check for config files
ls -la .eslintrc* eslint.config.* 2>/dev/null     # ESLint
ls -la .prettierrc* prettier.config.* 2>/dev/null # Prettier
ls -la ruff.toml pyproject.toml 2>/dev/null       # Ruff
ls -la .golangci.yml 2>/dev/null                  # golangci-lint
ls -la rustfmt.toml .rustfmt.toml 2>/dev/null     # rustfmt
```

### Step 2: Run Quality Checks

Execute appropriate tools based on detection:

#### JavaScript/TypeScript

```bash
# Linting
npm run lint 2>/dev/null || npx eslint . --ext .ts,.tsx,.js,.jsx

# Auto-fix
npm run lint:fix 2>/dev/null || npx eslint . --fix

# Formatting
npm run format 2>/dev/null || npx prettier --write "**/*.{ts,tsx,js,jsx,json,md}"

# Type checking
npx tsc --noEmit
```

#### Python

```bash
# Ruff (linting + formatting)
ruff check . --fix
ruff format .

# Or Black + isort
black .
isort .

# Type checking
mypy . || pyright .
```

#### Go

```bash
# Linting
golangci-lint run

# Formatting
go fmt ./...
goimports -w .

# Vet
go vet ./...
```

#### Rust

```bash
# Linting
cargo clippy -- -D warnings

# Formatting
cargo fmt

# Check
cargo check
```

#### Java

```bash
# Maven
mvn spotless:apply
mvn checkstyle:check

# Gradle
./gradlew spotlessApply
./gradlew checkstyleMain
```

### Step 3: Verify Build

Ensure the project still builds:

| Language | Build Command |
|----------|---------------|
| JavaScript | `npm run build` |
| Python | `python -m py_compile $(find . -name "*.py")` |
| Go | `go build ./...` |
| Rust | `cargo build` |
| Java | `mvn compile` or `./gradlew build` |

### Step 4: Handle Errors

If errors persist after auto-fix:

1. Read the specific error message
2. Locate the file and line number
3. Analyze the issue
4. Apply manual fix
5. Re-run quality checks

**Maximum retry attempts: 3**

If still failing after 3 attempts, report:
- File path
- Line number
- Error message
- Suggested fix

## Tool Configuration Reference

### ESLint (JavaScript)

```json
// eslint.config.js or .eslintrc.json
{
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
  "rules": {
    "no-unused-vars": "error",
    "@typescript-eslint/no-explicit-any": "error"
  }
}
```

### Ruff (Python)

```toml
# ruff.toml or pyproject.toml [tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "W", "UP"]
```

### golangci-lint (Go)

```yaml
# .golangci.yml
linters:
  enable:
    - gofmt
    - govet
    - errcheck
    - staticcheck
```

### Clippy (Rust)

```toml
# Cargo.toml
[lints.clippy]
pedantic = "warn"
unwrap_used = "deny"
```

## Success Criteria

- All lint rules pass
- No type errors
- Build completes successfully
- No formatting changes needed

## Rules

- ALWAYS detect tooling before running commands
- ALWAYS try auto-fix before manual intervention
- NEVER skip type checking
- ALWAYS verify build after fixes
- NEVER ignore errors, report them clearly
