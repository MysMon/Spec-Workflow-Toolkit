---
name: safe-migration
description: Safely manages database schema changes using Prisma. Use when creating or applying database migrations. Enforces backups, drift detection, and verification.
allowed-tools: Bash, Read, Write, AskUserQuestion
model: sonnet
user-invocable: true
---

# Safe Database Migration Protocol

Safely manage database schema changes with proper validation and rollback procedures.

## Prerequisites

- Ensure `.env` is loaded with correct `DATABASE_URL`
- Verify database connection before proceeding

## Workflow

### Step 1: Schema Validation
```bash
# Validate Prisma schema syntax
npx prisma validate
```

### Step 2: Drift Detection
```bash
# Check for schema drift between database and Prisma schema
npx prisma migrate diff \
  --from-schema-datasource prisma/schema.prisma \
  --to-schema-datamodel prisma/schema.prisma \
  --exit-code
```

If drift is detected (exit code 2):
- **STOP** and report to user
- Do not proceed without explicit approval

### Step 3: Generate Migration
```bash
# Create migration file without applying
npx prisma migrate dev --create-only --name <descriptive-name>
```

Naming convention: `<action>_<entity>_<detail>`
- Examples: `add_user_email_verified`, `create_orders_table`, `remove_legacy_field`

### Step 4: Review Generated SQL

**CRITICAL**: Read the generated SQL file in `prisma/migrations/`

Check for destructive statements:
- `DROP TABLE`
- `DROP COLUMN`
- `ALTER TABLE ... DROP`
- `TRUNCATE`
- `DELETE`

If destructive statements found:
```
Use AskUserQuestion to get explicit confirmation:

"This migration contains destructive changes:
- DROP COLUMN 'legacy_field' from 'users' table

This will permanently delete data. Proceed?"

Options: [Proceed] [Cancel] [Review SQL]
```

### Step 5: Apply Migration

Only after approval:
```bash
# Apply the migration
npx prisma migrate deploy

# Regenerate Prisma Client
npx prisma generate
```

### Step 6: Verification
```bash
# Verify migration status
npx prisma migrate status

# Quick sanity check (example)
npx prisma db execute --stdin <<< "SELECT COUNT(*) FROM _prisma_migrations WHERE applied_steps_count > 0"
```

## Rollback Procedure

If migration fails:
1. Check the error message
2. If partially applied, assess state
3. Create a down migration if needed
4. Document the failure

```bash
# Check migration status
npx prisma migrate status

# If needed, reset (DEVELOPMENT ONLY)
npx prisma migrate reset
```

**WARNING**: `migrate reset` destroys all data. Never use in production.

## Safety Rules

- NEVER apply migrations without reviewing generated SQL
- NEVER skip drift detection
- ALWAYS create backups before destructive migrations in production
- ALWAYS verify migration success after applying
- NEVER use `migrate reset` in production environments
