---
name: migration
description: |
  Safe database schema migration patterns across any ORM/database stack. Use when:
  - Making database schema changes (add/remove columns, tables)
  - Running migrations with Prisma, Drizzle, Alembic, Django, Goose, or Flyway
  - Managing database versioning and rollbacks
  - Assessing migration risk or planning safe deployment
  - Dealing with schema drift or migration conflicts
  Trigger phrases: database migration, schema change, add column, prisma migrate, alembic, django migrate, rollback migration, schema drift
allowed-tools: Bash, Read, AskUserQuestion, Write
model: sonnet
user-invocable: true
---

# Database Migration

Safe schema migration patterns across different ORMs and databases.

## Migration Safety Checklist

Before any migration:

- [ ] Backup exists or can be restored
- [ ] Migration is reversible (down migration)
- [ ] No data loss risk identified
- [ ] Tested in non-production environment
- [ ] Schema drift checked

## ORM Detection & Commands

### Detect ORM

```bash
# Prisma (JavaScript/TypeScript)
ls prisma/schema.prisma 2>/dev/null

# Drizzle (JavaScript/TypeScript)
ls drizzle.config.* 2>/dev/null

# SQLAlchemy/Alembic (Python)
ls alembic.ini alembic/ 2>/dev/null

# Django (Python)
ls */migrations/ manage.py 2>/dev/null

# GORM/Goose (Go)
ls migrations/*.sql 2>/dev/null

# Diesel (Rust)
ls diesel.toml migrations/ 2>/dev/null

# Flyway (Java)
ls src/main/resources/db/migration/ 2>/dev/null
```

### Migration Commands

#### Prisma (JavaScript/TypeScript)

```bash
# Check for drift
npx prisma migrate diff --from-schema-datamodel prisma/schema.prisma --to-schema-datasource prisma/schema.prisma

# Create migration
npx prisma migrate dev --name <migration_name>

# Apply migration (production)
npx prisma migrate deploy

# Generate client
npx prisma generate

# Reset database (dev only!)
npx prisma migrate reset
```

#### Drizzle (JavaScript/TypeScript)

```bash
# Generate migration
npx drizzle-kit generate

# Apply migration
npx drizzle-kit migrate

# Push (direct schema sync, dev only)
npx drizzle-kit push
```

#### Alembic (Python)

```bash
# Create migration
alembic revision --autogenerate -m "description"

# Apply migration
alembic upgrade head

# Rollback
alembic downgrade -1

# Check current version
alembic current
```

#### Django (Python)

```bash
# Create migration
python manage.py makemigrations

# Apply migration
python manage.py migrate

# Show migrations
python manage.py showmigrations

# Rollback
python manage.py migrate app_name 0001
```

#### Goose (Go)

```bash
# Create migration
goose create <name> sql

# Apply
goose up

# Rollback
goose down

# Status
goose status
```

#### Flyway (Java)

```bash
# Apply migrations
./mvnw flyway:migrate

# Status
./mvnw flyway:info

# Repair
./mvnw flyway:repair
```

## Safe Migration Patterns

### Adding Column

```sql
-- Safe: Add nullable column
ALTER TABLE users ADD COLUMN middle_name VARCHAR(100);

-- Safe: Add with default
ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';

-- Then backfill if needed
UPDATE users SET status = 'active' WHERE status IS NULL;

-- Then add constraint
ALTER TABLE users ALTER COLUMN status SET NOT NULL;
```

### Removing Column

```sql
-- Step 1: Stop using column in code
-- Step 2: Deploy code change
-- Step 3: Drop column
ALTER TABLE users DROP COLUMN deprecated_field;
```

### Renaming Column

```sql
-- Step 1: Add new column
ALTER TABLE users ADD COLUMN full_name VARCHAR(200);

-- Step 2: Copy data
UPDATE users SET full_name = name;

-- Step 3: Deploy code to use new column
-- Step 4: Drop old column
ALTER TABLE users DROP COLUMN name;
```

### Adding Index

```sql
-- Use CONCURRENTLY for large tables (PostgreSQL)
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|------------|
| Add nullable column | Low | None needed |
| Add non-null column | Medium | Add with default or backfill |
| Drop column | High | Ensure code doesn't use it |
| Rename column | High | Use add/copy/drop pattern |
| Change column type | High | Test data compatibility |
| Add index | Low-Medium | Use CONCURRENTLY if large |
| Drop index | Low | Verify not needed for queries |

## Rollback Strategy

Always have a rollback plan:

```bash
# Most ORMs support down migrations
# Test rollback before applying in production

# Example: Prisma
npx prisma migrate resolve --rolled-back <migration_name>

# Example: Alembic
alembic downgrade -1

# Manual rollback script
# Keep migrations/rollback/<migration_name>.sql
```

## Production Checklist

Before deploying to production:

1. [ ] Migration tested locally
2. [ ] Migration tested in staging
3. [ ] Backup created/verified
4. [ ] Rollback plan documented
5. [ ] Downtime window scheduled (if needed)
6. [ ] Team notified
7. [ ] Monitoring in place

## Rules

- ALWAYS backup before migration
- ALWAYS test migrations in staging first
- NEVER run destructive migrations without review
- ALWAYS have a rollback plan
- NEVER assume migrations are reversible
- ALWAYS check for schema drift
- NEVER run reset/drop in production
