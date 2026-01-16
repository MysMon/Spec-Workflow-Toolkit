---
name: stack-detector
description: Automatically detects project technology stack from configuration files and source code. Use to identify the programming language, frameworks, and tools used in a project before applying stack-specific patterns.
allowed-tools: Read, Glob, Grep, Bash
model: haiku
user-invocable: true
---

# Stack Detector

Automatically identifies the technology stack of a project by analyzing configuration files and source code patterns.

## Detection Process

### Step 1: Scan for Configuration Files

Look for these indicator files in the project root:

```bash
# Run these checks (presence indicates stack)
ls -la package.json         # JavaScript/Node.js
ls -la pyproject.toml       # Python (modern)
ls -la requirements.txt     # Python
ls -la go.mod               # Go
ls -la Cargo.toml           # Rust
ls -la pom.xml              # Java (Maven)
ls -la build.gradle         # Java (Gradle)
ls -la *.csproj             # .NET
ls -la Gemfile              # Ruby
ls -la composer.json        # PHP
ls -la pubspec.yaml         # Dart/Flutter
```

### Step 2: Identify Primary Language

| Config File | Primary Language | Package Manager |
|-------------|------------------|-----------------|
| `package.json` | JavaScript/TypeScript | npm/yarn/pnpm |
| `pyproject.toml` | Python | pip/poetry/uv |
| `requirements.txt` | Python | pip |
| `go.mod` | Go | go modules |
| `Cargo.toml` | Rust | cargo |
| `pom.xml` | Java | Maven |
| `build.gradle` | Java/Kotlin | Gradle |
| `*.csproj` | C# | dotnet |
| `Gemfile` | Ruby | bundler |
| `composer.json` | PHP | composer |
| `pubspec.yaml` | Dart | pub |

### Step 3: Detect Frameworks

#### JavaScript/TypeScript Frameworks
```bash
# Check package.json for dependencies
grep -E '"(react|vue|angular|svelte|next|nuxt|express|fastify|hono|nestjs)"' package.json
```

| Dependency | Framework Type | Category |
|------------|----------------|----------|
| `react`, `react-dom` | React | Frontend |
| `next` | Next.js | Full-stack |
| `vue` | Vue.js | Frontend |
| `nuxt` | Nuxt.js | Full-stack |
| `@angular/core` | Angular | Frontend |
| `svelte` | Svelte | Frontend |
| `express` | Express | Backend |
| `fastify` | Fastify | Backend |
| `hono` | Hono | Backend |
| `@nestjs/core` | NestJS | Backend |

#### Python Frameworks
```bash
# Check pyproject.toml or requirements.txt
grep -E '(django|flask|fastapi|starlette)' pyproject.toml requirements.txt 2>/dev/null
```

| Dependency | Framework | Category |
|------------|-----------|----------|
| `django` | Django | Full-stack |
| `flask` | Flask | Backend |
| `fastapi` | FastAPI | Backend |
| `starlette` | Starlette | Backend |

#### Go Frameworks
```bash
# Check go.mod
grep -E '(gin|echo|fiber|chi)' go.mod 2>/dev/null
```

#### Rust Frameworks
```bash
# Check Cargo.toml
grep -E '(actix|axum|rocket|warp)' Cargo.toml 2>/dev/null
```

### Step 4: Detect Database/ORM

| Indicator | Technology |
|-----------|------------|
| `prisma/schema.prisma` | Prisma ORM |
| `drizzle.config.ts` | Drizzle ORM |
| `typeorm` in deps | TypeORM |
| `sequelize` in deps | Sequelize |
| `sqlalchemy` in deps | SQLAlchemy |
| `django.db` | Django ORM |
| `gorm` in go.mod | GORM |
| `diesel` in Cargo.toml | Diesel |

### Step 5: Detect Testing Framework

| Config/Dependency | Testing Framework |
|-------------------|-------------------|
| `vitest.config.*` | Vitest |
| `jest.config.*` | Jest |
| `pytest` in deps | pytest |
| `_test.go` files | Go testing |
| `#[test]` in .rs | Rust testing |
| `cypress.config.*` | Cypress |
| `playwright.config.*` | Playwright |

### Step 6: Detect CI/CD

| File | CI/CD Platform |
|------|----------------|
| `.github/workflows/` | GitHub Actions |
| `.gitlab-ci.yml` | GitLab CI |
| `Jenkinsfile` | Jenkins |
| `.circleci/config.yml` | CircleCI |
| `azure-pipelines.yml` | Azure DevOps |

### Step 7: Detect Infrastructure

| File | Infrastructure |
|------|----------------|
| `Dockerfile` | Docker |
| `docker-compose.yml` | Docker Compose |
| `*.tf` | Terraform |
| `kubernetes/`, `k8s/` | Kubernetes |
| `serverless.yml` | Serverless Framework |

## Output Format

After detection, output a stack profile:

```yaml
Stack Profile:
  language: [Primary language]
  runtime: [Runtime version if detectable]
  package_manager: [npm|yarn|pip|cargo|etc]

  frontend:
    framework: [React|Vue|Angular|Svelte|None]
    styling: [Tailwind|CSS Modules|Styled Components|None]
    state: [Redux|Zustand|Pinia|None]

  backend:
    framework: [Express|FastAPI|Gin|None]
    orm: [Prisma|SQLAlchemy|GORM|None]
    database: [PostgreSQL|MySQL|MongoDB|None]

  testing:
    unit: [Vitest|Jest|pytest|None]
    e2e: [Playwright|Cypress|None]

  infrastructure:
    containerization: [Docker|None]
    orchestration: [Kubernetes|None]
    iac: [Terraform|None]
    ci_cd: [GitHub Actions|GitLab CI|None]

  recommended_skills:
    - [skill-name-1]
    - [skill-name-2]
```

## Skill Recommendations

Based on detected stack, recommend loading these skills:

| Stack | Recommended Skills |
|-------|-------------------|
| JavaScript/TypeScript | `javascript`, `code-quality`, `testing` |
| Python | `python`, `code-quality`, `testing` |
| Go | `go`, `code-quality`, `testing` |
| Rust | `rust`, `code-quality`, `testing` |
| With Prisma/SQL | `migration` |
| With Docker | `devops` |

## Usage

This skill is typically invoked automatically by other agents:

1. Agent receives task
2. Agent loads `stack-detector`
3. Stack profile is generated
4. Agent loads appropriate language skill
5. Agent proceeds with stack-specific patterns

## Rules

- ALWAYS check multiple indicators (don't rely on single file)
- ALWAYS report uncertainty if mixed signals
- NEVER assume stack without evidence
- ALWAYS list detected tools in output
