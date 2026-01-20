---
name: code-quality
description: |
  Detects and runs project-configured linting, formatting, and type checking. Use when:
  - After writing or editing code to ensure quality standards
  - Fixing lint errors or formatting issues
  - Running the project's configured quality tools
  - Code is failing CI quality checks
  Trigger phrases: lint, format code, run linter, fix formatting, type check, code style
allowed-tools: Bash, Read, Glob, Grep
model: haiku
user-invocable: true
---

# Code Quality

Detect and use the project's configured quality tools. This skill defines a **discovery process**, not specific tool commands.

## Design Principles

1. **Projects own their configuration**: Never assume which tools are used
2. **Discover before running**: Check what tools the project has configured
3. **Use project commands**: Prefer scripts defined in package.json/Makefile/etc.
4. **Never install**: Don't add tools that aren't already configured

---

## Workflow

### Step 1: Discover Quality Tool Configuration

Check for quality tool presence without assuming specific tools:

```bash
# List all config files that might indicate quality tools
ls -la .* *.config.* *.json *.toml *.yml *.yaml 2>/dev/null | head -30

# Check for common config patterns (not specific tools)
ls -la *lint* *format* *prettier* *eslint* *biome* *ruff* *black* *rubocop* *golangci* 2>/dev/null
```

### Step 2: Check for Defined Scripts

**Always prefer project-defined commands:**

```bash
# JavaScript/TypeScript projects
grep -A 30 '"scripts"' package.json 2>/dev/null | grep -E '(lint|format|check|style)'

# Python projects
grep -A 10 '\[tool\.' pyproject.toml 2>/dev/null
grep -E '(lint|format|check)' Makefile 2>/dev/null

# Any project
cat Makefile 2>/dev/null | grep -E '^(lint|format|check|style):'
```

### Step 3: Run Detected Commands

**Priority order:**

1. **Project scripts** (most reliable)
   - `npm run lint`, `npm run format`, `make lint`, etc.

2. **Direct tool execution** (if no script but config exists)
   - Only if configuration file is detected
   - Search for current command syntax if unsure

3. **Research** (if tool is unfamiliar)
   ```
   WebSearch: "[tool name] run command [year]"
   WebFetch: [official docs] → "Extract CLI usage"
   ```

### Step 4: Verify Build Still Works

After quality fixes:

```bash
# Run the project's build command (discover first)
grep -E '"build"' package.json 2>/dev/null && npm run build
grep -E '^build:' Makefile 2>/dev/null && make build
```

---

## Discovery Patterns

### Identifying Quality Tools

Instead of hardcoding tool names, look for patterns:

| Pattern | Indicates |
|---------|-----------|
| `*lint*` in filename | Linting configuration |
| `*format*` or `*prettier*` in filename | Formatting configuration |
| `*.config.*` files | Tool configuration |
| `[tool.*]` sections in pyproject.toml | Python tool configs |
| Scripts with `lint`, `format`, `check` keywords | Project-defined commands |

### Reading Unknown Configurations

If you find a config file for an unfamiliar tool:

1. Read the config file to understand tool name
2. Check if there's a script that uses it
3. If needed, WebSearch for the tool's documentation
4. Run the tool using its documented interface

---

## What NOT To Do

| Don't | Why |
|-------|-----|
| Install tools that aren't configured | Changes project dependencies |
| Assume specific tool names | Tools change and vary by project |
| Run tools without config present | May use wrong settings |
| Override project configuration | Violates project standards |
| Hardcode tool commands | Commands change between versions |

---

## Integration with CI

Projects typically enforce quality via:
- Pre-commit hooks
- CI pipelines (GitHub Actions, GitLab CI, etc.)
- Editor integration

**This skill complements those mechanisms** by running the same tools on demand, using the same configuration.

---

## Success Criteria

- All configured lint rules pass
- No type errors (if type checking is configured)
- Build completes successfully
- Git hooks pass (if present)

---

## Rules

- ALWAYS detect tooling before running commands
- ALWAYS use project's configured scripts/commands
- ALWAYS check for scripts in package.json/Makefile first
- NEVER install or assume tools
- NEVER run tools without their config present
- NEVER hardcode tool commands (discover them)
- ALWAYS verify build after fixes
- ALWAYS report errors clearly (don't ignore them)
