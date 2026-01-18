---
name: code-quality
description: |
  Detects and runs project-configured linting, formatting, and type checking. Use when:
  - After writing or editing code to ensure quality standards
  - Fixing lint errors or formatting issues
  - Running the project's configured quality tools
  - Code is failing CI quality checks
  Trigger phrases: lint, format code, run linter, fix formatting, type check, code style
allowed-tools: Bash, Read, Glob
model: haiku
user-invocable: true
---

# Code Quality

Detect and use the project's configured quality tools. Never assume tools - always check what the project uses.

## Philosophy

**Projects own their quality configuration.** This skill:
1. Detects what tools the project has configured
2. Runs those tools using the project's settings
3. Never installs or assumes tools that aren't present

## Workflow

### Step 1: Detect Project Configuration

Check for quality tool configs in the project:

```bash
# List all potential config files
ls -la .eslintrc* eslint.config.* .prettierrc* prettier.config.* biome.json* 2>/dev/null
ls -la ruff.toml pyproject.toml .golangci.yml rustfmt.toml .rubocop.yml 2>/dev/null

# Check package.json scripts (JavaScript/TypeScript)
grep -A 20 '"scripts"' package.json 2>/dev/null | grep -E '(lint|format|check)'
```

### Step 2: Use Project's Commands

**Always prefer project-defined npm scripts or Makefile targets:**

```bash
# JavaScript/TypeScript - check package.json scripts first
npm run lint          # If "lint" script exists
npm run format        # If "format" script exists
npm run typecheck     # If "typecheck" script exists

# Python - check pyproject.toml or Makefile
make lint             # If Makefile has lint target
make format           # If Makefile has format target

# Or run detected tools directly
ruff check . --fix    # If ruff.toml exists
black .               # If black is in pyproject.toml
```

### Step 3: Run Detected Tools

Only run tools that have configuration present:

| Config Present | Command |
|----------------|---------|
| `eslint.config.*` or `.eslintrc*` | `npm run lint` or `npx eslint .` |
| `.prettierrc*` or `prettier.config.*` | `npm run format` or `npx prettier --write .` |
| `biome.json*` | `npx biome check --write .` |
| `ruff.toml` or `[tool.ruff]` in pyproject.toml | `ruff check . --fix && ruff format .` |
| `.golangci.yml` | `golangci-lint run` |
| `rustfmt.toml` or `.rustfmt.toml` | `cargo fmt` |
| `.rubocop.yml` | `bundle exec rubocop -a` |

### Step 4: Verify Build

After quality fixes, verify the project still builds:

```bash
# Use project's build command
npm run build         # JavaScript
cargo build           # Rust
go build ./...        # Go
```

## What NOT To Do

- **Never install tools** that aren't already configured
- **Never run tools** without checking for their config first
- **Never override** project's tool configuration
- **Never assume** which formatter or linter to use

## Integration with Git Hooks

Projects typically enforce quality via:
- Pre-commit hooks (husky, pre-commit, lefthook)
- CI pipelines (GitHub Actions, GitLab CI)
- Editor integration (VS Code, IDE plugins)

**This skill complements those mechanisms** by running the same tools on demand.

## Success Criteria

- All configured lint rules pass
- No type errors (if type checking is configured)
- Build completes successfully
- Git hooks pass (if present)

## Rules

- ALWAYS detect tooling before running commands
- ALWAYS use project's configured scripts/commands
- NEVER install or assume tools
- ALWAYS verify build after fixes
- NEVER ignore errors, report them clearly
