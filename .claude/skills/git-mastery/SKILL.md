---
name: git-mastery
description: Generates semantic commit messages and manages git operations. Use for committing changes with proper conventional commit format and updating changelog.
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
model: haiku
user-invocable: true
---

# Git Mastery

Generate semantic commit messages following Conventional Commits specification and manage changelog updates.

## Conventional Commits Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types
- `feat`: New feature (MINOR version bump)
- `fix`: Bug fix (PATCH version bump)
- `docs`: Documentation only
- `style`: Formatting, no code change
- `refactor`: Code change, no feature/fix
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes
- `build`: Build system changes

### Breaking Changes
Add `!` after type or include `BREAKING CHANGE:` in footer:
```
feat!: remove deprecated API endpoint
```

## Workflow

### Step 1: Analyze Changes
```bash
# See staged changes
git diff --staged --stat
git diff --staged

# See unstaged changes
git diff --stat
```

### Step 2: Categorize Changes

Group changes by type:
- New files = likely `feat` or `test`
- Modified existing = `fix`, `refactor`, or `feat`
- Deleted files = may indicate breaking change
- Only `.md` files = `docs`
- Only test files = `test`

### Step 3: Determine Scope

Scope should reflect the affected area:
- `auth` - Authentication related
- `api` - API endpoints
- `ui` - User interface
- `db` - Database
- `config` - Configuration

### Step 4: Generate Commit Message

Template:
```
<type>(<scope>): <imperative description>

<optional body explaining what and why>

<optional footer with references>
```

Examples:
```
feat(auth): add OAuth2 login with Google

Implements OAuth2 flow using passport-google-oauth20.
Users can now sign in with their Google accounts.

Closes #123
```

```
fix(api): handle null user in profile endpoint

Previously returned 500 when user was null.
Now returns 404 with appropriate error message.

Fixes #456
```

### Step 5: Update Changelog

If changes are significant, update `CHANGELOG.md`:

```markdown
## [Unreleased]

### Added
- OAuth2 login with Google (#123)

### Fixed
- Null user handling in profile endpoint (#456)
```

### Step 6: Commit

Present message to user via `AskUserQuestion` for approval:
```
Proposed commit message:

feat(auth): add OAuth2 login with Google

[Approve] [Edit] [Cancel]
```

After approval:
```bash
git add -A  # or specific files
git commit -m "feat(auth): add OAuth2 login with Google"
```

## Rules

- ALWAYS use imperative mood ("add" not "added")
- ALWAYS keep first line under 72 characters
- NEVER include implementation details in the title
- ALWAYS reference issues when applicable
- NEVER commit sensitive data or secrets
- ALWAYS verify staged changes before committing
