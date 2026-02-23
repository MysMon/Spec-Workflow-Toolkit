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

### ステップ 2-7: 言語・フレームワーク・ツールの特定

設定ファイルに基づいて以下を順次検出する:

- ステップ 2: 主要言語とパッケージマネージャー
- ステップ 2a: パッケージマネージャーの検出（JavaScript）
- ステップ 3: フレームワークの検出（言語別）
- ステップ 4: データベース/ORM の検出
- ステップ 5: テストフレームワークの検出
- ステップ 6: CI/CD の検出
- ステップ 7: インフラの検出

各ステップの検出テーブルと bash コマンドは `REFERENCE.md` を参照。

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
