---
name: git-mastery
description: |
  Semantic commit messages following Conventional Commits, changelog management, and git workflows. Use when:
  - Committing changes and need proper commit message format
  - Managing changelog or release notes
  - Working with git branches, merges, or rebases
  - Creating pull requests or reviewing git history
  - Need semantic versioning guidance
  Trigger phrases: commit message, conventional commits, changelog, git workflow, semantic version, feat:, fix:, pull request
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

## Undo & Recovery Patterns

### Scenario-Based Recovery

| Situation | Command | Risk Level |
|-----------|---------|------------|
| Undo last commit (keep changes) | `git reset --soft HEAD~1` | Safe |
| Undo last commit (discard changes) | `git reset --hard HEAD~1` | Destructive |
| Undo specific commit (public) | `git revert <hash>` | Safe |
| Discard unstaged changes | `git checkout -- <file>` | Destructive |
| Discard all local changes | `git reset --hard HEAD` | Destructive |
| Recover deleted branch | `git reflog` + `git checkout -b <branch> <hash>` | Safe |

### Safe Rollback Workflow

```bash
# 1. Check current state
git status
git log --oneline -5

# 2. Create backup branch (always!)
git branch backup-$(date +%Y%m%d-%H%M%S)

# 3. Perform rollback
git revert <commit-hash>  # For pushed commits
# OR
git reset --soft HEAD~1   # For unpushed commits

# 4. Verify
git log --oneline -5
git diff HEAD~1
```

### Stash for Temporary Storage

```bash
# Save current work
git stash push -m "WIP: feature description"

# List stashes
git stash list

# Restore latest
git stash pop

# Restore specific
git stash apply stash@{2}

# Drop stash
git stash drop stash@{0}
```

### Emergency Recovery

```bash
# Find lost commits
git reflog

# Recover lost commit
git cherry-pick <hash>

# Recover deleted file from history
git checkout <commit-hash> -- path/to/file
```

### What NOT to Do

| Dangerous Action | Why | Safe Alternative |
|------------------|-----|------------------|
| `git push --force` on shared branch | Overwrites others' work | `git revert` + regular push |
| `git reset --hard` without backup | Permanent data loss | Create backup branch first |
| `git clean -fd` without review | Deletes untracked files | `git clean -fdn` (dry-run) first |

## Rules (L1 - Hard)

Critical for data safety and team collaboration. Violations can cause data loss or disrupt others.

- NEVER force push to shared branches (overwrites others' work)
- ALWAYS create backup branch before destructive operations
- NEVER use `--hard` reset without understanding consequences
- NEVER commit secrets or credentials

## Defaults (L2 - Soft)

Important for consistency and quality. Override with reasoning when appropriate.

- Use conventional commit format for semantic versioning
- Check git status before committing
- Avoid committing unrelated changes together
- Write meaningful descriptions in commit messages
- Update changelog for user-facing changes

## Guidelines (L3)

Recommendations for better git hygiene.

- Consider using `git add -p` for partial staging
- Prefer rebase for linear history on feature branches
- Consider signing commits for verified authorship
