---
description: "Audit documentation for drift from code - detect outdated docs, missing sections, and inconsistencies"
argument-hint: "[path or --scope api|readme|all]"
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite
---

# /doc-audit - Documentation Drift Detection

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

Systematically audit documentation against code to detect outdated content, missing sections, and inconsistencies.

## Design Principles

1. **Code is truth**: Code behavior is the source of truth, docs should match
2. **Scope appropriately**: Focus audit on high-impact documentation
3. **Actionable findings**: Report specific issues with clear fixes
4. **Prioritize by impact**: User-facing docs take priority

---

## When to Use

- Before release to ensure docs are current
- After significant refactoring
- As part of PR review process
- Periodic documentation health checks

## Input Formats

```bash
# Audit specific documentation file
/doc-audit docs/API.md

# Audit by scope
/doc-audit --scope api       # API documentation
/doc-audit --scope readme    # README files
/doc-audit --scope all       # All documentation

# Audit documentation for specific code
/doc-audit --for src/services/auth.ts
```

---

## Execution Instructions

### Phase 1: Documentation Discovery

**Goal:** Identify documentation files to audit.

**Delegate documentation discovery to code-explorer:**

```
Launch code-explorer agent:
Task: Discover documentation files in the codebase
Analyze:
- All markdown files (excluding .git/, node_modules/)
- Common documentation locations (README.md, docs/, CONTRIBUTING.md, CHANGELOG.md, API.md)
- Documentation structure and organization
Thoroughness: quick
Output: List of documentation files with categories (user-facing, API, contributing, etc.)
```

Use the agent's output for categorization. Do NOT run find/ls commands manually.

**Categorize documentation:**

| Category | Files | Priority |
|----------|-------|----------|
| **User-facing** | README.md, docs/getting-started.md | High |
| **API** | API.md, docs/api/*.md, OpenAPI specs | High |
| **Contributing** | CONTRIBUTING.md, docs/development.md | Medium |
| **Architecture** | docs/architecture/*.md, ADRs | Medium |
| **Changelog** | CHANGELOG.md, HISTORY.md | Low |

**Create audit scope** based on input or ask user:

```
Question: "Which documentation should I audit?"
Header: "Scope"
Options:
- "All documentation" (Recommended for releases)
- "README and user guides only"
- "API documentation only"
- "Let me specify files"
```

### Phase 2: Code-Documentation Mapping

**Goal:** Map documentation sections to corresponding code.

**For each documentation file, launch code-explorer:**

```
Launch code-explorer agent:

Analyze this documentation and identify corresponding code:

Documentation: [file content or path]

Tasks:
1. Extract all code references (file paths, function names, classes)
2. Identify setup/installation commands mentioned
3. Find API endpoints or interfaces documented
4. List configuration options mentioned
5. Note any version numbers or dependencies

Return a mapping table in this format:
| Doc Section | Code Reference | File Path | Status |
|-------------|---------------|-----------|--------|
| [section] | [reference] | [path] | TBD |

Thoroughness: medium
```

Use the agent's mapping table output directly. Do NOT build mapping tables manually.

### Phase 3: Drift Detection

**Goal:** Compare documentation claims against actual code.

**For each mapping, verify accuracy:**

**Installation/Setup Drift:**
```
Launch code-explorer:

Verify these setup instructions are accurate:

Instructions from docs:
[setup steps]

Check:
1. Do the commands work?
2. Are dependencies correct and current?
3. Are environment variables documented?
4. Is the order of steps correct?
```

**API Drift:**
```
Launch code-explorer:

Compare documented API with implementation:

Documented endpoint:
[API doc section]

Check:
1. Does endpoint exist?
2. Do parameters match?
3. Are response types accurate?
4. Are error codes documented?
```

**Configuration Drift:**
```
Verify configuration options:

Documented options:
[config section]

Check:
1. Do all options exist in code?
2. Are defaults accurate?
3. Are any options missing from docs?
```

### Phase 4: Finding Classification

**Goal:** Categorize and prioritize findings.

**Classify each finding:**

| Severity | Description | Examples |
|----------|-------------|----------|
| **Critical** | Docs mislead users, cause errors | Wrong install command, deprecated API |
| **High** | Significant inaccuracy | Missing required step, wrong parameter |
| **Medium** | Minor inaccuracy | Outdated example, typo in code |
| **Low** | Cosmetic or enhancement | Style inconsistency, could be clearer |

**Confidence scoring (0-100):**
- 90-100: Definite drift, verified in code
- 70-89: Likely drift, strong evidence
- 50-69: Possible drift, needs verification
- Below 50: Uncertain, may be false positive

**Filter findings:** Report only >= 80 confidence by default.

### Phase 5: Report Generation

**Goal:** Present actionable audit results.

```markdown
## Documentation Audit Report

### Summary
- **Files Audited**: [N]
- **Drift Detected**: [N] issues
- **Critical**: [N] | **High**: [N] | **Medium**: [N] | **Low**: [N]

### Critical Issues (Must Fix)

#### Issue 1: [Title] (Confidence: 95)
**File**: `README.md`, Line 45
**Type**: Installation drift
**Current Doc**:
```
npm install -g old-cli-name
```
**Actual**:
```
npm install -g new-cli-name
```
**Fix**: Update package name to `new-cli-name`

---

### High Priority Issues

#### Issue 2: [Title] (Confidence: 88)
...

### Medium Priority Issues
...

### Recommendations

1. Update installation instructions in README.md
2. Regenerate API documentation from OpenAPI spec
3. Add missing configuration options to docs/config.md

### Verification Checklist

After updates, verify:
- [ ] Installation steps work on clean environment
- [ ] API examples return expected responses
- [ ] Configuration options match code defaults
```

### Phase 6: User Decision

**Goal:** Determine next steps.

```
Question: "Audit complete. Found [N] issues. What would you like to do?"
Header: "Action"
Options:
- "Fix all issues automatically" (Recommended for <10 issues)
- "Fix critical issues only"
- "Show detailed report and let me decide"
- "Export report to file"
```

**If fixing automatically:**

```
DELEGATE to technical-writer agent:

Update this documentation to fix the identified issues:

File: [path]
Current content: [content]

Issues to fix:
[list of issues with fixes]

Requirements:
- Preserve document structure
- Maintain consistent style
- Update only the identified sections
```

---

## Audit Patterns

### README.md Audit

Check these common drift points:
- Installation commands and dependencies
- Quick start examples
- Feature list vs actual features
- Badge links and versions
- License information

### API Documentation Audit

Check these elements:
- Endpoint paths and methods
- Request/response schemas
- Authentication requirements
- Rate limits and quotas
- Error codes and messages

### Configuration Documentation Audit

Check these elements:
- Environment variable names
- Default values
- Required vs optional settings
- Valid value ranges
- Deprecated options

---

## Integration with /code-review

This command can be invoked as part of `/code-review` for documentation-heavy PRs:

```
If PR modifies documentation or documented code:
  Consider running /doc-audit --for [modified-files]
```

---

## Rules (L1 - Hard)

- ALWAYS verify drift against actual code, not assumptions
- NEVER report issues without code evidence
- ALWAYS include specific fix recommendations
- NEVER auto-fix without user confirmation for critical docs

## Defaults (L2 - Soft)

- Use 80% confidence threshold for reporting
- Prioritize user-facing documentation (README, guides)
- Delegate analysis to code-explorer for accuracy
- Generate actionable fix recommendations

## Guidelines (L3)

- Consider running before major releases
- Prefer fixing docs near the code that changed
- Consider adding doc drift checks to CI/CD
- Keep audit scope focused for faster results
