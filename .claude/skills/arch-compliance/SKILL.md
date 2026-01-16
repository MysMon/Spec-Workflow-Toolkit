---
name: arch-compliance
description: Validates architectural boundaries and dependency rules using dependency-cruiser. Use to check Clean Architecture compliance and detect forbidden dependencies.
allowed-tools: Bash, Read, Write
model: sonnet
user-invocable: true
---

# Architectural Compliance Check

Validate that code adheres to architectural boundaries and dependency rules using dependency-cruiser.

## Prerequisites

Install dependency-cruiser:
```bash
npm install -D dependency-cruiser
npx depcruise --init
```

## Workflow

### Step 1: Run Dependency Analysis
```bash
# Full analysis
npx depcruise src --config .dependency-cruiser.js

# Output as JSON for detailed analysis
npx depcruise src --config .dependency-cruiser.js --output-type json > deps.json

# Generate visual graph
npx depcruise src --config .dependency-cruiser.js --output-type dot | dot -T svg > dependency-graph.svg
```

### Step 2: Check for Violations

Common violation types:
- **Forbidden**: Direct violation of dependency rule
- **Circular**: Circular dependency detected
- **Orphan**: Module not imported by anything
- **Not Reachable**: Module can't reach its dependencies

### Step 3: Analyze Results

For each violation:
1. Identify the source and target modules
2. Determine the rule being violated
3. Assess the severity
4. Recommend fix

## Configuration

### .dependency-cruiser.js
```javascript
/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    // Clean Architecture: UI should not import DB
    {
      name: 'no-ui-to-db',
      severity: 'error',
      from: { path: '^src/components' },
      to: { path: '^src/database|^src/repositories' },
    },
    // Clean Architecture: Domain should not import Infrastructure
    {
      name: 'no-domain-to-infra',
      severity: 'error',
      from: { path: '^src/domain' },
      to: { path: '^src/infrastructure' },
    },
    // No circular dependencies
    {
      name: 'no-circular',
      severity: 'error',
      from: {},
      to: { circular: true },
    },
    // No importing test files in production code
    {
      name: 'no-test-in-prod',
      severity: 'error',
      from: { pathNot: '\\.test\\.|__tests__' },
      to: { path: '\\.test\\.|__tests__' },
    },
    // Node built-ins only in specific places
    {
      name: 'no-node-builtins-in-frontend',
      severity: 'error',
      from: { path: '^src/components|^src/pages' },
      to: { dependencyTypes: ['core'] },
    },
  ],
  options: {
    doNotFollow: {
      path: 'node_modules',
    },
    tsConfig: {
      fileName: './tsconfig.json',
    },
    reporterOptions: {
      dot: {
        theme: {
          graph: { rankdir: 'TB' },
        },
      },
    },
  },
};
```

## Architecture Layers

### Clean Architecture Boundaries
```
┌─────────────────────────────────────┐
│           Presentation              │ ← Can only import from Application
│  (components, pages, controllers)   │
├─────────────────────────────────────┤
│           Application               │ ← Can only import from Domain
│     (use cases, services)           │
├─────────────────────────────────────┤
│            Domain                   │ ← No external dependencies
│   (entities, value objects)         │
├─────────────────────────────────────┤
│          Infrastructure             │ ← Implements Domain interfaces
│  (repositories, external APIs)      │
└─────────────────────────────────────┘
```

### Allowed Dependencies
```
Presentation → Application → Domain ← Infrastructure
                    ↓
               Infrastructure (implements interfaces)
```

## Report Format

When violations found:
```markdown
## Architectural Compliance Report

### Summary
- **Total Violations**: 3
- **Critical**: 1
- **Warnings**: 2

### Critical Violations

#### [ARCH-001] UI Layer importing Database
- **Rule**: no-ui-to-db
- **From**: `src/components/UserList.tsx`
- **To**: `src/database/prisma.ts`
- **Fix**: Use a service layer to abstract database access

### Warnings

#### [ARCH-002] Circular Dependency
- **Modules**: `src/services/auth.ts` ↔ `src/services/user.ts`
- **Fix**: Extract shared logic to a separate module
```

## Fixing Violations

### Breaking Circular Dependencies
1. Identify shared functionality
2. Extract to new module
3. Both modules import from new module

### Fixing Layer Violations
1. Create interface in Domain layer
2. Implement interface in Infrastructure layer
3. Inject dependency via DI container

## Rules

- NEVER approve code with critical architectural violations
- ALWAYS document exceptions if rules must be bypassed
- NEVER modify architectural rules without architect approval
- ALWAYS fix violations before merging to main
- ALWAYS regenerate dependency graph after significant changes
