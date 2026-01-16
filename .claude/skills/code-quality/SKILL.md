---
name: code-quality
description: Runs linting, formatting, and type checking. Use after writing or editing code to ensure quality standards are met.
allowed-tools: Bash, Read, Glob
model: haiku
user-invocable: true
---

# Code Quality Fixer

Automatically run linting, formatting, and type checking to ensure code quality.

## Workflow

### Step 1: Identify Changed Files
```bash
# Get recently modified files
git diff --name-only HEAD
git diff --name-only --cached
```

### Step 2: Run Linting
```bash
# ESLint with auto-fix
npm run lint -- --fix

# If specific files provided, target them
npm run lint -- --fix src/path/to/file.ts
```

### Step 3: Run Formatting
```bash
# Prettier formatting
npm run format

# Or directly
npx prettier --write "src/**/*.{ts,tsx,js,jsx}"
```

### Step 4: Type Checking
```bash
# TypeScript compilation check
npx tsc --noEmit
```

### Step 5: Verify Build
```bash
# Ensure build still works
npm run build
```

## Error Resolution

If errors persist after auto-fix:
1. Read the specific error message
2. Locate the file and line number
3. Analyze the issue
4. Apply manual fix
5. Re-run linting to verify

**Maximum retry attempts: 3**

If still failing after 3 attempts, report the remaining errors to the user with:
- File path
- Line number
- Error message
- Suggested fix

## Success Criteria

- All lint rules pass
- No TypeScript errors
- Build completes successfully
