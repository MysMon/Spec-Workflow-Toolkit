# stack-detector Reference

言語・フレームワーク・ツール別の検出テーブル一覧。

## 主要言語の特定

| 設定ファイル | 主要言語 | パッケージマネージャー |
|-------------|----------|---------------------|
| `package.json` | JavaScript/TypeScript | npm/yarn/pnpm/bun |
| `pyproject.toml` | Python | pip/poetry/uv |
| `requirements.txt` | Python | pip |
| `go.mod` | Go | go modules |
| `Cargo.toml` | Rust | cargo |
| `pom.xml` | Java | Maven |
| `build.gradle` | Java/Kotlin | Gradle |
| `build.gradle.kts` | Kotlin | Gradle |
| `*.csproj` / `*.sln` | C# | dotnet |
| `Gemfile` | Ruby | bundler |
| `composer.json` | PHP | composer |
| `pubspec.yaml` | Dart | pub |
| `Package.swift` | Swift | SwiftPM |

## パッケージマネージャーの検出（JavaScript）

| ロックファイル | パッケージマネージャー |
|--------------|---------------------|
| `package-lock.json` | npm |
| `yarn.lock` | yarn |
| `pnpm-lock.yaml` | pnpm |
| `bun.lockb` | bun |

## フレームワークの検出

### JavaScript/TypeScript フレームワーク

```bash
# package.json の依存関係をチェック
grep -E '"(react|vue|angular|svelte|next|nuxt|express|fastify|hono|nestjs)"' package.json
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `react`, `react-dom` | React | フロントエンド |
| `next` | Next.js | フルスタック |
| `vue` | Vue.js | フロントエンド |
| `nuxt` | Nuxt.js | フルスタック |
| `@angular/core` | Angular | フロントエンド |
| `svelte` | Svelte | フロントエンド |
| `express` | Express | バックエンド |
| `fastify` | Fastify | バックエンド |
| `hono` | Hono | バックエンド |
| `@nestjs/core` | NestJS | バックエンド |

### Python フレームワーク

```bash
# pyproject.toml または requirements.txt をチェック
grep -E '(django|flask|fastapi|starlette)' pyproject.toml requirements.txt 2>/dev/null
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `django` | Django | フルスタック |
| `flask` | Flask | バックエンド |
| `fastapi` | FastAPI | バックエンド |
| `starlette` | Starlette | バックエンド |

### Go フレームワーク

```bash
# go.mod をチェック
grep -E '(gin|echo|fiber|chi)' go.mod 2>/dev/null
```

### Rust フレームワーク

```bash
# Cargo.toml をチェック
grep -E '(actix|axum|rocket|warp)' Cargo.toml 2>/dev/null
```

### PHP フレームワーク

```bash
# composer.json をチェック
grep -E '(laravel|symfony|slim|laminas)' composer.json 2>/dev/null
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `laravel/framework` | Laravel | フルスタック |
| `symfony/framework-bundle` | Symfony | フルスタック |
| `slim/slim` | Slim | バックエンド |
| `wordpress` | WordPress | CMS |

### Ruby フレームワーク

```bash
# Gemfile をチェック
grep -E '(rails|sinatra|hanami)' Gemfile 2>/dev/null
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `rails` | Ruby on Rails | フルスタック |
| `sinatra` | Sinatra | バックエンド |
| `hanami` | Hanami | フルスタック |

### C# / .NET フレームワーク

```bash
# *.csproj の PackageReference をチェック
grep -E '(Microsoft.AspNetCore|Blazor)' *.csproj 2>/dev/null
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `Microsoft.AspNetCore` | ASP.NET Core | バックエンド |
| `Microsoft.AspNetCore.Components` | Blazor | フロントエンド |
| `Microsoft.Maui` | .NET MAUI | モバイル |

### Kotlin フレームワーク

```bash
# build.gradle.kts をチェック
grep -E '(ktor|spring)' build.gradle.kts 2>/dev/null
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `io.ktor` | Ktor | バックエンド |
| `org.springframework.boot` | Spring Boot | バックエンド |
| Android SDK | Android | モバイル |

### Swift フレームワーク

```bash
# Package.swift またはプロジェクトのフレームワークをチェック
grep -E '(vapor|perfect|kitura)' Package.swift 2>/dev/null
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `vapor` | Vapor | バックエンド |
| SwiftUI | SwiftUI | フロントエンド |
| UIKit | UIKit | フロントエンド |

## データベース/ORM の検出

| 指標 | 技術 |
|------|------|
| `prisma/schema.prisma` | Prisma ORM |
| `drizzle.config.ts` | Drizzle ORM |
| `typeorm` in deps | TypeORM |
| `sequelize` in deps | Sequelize |
| `sqlalchemy` in deps | SQLAlchemy |
| `django.db` | Django ORM |
| `gorm` in go.mod | GORM |
| `diesel` in Cargo.toml | Diesel |

## テストフレームワークの検出

| 設定/依存関係 | テストフレームワーク |
|-------------|-------------------|
| `vitest.config.*` | Vitest |
| `jest.config.*` | Jest |
| `pytest` in deps | pytest |
| `_test.go` files | Go testing |
| `#[test]` in .rs | Rust testing |
| `cypress.config.*` | Cypress |
| `playwright.config.*` | Playwright |

## CI/CD の検出

| ファイル | CI/CD プラットフォーム |
|---------|---------------------|
| `.github/workflows/` | GitHub Actions |
| `.gitlab-ci.yml` | GitLab CI |
| `Jenkinsfile` | Jenkins |
| `.circleci/config.yml` | CircleCI |
| `azure-pipelines.yml` | Azure DevOps |

## インフラの検出

| ファイル | インフラ |
|---------|---------|
| `Dockerfile` | Docker |
| `docker-compose.yml` | Docker Compose |
| `*.tf` | Terraform |
| `kubernetes/`, `k8s/` | Kubernetes |
| `serverless.yml` | Serverless Framework |
