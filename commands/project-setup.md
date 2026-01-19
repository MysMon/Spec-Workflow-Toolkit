---
description: "Analyze project and generate .claude/rules/ files through stack detection and user interview"
argument-hint: "[optional: focus area - e.g., 'frontend', 'testing']"
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite
---

# /project-setup - Project Rules Generator

Generate project-specific `.claude/rules/` files by analyzing the codebase and interviewing the user about conventions and preferences.

## Purpose

This command helps onboard Claude to a new project by:
1. Detecting the technology stack automatically
2. Identifying existing patterns and conventions
3. Interviewing the user about project-specific rules
4. Generating `.claude/rules/` files with appropriate `paths:` conditions

## When to Use

- Setting up Claude Code for a new project
- Onboarding to an existing codebase
- Documenting team conventions for AI assistance
- Creating stack-specific guidelines (frontend vs backend)

## Phase Overview

```
Phase 1: Stack Detection    → Identify technologies
Phase 2: Pattern Analysis   → Find existing conventions
Phase 3: User Interview     → Gather preferences
Phase 4: Rule Generation    → Create .claude/rules/ files
Phase 5: Review & Confirm   → User approval
```

---

## Execution Instructions

### Phase 1: Stack Detection

**Goal:** Automatically identify the project's technology stack.

**Use the `stack-detector` skill pattern:**

```bash
# Check for configuration files
ls -la package.json pyproject.toml go.mod Cargo.toml *.csproj 2>/dev/null

# Check for lock files (package manager detection)
ls -la package-lock.json yarn.lock pnpm-lock.yaml bun.lockb 2>/dev/null

# Check for framework indicators
ls -la next.config.* nuxt.config.* vite.config.* angular.json 2>/dev/null
```

**Identify:**
- Primary language(s)
- Package manager
- Frontend framework (if any)
- Backend framework (if any)
- Testing framework(s)
- Linting/formatting tools
- CI/CD configuration

**Output:** Stack profile summary for user confirmation.

### Phase 2: Pattern Analysis

**Goal:** Discover existing conventions in the codebase.

**Delegate to `code-explorer` agent:**

```
Launch code-explorer agent to analyze:
- Directory structure and naming conventions
- Code organization patterns (by feature, by layer, etc.)
- Import/export patterns
- Error handling patterns
- Testing patterns (file locations, naming)
- Documentation patterns

Thoroughness: medium
Output: Convention summary with file:line examples
```

**Also check for existing configuration:**

```bash
# Check for existing Claude configuration
ls -la .claude/ CLAUDE.md .claude/rules/ 2>/dev/null

# Check for linting/formatting configs
ls -la .eslintrc* .prettierrc* biome.json pyproject.toml .golangci.yml 2>/dev/null

# Check for editor configs
ls -la .editorconfig .vscode/ 2>/dev/null
```

**Output:** Pattern summary with specific examples.

### Phase 3: User Interview

**Goal:** Gather project-specific preferences through structured questions.

**Use `AskUserQuestion` for each category:**

#### 3.1 Code Style Preferences

```
Based on detected stack: [stack summary]

Question: "What code style conventions should Claude follow?"
Header: "Code Style"
Options:
- "Follow existing linter config (detected: [linter])"
- "Stricter than current config"
- "Let me specify custom rules"
- "Use framework defaults"
```

#### 3.2 Testing Conventions

```
Question: "What testing approach should Claude use?"
Header: "Testing"
Options:
- "Match existing test patterns (detected: [pattern])"
- "Test-Driven Development (write tests first)"
- "Tests after implementation"
- "Let me specify test requirements"
```

#### 3.3 Documentation Preferences

```
Question: "What documentation style should Claude follow?"
Header: "Docs Style"
Options:
- "JSDoc/docstrings for public APIs only"
- "Comprehensive inline comments"
- "Minimal comments (self-documenting code)"
- "Match existing documentation style"
```

#### 3.4 Architecture Boundaries

```
Question: "Are there areas Claude should handle differently?"
Header: "Boundaries"
MultiSelect: true
Options:
- "Frontend has different rules than backend"
- "API layer has strict validation requirements"
- "Database code requires extra review"
- "No special boundaries needed"
```

#### 3.5 Security Requirements

```
Question: "What security considerations apply?"
Header: "Security"
MultiSelect: true
Options:
- "Authentication/authorization code needs extra care"
- "Input validation is critical"
- "Sensitive data handling (PII, credentials)"
- "Standard security practices are sufficient"
```

#### 3.6 Custom Rules

```
Question: "Any other project-specific rules Claude should know?"
Header: "Custom"
Options:
- "Yes, I'll describe them"
- "No additional rules needed"
```

If "Yes", use follow-up `AskUserQuestion` to gather details.

**Output:** Comprehensive preferences summary.

### Phase 4: Rule Generation

**Goal:** Generate `.claude/rules/` files based on analysis and interview.

**Create directory structure:**

```bash
mkdir -p .claude/rules
```

**Generate rule files based on findings:**

#### 4.1 General Rules (always created)

Create `.claude/rules/general.md`:

```markdown
# Project: [Project Name]

## Technology Stack
- Language: [detected]
- Framework: [detected]
- Package Manager: [detected]

## Code Style
[Based on interview responses]

## Testing
[Based on interview responses]

## Documentation
[Based on interview responses]
```

#### 4.2 Path-Conditional Rules (if boundaries detected)

If frontend/backend separation detected, create:

`.claude/rules/frontend.md`:
```yaml
---
paths:
  - "src/frontend/**"
  - "src/components/**"
  - "src/pages/**"
  - "app/**"
---

# Frontend Development Rules

[Frontend-specific rules from interview]
```

`.claude/rules/backend.md`:
```yaml
---
paths:
  - "src/api/**"
  - "src/services/**"
  - "src/server/**"
  - "server/**"
---

# Backend Development Rules

[Backend-specific rules from interview]
```

#### 4.3 Testing Rules (if specific testing conventions)

`.claude/rules/testing.md`:
```yaml
---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "tests/**"
  - "__tests__/**"
---

# Testing Conventions

[Testing rules from interview]
```

#### 4.4 Security Rules (if security-sensitive areas identified)

`.claude/rules/security.md`:
```yaml
---
paths:
  - "src/auth/**"
  - "src/api/**"
  - "**/middleware/**"
---

# Security Requirements

[Security rules from interview]
```

### Phase 5: Review & Confirm

**Goal:** Present generated rules for user approval.

**Display summary:**

```markdown
## Generated Rules Summary

### Files Created
| File | Paths Scope | Key Rules |
|------|-------------|-----------|
| `general.md` | All files | [summary] |
| `frontend.md` | src/frontend/** | [summary] |
| `backend.md` | src/api/** | [summary] |
| `testing.md` | **/*.test.* | [summary] |

### Rule Highlights
- [Key rule 1]
- [Key rule 2]
- [Key rule 3]

Would you like to:
1. Apply these rules as-is
2. Review and edit before applying
3. Regenerate with different preferences
4. Cancel
```

**If user chooses to edit:**
- Open each file for review
- Allow modifications
- Confirm final state

**Final confirmation:**

```
Rules have been created in .claude/rules/

These rules will be automatically loaded when Claude works on this project.

To modify rules later:
- Edit files in .claude/rules/
- Use paths: frontmatter to scope rules to specific files

Next steps:
1. Review generated rules in .claude/rules/
2. Add to version control: git add .claude/rules/
3. Share with team for consistent AI assistance
```

---

## Rule Generation Templates

### General Template

```markdown
# [Project Name] Development Guidelines

## Stack
- **Language**: [Language] [Version if known]
- **Framework**: [Framework]
- **Package Manager**: [PM]

## Code Conventions
[From interview + detected patterns]

## File Organization
[Detected structure]

## Naming Conventions
- Files: [pattern]
- Components: [pattern]
- Functions: [pattern]
- Variables: [pattern]

## Import Order
[Detected or specified pattern]
```

### Path-Conditional Template

```yaml
---
paths:
  - "[glob pattern 1]"
  - "[glob pattern 2]"
---

# [Area] Development Rules

## Scope
These rules apply to: [description of matched files]

## Conventions
[Specific rules for this area]

## Patterns to Follow
[Examples with file:line references from analysis]

## Common Mistakes to Avoid
[Based on codebase analysis]
```

---

## Integration with Existing Configuration

**If CLAUDE.md exists:**
- Read existing content
- Avoid duplicating rules
- Reference CLAUDE.md in generated rules

**If .claude/rules/ exists:**
- List existing rules
- Ask if user wants to merge or replace
- Preserve custom rules user wants to keep

---

## Usage Examples

```bash
# Full setup with interview
/project-setup

# Focus on frontend rules only
/project-setup frontend

# Focus on testing conventions
/project-setup testing

# Regenerate after codebase changes
/project-setup
```

## Tips for Best Results

1. **Run early**: Set up rules when starting work on a project
2. **Be specific**: More detailed answers lead to better rules
3. **Review generated rules**: They may need minor adjustments
4. **Version control rules**: Share with team via git
5. **Update periodically**: Re-run after major architecture changes

## Comparison with /init

| Aspect | `/init` (built-in) | `/project-setup` |
|--------|-------------------|------------------|
| Output | Single CLAUDE.md | Multiple .claude/rules/ files |
| Path conditions | No | Yes (paths: frontmatter) |
| User interview | Minimal | Comprehensive |
| Stack detection | Basic | Detailed |
| Customization | Limited | Extensive |
