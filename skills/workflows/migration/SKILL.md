---
name: migration
description: |
  Safe database schema migration patterns applicable to any ORM/database stack. Use when:
  - Making database schema changes (add/remove columns, tables)
  - Running migrations safely
  - Managing database versioning and rollbacks
  - Assessing migration risk or planning safe deployment
  - Dealing with schema drift or migration conflicts
  Trigger phrases: database migration, schema change, add column, migration rollback, schema drift
allowed-tools: Bash, Read, AskUserQuestion, Write, Glob, Grep, WebSearch, WebFetch
model: sonnet
user-invocable: true
---

# Database Migration

Safe schema migration patterns applicable to any ORM and database. This skill defines **migration principles and safety patterns**, not specific ORM commands.

## Design Principles

1. **Discover project tools**: Detect which ORM/migration tool the project uses
2. **Research commands**: Use WebSearch for current ORM command syntax
3. **Safety first**: Follow safe migration patterns regardless of tool
4. **Always have rollback**: Plan for reverting changes

---

## Migration Safety Checklist

Before any migration:

- [ ] Backup exists or can be restored
- [ ] Migration is reversible (down migration defined)
- [ ] No data loss risk identified
- [ ] Tested in non-production environment
- [ ] Schema drift checked

---

## Tool Discovery

### Step 1: Detect Migration Tool

Look for migration-related configuration without assuming specific tools:

```bash
# Check for migration directories and configs
ls -la migrations/ db/migrate/ alembic/ prisma/ drizzle/ 2>/dev/null
ls -la *migrate* *migration* *.prisma diesel.toml 2>/dev/null

# Check for migration tools in dependencies
grep -E 'prisma|drizzle|alembic|django|sequelize|typeorm|knex|goose|diesel|flyway' \
  package.json pyproject.toml requirements.txt go.mod Cargo.toml pom.xml 2>/dev/null
```

### Step 2: Find Project Commands

```bash
# Check for migration scripts
grep -E 'migrate|migration|db:' package.json 2>/dev/null
grep -E '^(migrate|db)' Makefile 2>/dev/null
```

### Step 3: Research Current Commands

If tool is detected but commands are unfamiliar:

```
WebSearch: "[ORM/tool name] migration commands [year]"
WebFetch: [official docs] → "Extract migration CLI commands"
```

---

## Safe Migration Patterns

These patterns apply to **any** database and migration tool:

### Adding a Column

**Safe approach (2-step for NOT NULL):**

```
Step 1: Add column as nullable
Step 2: Backfill data if needed
Step 3: Add NOT NULL constraint (if required)
```

**Why**: Adding NOT NULL column directly fails on existing rows.

### Removing a Column

**Safe approach (3-step):**

```
Step 1: Stop using column in application code
Step 2: Deploy application change
Step 3: Remove column in migration
```

**Why**: Removing column while code uses it causes errors.

### Renaming a Column

**Safe approach (4-step):**

```
Step 1: Add new column (copy of old)
Step 2: Copy data from old to new
Step 3: Update code to use new column
Step 4: Remove old column
```

**Why**: Renaming directly breaks running code during deployment.

### Adding an Index

**Safe approach:**

```
- For small tables: Direct index creation
- For large tables: Use concurrent/online index creation
```

**Why**: Index creation locks table; concurrent creation avoids downtime.

Note: Concurrent index syntax varies by database - research for your specific database.

---

## Risk Assessment

| Change Type | Risk Level | Mitigation |
|-------------|------------|------------|
| Add nullable column | Low | None needed |
| Add column with default | Low | Check default value |
| Add NOT NULL column | Medium | Add nullable first, backfill, then constrain |
| Drop column | High | Ensure code doesn't use it |
| Rename column | High | Use add/copy/drop pattern |
| Change column type | High | Test data compatibility |
| Add index (small table) | Low | None needed |
| Add index (large table) | Medium | Use concurrent creation |
| Drop index | Low | Verify not needed for queries |

---

## Rollback Strategy

**Always plan for rollback:**

1. **Reversible migrations**: Define both up and down migrations
2. **Test rollback**: Verify down migration works before deploying
3. **Keep rollback scripts**: Store manual rollback SQL if needed
4. **Document rollback steps**: Include in deployment checklist

### Rollback Commands

Discover the rollback command for your migration tool:

```
WebSearch: "[migration tool] rollback command"
```

---

## Production Checklist

Before deploying migrations to production:

1. [ ] Migration tested locally
2. [ ] Migration tested in staging/preview
3. [ ] Database backup created/verified
4. [ ] Rollback plan documented and tested
5. [ ] Downtime window scheduled (if needed)
6. [ ] Team notified of migration
7. [ ] Monitoring ready for issues
8. [ ] Application code compatible with both old and new schema

---

## Common Issues

### Schema Drift

When database differs from migrations:

1. Compare current schema to expected schema
2. Identify divergent changes
3. Either:
   - Generate migration to match current state
   - Reset to migration state (dev only)

### Migration Conflicts

When multiple migrations conflict:

1. Pull latest migrations
2. Check for ordering issues
3. Resolve conflicts in migration files
4. Re-run migrations

### Failed Migration

When migration fails mid-way:

1. Check what was applied
2. Manually fix or rollback partial changes
3. Fix migration and re-attempt
4. Mark migration as resolved (tool-specific)

---

## Rules

- ALWAYS backup before migration
- ALWAYS test migrations in non-production first
- ALWAYS have a rollback plan
- ALWAYS discover the project's migration tool before running commands
- ALWAYS use WebSearch to verify current command syntax
- NEVER run destructive migrations without explicit confirmation
- NEVER assume migrations are automatically reversible
- NEVER run reset/drop commands in production
- NEVER hardcode ORM-specific commands (discover them)
