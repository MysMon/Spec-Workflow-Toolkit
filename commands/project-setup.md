---
description: "Analyze project and generate .claude/rules/ files through stack detection and user interview"
argument-hint: "[optional: focus area - e.g., 'frontend', 'testing']"
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite
---

# /project-setup - Project Rules Generator

Generate project-specific `.claude/rules/` files by analyzing the codebase and interviewing the user about conventions and preferences.

## Design Principles

1. **Discover, don't assume**: Detect the stack through analysis, not hardcoded file lists
2. **Domain-agnostic**: Works for any project type (web, mobile, CLI, embedded, etc.)
3. **User-driven**: Interview to understand conventions that can't be detected
4. **Pattern-based**: Generate rules based on discovered patterns, not technology categories

---

## Phase Overview

```
Phase 1: Stack Detection    → Discover technologies through analysis
Phase 2: Pattern Analysis   → Find existing conventions in code
Phase 3: User Interview     → Gather preferences through questions
Phase 4: Rule Generation    → Create .claude/rules/ files
Phase 5: Review & Confirm   → User approval
```

---

## Execution Instructions

### Phase 1: Stack Detection

**Goal:** Discover the project's technology stack through analysis.

**Use discovery patterns, not hardcoded file lists:**

```bash
# Discover project type from common indicators
ls -la *.json *.toml *.yaml *.yml *.xml *.gradle 2>/dev/null | head -20

# Discover language from file extensions
find . -maxdepth 3 -type f -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" 2>/dev/null | head -5

# Discover build/package configuration
ls -la package*.json Cargo.toml go.mod pyproject.toml pom.xml build.gradle 2>/dev/null
```

**Delegate to `code-explorer` agent if needed:**

```
Launch code-explorer agent to analyze:
- Primary language(s) used
- Project structure and organization
- Package manager and dependencies
- Testing setup (if present)
- Build/lint configuration (if present)

Thoroughness: quick
Output: Stack profile summary
```

**Output:** Stack summary for user confirmation (don't assume specific frameworks).

### Phase 2: Pattern Analysis

**Goal:** Discover existing conventions through code analysis, not assumptions.

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

**Check for existing configuration:**

```bash
# Check for existing Claude configuration
ls -la .claude/ CLAUDE.md .claude/rules/ 2>/dev/null

# Check for quality tool configs (general patterns)
ls -la .*rc* *.config.* 2>/dev/null | head -10

# Check for editor configs
ls -la .editorconfig .vscode/ .idea/ 2>/dev/null
```

**Output:** Discovered patterns with specific examples from the codebase.

### Phase 3: User Interview

**Goal:** Gather preferences that can't be detected through code analysis.

**Use domain-agnostic questions:**

#### 3.1 Code Style Preferences

```
Based on detected stack: [stack summary]

Question: "What code style conventions should Claude follow?"
Header: "Code Style"
Options:
- "Follow existing tool configuration (detected: [tool])"
- "Match patterns found in codebase"
- "Let me specify custom rules"
- "Use language/framework defaults"
```

#### 3.2 Testing Approach

```
Question: "What testing approach should Claude use?"
Header: "Testing"
Options:
- "Match existing test patterns (detected: [pattern])"
- "Test-Driven Development (write tests first)"
- "Tests after implementation"
- "Let me specify test requirements"
```

#### 3.3 Documentation Style

```
Question: "What documentation style should Claude follow?"
Header: "Docs"
Options:
- "Document public APIs only"
- "Comprehensive documentation"
- "Minimal (self-documenting code)"
- "Match existing documentation style"
```

#### 3.4 Architecture Boundaries

```
Question: "Are there areas that should have different rules?"
Header: "Boundaries"
MultiSelect: true
Options:
- "Different rules for different parts of codebase"
- "Some areas require extra review/care"
- "Strict validation in certain areas"
- "No special boundaries needed"
```

If user selects boundaries, follow up to understand which paths/patterns.

#### 3.5 Security Considerations

```
Question: "What security considerations apply?"
Header: "Security"
MultiSelect: true
Options:
- "Authentication/authorization code needs extra care"
- "Input validation is critical"
- "Handles sensitive data (PII, credentials)"
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

### Phase 4: Rule Generation

**Goal:** Generate `.claude/rules/` files based on analysis and interview.

**Create directory:**

```bash
mkdir -p .claude/rules
```

**Generate rule files based on findings (not hardcoded templates):**

#### 4.1 General Rules (always created)

Create `.claude/rules/general.md`:

```markdown
# Project: [Project Name from analysis]

## Technology Stack
[Detected stack - discovered, not assumed]

## Code Style
[From interview + detected patterns]

## Testing
[From interview + detected patterns]

## Documentation
[From interview]

## Additional Context
[Any custom rules from interview]
```

#### 4.2 Path-Conditional Rules (if boundaries identified)

Only create path-specific rules if:
1. User indicated different rules for different areas
2. Analysis found clear separation in codebase

**Discover paths from analysis, don't hardcode:**

```bash
# Find actual directory structure
find . -maxdepth 2 -type d | grep -v node_modules | grep -v .git | head -20
```

Create path-conditional rules using discovered paths:

```yaml
---
paths:
  - "[discovered path pattern]"
---

# [Area] Development Rules

[Rules specific to this area from interview]
```

### Phase 5: Review & Confirm

**Goal:** Present generated rules for user approval.

**Display summary:**

```markdown
## Generated Rules Summary

### Files Created
| File | Scope | Key Rules |
|------|-------|-----------|
| `general.md` | All files | [summary] |
| [path-specific if created] | [paths] | [summary] |

### Rule Highlights
- [Key rule 1 based on interview]
- [Key rule 2 based on analysis]

Options:
1. Apply these rules as-is
2. Review and edit before applying
3. Regenerate with different preferences
4. Cancel
```

**Final output:**

```markdown
Rules created in .claude/rules/

These rules will be automatically loaded when Claude works on this project.

Next steps:
1. Review generated rules in .claude/rules/
2. Add to version control: git add .claude/rules/
3. Share with team for consistent AI assistance
```

---

## Usage Examples

```bash
# Full setup with interview
/project-setup

# Focus on specific area (will ask focused questions)
/project-setup testing
/project-setup security

# Regenerate after codebase changes
/project-setup
```

---

## Rules

- ALWAYS discover stack through analysis, not hardcoded file lists
- ALWAYS use domain-agnostic interview questions
- ALWAYS confirm detected patterns with user
- ALWAYS use discovered paths for path-conditional rules
- NEVER assume specific framework/library names
- NEVER hardcode path patterns (discover them)
- NEVER create rules for technologies not detected
- NEVER skip user confirmation before creating files
