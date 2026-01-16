#!/bin/bash
# Stack Detector Script
# Analyzes project structure and outputs detected technologies

set -e

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

echo "=== Stack Detection Report ==="
echo "Project: $(pwd)"
echo "Date: $(date -Iseconds)"
echo ""

# Language Detection
echo "## Primary Language"
if [ -f "package.json" ]; then
    echo "- JavaScript/TypeScript (package.json found)"
    if grep -q '"typescript"' package.json 2>/dev/null; then
        echo "  - TypeScript enabled"
    fi
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    echo "- Python"
    [ -f "pyproject.toml" ] && echo "  - pyproject.toml (modern Python)"
    [ -f "requirements.txt" ] && echo "  - requirements.txt"
elif [ -f "go.mod" ]; then
    echo "- Go (go.mod found)"
elif [ -f "Cargo.toml" ]; then
    echo "- Rust (Cargo.toml found)"
elif [ -f "pom.xml" ]; then
    echo "- Java (Maven)"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "- Java/Kotlin (Gradle)"
elif ls *.csproj 1>/dev/null 2>&1; then
    echo "- C# (.NET)"
elif [ -f "Gemfile" ]; then
    echo "- Ruby"
elif [ -f "composer.json" ]; then
    echo "- PHP"
else
    echo "- Unknown (no package manager config found)"
fi
echo ""

# Framework Detection
echo "## Frameworks"
if [ -f "package.json" ]; then
    # Frontend
    grep -q '"react"' package.json 2>/dev/null && echo "- React"
    grep -q '"next"' package.json 2>/dev/null && echo "- Next.js"
    grep -q '"vue"' package.json 2>/dev/null && echo "- Vue.js"
    grep -q '"nuxt"' package.json 2>/dev/null && echo "- Nuxt"
    grep -q '"@angular/core"' package.json 2>/dev/null && echo "- Angular"
    grep -q '"svelte"' package.json 2>/dev/null && echo "- Svelte"

    # Backend
    grep -q '"express"' package.json 2>/dev/null && echo "- Express"
    grep -q '"fastify"' package.json 2>/dev/null && echo "- Fastify"
    grep -q '"hono"' package.json 2>/dev/null && echo "- Hono"
    grep -q '"@nestjs/core"' package.json 2>/dev/null && echo "- NestJS"
fi

if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    cat pyproject.toml requirements.txt 2>/dev/null | grep -qi "django" && echo "- Django"
    cat pyproject.toml requirements.txt 2>/dev/null | grep -qi "flask" && echo "- Flask"
    cat pyproject.toml requirements.txt 2>/dev/null | grep -qi "fastapi" && echo "- FastAPI"
fi

if [ -f "go.mod" ]; then
    grep -q "gin-gonic" go.mod 2>/dev/null && echo "- Gin"
    grep -q "echo" go.mod 2>/dev/null && echo "- Echo"
    grep -q "fiber" go.mod 2>/dev/null && echo "- Fiber"
fi

if [ -f "Cargo.toml" ]; then
    grep -q "actix" Cargo.toml 2>/dev/null && echo "- Actix"
    grep -q "axum" Cargo.toml 2>/dev/null && echo "- Axum"
    grep -q "rocket" Cargo.toml 2>/dev/null && echo "- Rocket"
fi
echo ""

# Database/ORM Detection
echo "## Database/ORM"
[ -f "prisma/schema.prisma" ] && echo "- Prisma ORM"
[ -f "drizzle.config.ts" ] || [ -f "drizzle.config.js" ] && echo "- Drizzle ORM"
[ -f "package.json" ] && grep -q '"typeorm"' package.json 2>/dev/null && echo "- TypeORM"
[ -f "package.json" ] && grep -q '"sequelize"' package.json 2>/dev/null && echo "- Sequelize"
cat pyproject.toml requirements.txt 2>/dev/null | grep -qi "sqlalchemy" && echo "- SQLAlchemy"
cat pyproject.toml requirements.txt 2>/dev/null | grep -qi "django" && echo "- Django ORM"
[ -f "go.mod" ] && grep -q "gorm" go.mod 2>/dev/null && echo "- GORM"
[ -f "Cargo.toml" ] && grep -q "diesel" Cargo.toml 2>/dev/null && echo "- Diesel"
echo ""

# Testing Framework Detection
echo "## Testing"
[ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ] && echo "- Vitest"
[ -f "jest.config.ts" ] || [ -f "jest.config.js" ] && echo "- Jest"
cat pyproject.toml requirements.txt 2>/dev/null | grep -qi "pytest" && echo "- pytest"
[ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ] && echo "- Playwright"
[ -f "cypress.config.ts" ] || [ -f "cypress.config.js" ] && echo "- Cypress"
echo ""

# Infrastructure Detection
echo "## Infrastructure"
[ -f "Dockerfile" ] && echo "- Docker"
[ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] && echo "- Docker Compose"
ls *.tf 1>/dev/null 2>&1 && echo "- Terraform"
[ -d "kubernetes" ] || [ -d "k8s" ] && echo "- Kubernetes"
[ -f "serverless.yml" ] && echo "- Serverless Framework"
echo ""

# CI/CD Detection
echo "## CI/CD"
[ -d ".github/workflows" ] && echo "- GitHub Actions"
[ -f ".gitlab-ci.yml" ] && echo "- GitLab CI"
[ -f "Jenkinsfile" ] && echo "- Jenkins"
[ -f ".circleci/config.yml" ] && echo "- CircleCI"
echo ""

echo "=== Detection Complete ==="
