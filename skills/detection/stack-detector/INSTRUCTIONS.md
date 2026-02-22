# スタック検出

設定ファイルとソースコードパターンを分析して、プロジェクトの技術スタックを自動的に特定する。

## 検出プロセス

### ステップ 1: 設定ファイルのスキャン

プロジェクトルートでこれらの指標ファイルを探す:

```bash
# これらのチェックを実行（存在がスタックを示す）
ls -la package.json         # JavaScript/Node.js
ls -la pyproject.toml       # Python（モダン）
ls -la requirements.txt     # Python
ls -la go.mod               # Go
ls -la Cargo.toml           # Rust
ls -la pom.xml              # Java (Maven)
ls -la build.gradle         # Java/Gradle
ls -la build.gradle.kts     # Kotlin (Gradle)
ls -la *.csproj             # C# / .NET
ls -la *.sln                # .NET Solution
ls -la Gemfile              # Ruby
ls -la composer.json        # PHP
ls -la pubspec.yaml         # Dart/Flutter
ls -la Package.swift        # Swift
```

### ステップ 2: 主要言語の特定

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

### ステップ 2a: パッケージマネージャーの検出（JavaScript）

| ロックファイル | パッケージマネージャー |
|--------------|---------------------|
| `package-lock.json` | npm |
| `yarn.lock` | yarn |
| `pnpm-lock.yaml` | pnpm |
| `bun.lockb` | bun |

### ステップ 3: フレームワークの検出

#### JavaScript/TypeScript フレームワーク
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

#### Python フレームワーク
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

#### Go フレームワーク
```bash
# go.mod をチェック
grep -E '(gin|echo|fiber|chi)' go.mod 2>/dev/null
```

#### Rust フレームワーク
```bash
# Cargo.toml をチェック
grep -E '(actix|axum|rocket|warp)' Cargo.toml 2>/dev/null
```

#### PHP フレームワーク
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

#### Ruby フレームワーク
```bash
# Gemfile をチェック
grep -E '(rails|sinatra|hanami)' Gemfile 2>/dev/null
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `rails` | Ruby on Rails | フルスタック |
| `sinatra` | Sinatra | バックエンド |
| `hanami` | Hanami | フルスタック |

#### C# / .NET フレームワーク
```bash
# *.csproj の PackageReference をチェック
grep -E '(Microsoft.AspNetCore|Blazor)' *.csproj 2>/dev/null
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `Microsoft.AspNetCore` | ASP.NET Core | バックエンド |
| `Microsoft.AspNetCore.Components` | Blazor | フロントエンド |
| `Microsoft.Maui` | .NET MAUI | モバイル |

#### Kotlin フレームワーク
```bash
# build.gradle.kts をチェック
grep -E '(ktor|spring)' build.gradle.kts 2>/dev/null
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `io.ktor` | Ktor | バックエンド |
| `org.springframework.boot` | Spring Boot | バックエンド |
| Android SDK | Android | モバイル |

#### Swift フレームワーク
```bash
# Package.swift またはプロジェクトのフレームワークをチェック
grep -E '(vapor|perfect|kitura)' Package.swift 2>/dev/null
```

| 依存関係 | フレームワーク | カテゴリ |
|---------|---------------|---------|
| `vapor` | Vapor | バックエンド |
| SwiftUI | SwiftUI | フロントエンド |
| UIKit | UIKit | フロントエンド |

### ステップ 4: データベース/ORM の検出

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

### ステップ 5: テストフレームワークの検出

| 設定/依存関係 | テストフレームワーク |
|-------------|-------------------|
| `vitest.config.*` | Vitest |
| `jest.config.*` | Jest |
| `pytest` in deps | pytest |
| `_test.go` files | Go testing |
| `#[test]` in .rs | Rust testing |
| `cypress.config.*` | Cypress |
| `playwright.config.*` | Playwright |

### ステップ 6: CI/CD の検出

| ファイル | CI/CD プラットフォーム |
|---------|---------------------|
| `.github/workflows/` | GitHub Actions |
| `.gitlab-ci.yml` | GitLab CI |
| `Jenkinsfile` | Jenkins |
| `.circleci/config.yml` | CircleCI |
| `azure-pipelines.yml` | Azure DevOps |

### ステップ 7: インフラの検出

| ファイル | インフラ |
|---------|---------|
| `Dockerfile` | Docker |
| `docker-compose.yml` | Docker Compose |
| `*.tf` | Terraform |
| `kubernetes/`, `k8s/` | Kubernetes |
| `serverless.yml` | Serverless Framework |

## 出力形式

検出後、スタックプロファイルを出力:

```yaml
Stack Profile:
  language: [主要言語]
  runtime: [検出可能な場合のランタイムバージョン]
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

## スキル推奨

検出されたスタックに基づいて、以下のタスク指向スキルの読み込みを推奨:

| コンテキスト | 推奨スキル |
|-------------|-----------|
| すべてのプロジェクト | `code-quality`, `testing` |
| Prisma/SQL あり | `migration` |
| Docker/K8s あり | （`devops-sre` エージェントを使用） |
| API 開発 | `api-design` |
| 本番システム | `observability` |
| 新機能 | `spec-philosophy`, `interview` |
| セキュリティ重要 | `security-fundamentals` |

## 使用方法

このスキルは通常、他のエージェントによって自動的に呼び出される:

1. エージェントがタスクを受信
2. エージェントが `stack-detector` を読み込む
3. スタックプロファイルが生成される
4. エージェントがスタック固有のパターンで処理を進行（Claude は言語のベストプラクティスを既に知っている）

## ルール（L1 - ハード）

正確な検出にとって重要。

- NEVER: 証拠なしにスタックを推測しない（不正確な推奨になる）

## デフォルト（L2 - ソフト）

信頼性の高い検出にとって重要。適切な理由がある場合はオーバーライド可能。

- 複数の指標をチェックする（単一のファイルに依存しない）
- 混合シグナルの場合は不確実性を報告
- 検出されたツールを出力にリスト化

## ガイドライン（L3）

徹底的な検出のための推奨事項。

- consider: 技術変更について最近の git 履歴をチェックすることを検討
- recommend: 曖昧な場合は設定ファイルだけでなく実際のソースファイルのチェックを推奨
