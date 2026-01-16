---
name: git-mastery
description: Semantic commit messages following Conventional Commits, changelog management, and git workflows. Use for committing changes with proper format and maintaining release history.
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
model: haiku
user-invocable: true
---

# Git Mastery

Semantic commit messages and git best practices.

## Conventional Commits

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(auth): add OAuth2 login` |
| `fix` | Bug fix | `fix(api): handle null response` |
| `docs` | Documentation | `docs: update README setup` |
| `style` | Formatting (no logic change) | `style: fix indentation` |
| `refactor` | Code change (no feature/fix) | `refactor: extract helper` |
| `perf` | Performance improvement | `perf: optimize query` |
| `test` | Add/fix tests | `test: add user service tests` |
| `chore` | Maintenance | `chore: update dependencies` |
| `ci` | CI/CD changes | `ci: add GitHub Actions` |
| `build` | Build system | `build: update webpack config` |

### Scope Examples

- `auth`, `api`, `ui`, `db`, `config`
- Feature name or component name
- Optional but recommended

### Description Rules

- Imperative mood: "add" not "added"
- No period at end
- Max 50 characters
- Lowercase start

## Workflow

### Step 1: Review Changes

```bash
# See what's changed
git status
git diff --staged
git diff

# Recent commit style
git log --oneline -10
```

### Step 2: Stage Changes

```bash
# Stage specific files
git add path/to/file

# Stage all changes
git add .

# Interactive staging
git add -p
```

### Step 3: Generate Commit Message

Analyze changes and create semantic message:

```bash
# Single feature
git commit -m "feat(users): add email verification flow"

# Bug fix with body
git commit -m "fix(api): handle timeout on external calls

- Add retry logic with exponential backoff
- Set 30s timeout for external API
- Log failures for monitoring"

# Breaking change
git commit -m "feat(auth)!: require MFA for admin users

BREAKING CHANGE: Admin users must now configure MFA before accessing admin panel."
```

### Step 4: Verify

```bash
git log --oneline -1
git show --stat
```

## Changelog Management

### Keep a Changelog Format

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- New feature X (#123)

### Changed
- Updated behavior Y

### Fixed
- Bug in component Z (#456)

## [1.2.0] - 2024-01-15

### Added
- Feature A
- Feature B

### Fixed
- Critical bug C
```

### Update Changelog

When making changes:

1. Add entry under `[Unreleased]`
2. Use appropriate category (Added, Changed, Fixed, etc.)
3. Reference issue/PR numbers
4. Keep entries concise

## Git Best Practices

### Branch Naming

```
feature/user-authentication
fix/login-timeout
docs/api-reference
refactor/database-layer
```

### Commit Hygiene

- One logical change per commit
- Commit early, commit often
- Never commit secrets
- Review diff before committing

### Interactive Rebase (for cleanup)

```bash
# Squash last 3 commits
git rebase -i HEAD~3

# In editor:
pick abc123 First commit
squash def456 Second commit
squash ghi789 Third commit
```

## Commit Message Templates

### Feature

```
feat(<scope>): <what the feature does>

- Implementation detail 1
- Implementation detail 2

Closes #<issue>
```

### Bug Fix

```
fix(<scope>): <what was fixed>

<Why the bug occurred and how it was fixed>

Fixes #<issue>
```

### Breaking Change

```
feat(<scope>)!: <breaking change description>

BREAKING CHANGE: <detailed explanation of what breaks>

Migration: <how to migrate>
```

## Rules

- ALWAYS use conventional commit format
- ALWAYS check git status before committing
- NEVER commit unrelated changes together
- ALWAYS write meaningful descriptions
- NEVER force push to shared branches
- ALWAYS update changelog for user-facing changes
