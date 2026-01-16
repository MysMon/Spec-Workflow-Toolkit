# Agentic Architecture Plugin for Claude Code

Claude Codeを活用した**仕様駆動開発（Specification-Driven Development: SDD）**と**自律型エージェントアーキテクチャ**を実現するための包括的なプラグイン実装です。

## 概要

このプラグインは、Claude Codeの公式機能（Subagents、Skills、Hooks、MCP）を活用し、以下を実現します：

- **Hub-and-Spoke モデル**: メインセッション（Hub）が専門エージェント（Spokes）にタスクを委譲
- **仕様駆動開発**: コード実装前に必ず仕様書を作成・承認するワークフロー
- **多層防御セキュリティ**: フック、パーミッション、エージェント分離による安全性確保
- **コンテキスト・エコノミー**: 効率的なコンテキスト管理で長時間セッションでも高精度を維持

## クイックスタート

### 1. リポジトリのクローン

```bash
git clone https://github.com/your-org/your-repo.git
cd your-repo
```

### 2. 環境変数の設定（オプション）

MCP サーバーを使用する場合：

```bash
# .env ファイルを作成（コミットしないこと）
cp .env.example .env

# 必要な環境変数を設定
GITHUB_TOKEN=your-github-token
DATABASE_URL=postgresql://user:password@localhost:5432/db
```

### 3. Claude Code でプロジェクトを開く

```bash
claude
```

プロジェクトの`CLAUDE.md`が自動的に読み込まれ、SDD原則とエージェント委譲プロトコルが有効になります。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                    Hub (Orchestrator)                       │
│  ・ユーザーとのインターフェース                              │
│  ・タスクの分解と委譲                                        │
│  ・最小限のコンテキスト保持                                  │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ product-manager │ │    architect    │ │ frontend-spec.  │
│ 要件定義・PRD   │ │ システム設計    │ │ React/Next.js   │
└─────────────────┘ └─────────────────┘ └─────────────────┘
          │                   │                   │
          ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ backend-spec.   │ │   devops-sre    │ │   qa-engineer   │
│ Node.js/API     │ │ インフラ・CI/CD │ │ テスト・QA      │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

## ディレクトリ構成

```
.
├── CLAUDE.md                          # プロジェクト憲法
├── README.md                          # このファイル
├── .mcp.json                          # MCP サーバー設定
├── .gitignore
│
├── docs/
│   └── specs/                         # 仕様書ディレクトリ
│       └── SPEC-TEMPLATE.md           # 仕様書テンプレート
│
└── .claude/
    ├── settings.json                  # Hooks & Permissions
    │
    ├── hooks/                         # セキュリティフック
    │   ├── safety_check.py            # 危険コマンドブロック
    │   ├── prevent_secret_leak.py     # シークレット検出
    │   ├── post_edit_lint.sh          # 自動Lint実行
    │   └── session_summary.sh         # セッション終了サマリー
    │
    ├── agents/                        # 専門エージェント定義
    │   ├── product-manager.md
    │   ├── architect.md
    │   ├── frontend-specialist.md
    │   ├── backend-specialist.md
    │   ├── devops-sre.md
    │   ├── qa-engineer.md
    │   ├── security-auditor.md
    │   ├── ui-ux-designer.md
    │   ├── technical-writer.md
    │   └── legacy-modernizer.md
    │
    ├── skills/                        # 再利用可能なスキル
    │   ├── code-quality/
    │   ├── safe-migration/
    │   ├── git-mastery/
    │   ├── visual-testing/
    │   ├── arch-compliance/
    │   └── interview/
    │
    └── rules/                         # モジュール化されたルール
        ├── code-style.md
        ├── security.md
        └── testing.md
```

## 専門エージェント

| エージェント | 役割 | 主な責務 |
|------------|------|---------|
| `product-manager` | 要件定義 | ヒアリング、PRD作成、仕様の明確化 |
| `architect` | 設計 | システム設計、DB設計、ADR作成 |
| `frontend-specialist` | フロント実装 | React/Next.js/TypeScript/Tailwind |
| `backend-specialist` | バックエンド実装 | Node.js/API/Prisma |
| `devops-sre` | インフラ | Terraform/Kubernetes/CI-CD |
| `qa-engineer` | 品質保証 | Vitest/Playwright/ビジュアルテスト |
| `security-auditor` | セキュリティ | 脆弱性診断、コードレビュー（読取専用） |
| `ui-ux-designer` | デザイン | デザインシステム、A11y監査 |
| `technical-writer` | ドキュメント | README、Changelog、API docs |
| `legacy-modernizer` | レガシー改修 | リバースエンジニアリング、安全なリファクタリング |

### エージェントの呼び出し例

Claude Code は自動的に適切なエージェントを選択しますが、明示的に指定することも可能です：

```
# 新機能の要件定義から始める
「ユーザーダッシュボード機能を追加したい」
→ product-manager エージェントが起動し、要件をヒアリング

# アーキテクチャ設計を依頼
「認証システムのアーキテクチャを設計して」
→ architect エージェントが起動

# セキュリティレビューを実行
「このPRのセキュリティレビューをして」
→ security-auditor エージェントが起動（読取専用）
```

## Skills（スキル）

スキルは `/skill-name` で呼び出し可能な再利用可能な手順書です。

| スキル | 説明 | 呼び出し |
|-------|------|---------|
| `code-quality` | Lint/Format/Type check | `/code-quality` |
| `safe-migration` | Prisma安全マイグレーション | `/safe-migration` |
| `git-mastery` | セマンティックコミット生成 | `/git-mastery` |
| `visual-testing` | Playwrightビジュアルテスト | `/visual-testing` |
| `arch-compliance` | アーキテクチャ境界検証 | `/arch-compliance` |
| `interview` | 構造化要件インタビュー | `/interview` |

### スキルの使用例

```
# コード品質チェック
/code-quality

# データベースマイグレーション（安全手順付き）
/safe-migration add_user_roles

# セマンティックコミットメッセージ生成
/git-mastery
```

## Hooks（フック）

フックはツール実行前後に自動実行されるスクリプトです。

### PreToolUse フック

| フック | トリガー | 機能 |
|--------|---------|------|
| `safety_check.py` | Bash実行前 | 危険コマンド（rm -rf /、sudo等）をブロック |
| `prevent_secret_leak.py` | Write/Edit前 | APIキー、パスワード等の検出・ブロック |

### PostToolUse フック

| フック | トリガー | 機能 |
|--------|---------|------|
| `post_edit_lint.sh` | Write/Edit後 | 自動Lint/Format実行 |

### Stop フック

| フック | トリガー | 機能 |
|--------|---------|------|
| `session_summary.sh` | レスポンス完了時 | Gitステータスのサマリー表示 |

### セキュリティフックが検出するパターン

**危険コマンド（ブロック）:**
- `rm -rf /` - システム破壊
- `sudo` - 権限昇格
- `chmod 777` - 危険なパーミッション
- `curl | sh` - リモートスクリプト実行
- `DROP DATABASE` - データベース削除

**シークレットパターン（ブロック）:**
- AWS Access Key (`AKIA...`)
- GitHub Token (`ghp_...`)
- Stripe Key (`sk_live_...`)
- Private Keys (`-----BEGIN PRIVATE KEY-----`)
- Generic API Keys

## MCP サーバー設定

`.mcp.json` で以下のMCPサーバーが設定されています：

```json
{
  "mcpServers": {
    "filesystem": { ... },  // ファイルシステムアクセス
    "github": { ... },      // GitHub API
    "postgres": { ... },    // PostgreSQL
    "memory": { ... },      // セッション内メモリ
    "fetch": { ... }        // HTTP リクエスト
  }
}
```

### MCP サーバーの有効化

環境変数を設定してClaude Codeを起動：

```bash
export GITHUB_TOKEN="your-token"
export DATABASE_URL="postgresql://..."
claude
```

## 仕様駆動開発（SDD）ワークフロー

### Phase 1: 要件定義

```
ユーザー: 「ユーザー認証機能を追加したい」

→ product-manager エージェントが起動
→ トレードオフ質問:「OAuth2 vs カスタムJWT？」
→ docs/specs/feat-authentication.md を作成
```

### Phase 2: 設計

```
→ architect エージェントが仕様書を読み込み
→ システム設計、DBスキーマ、API設計を作成
→ docs/architecture/ に成果物を配置
```

### Phase 3: 実装

```
→ frontend-specialist / backend-specialist が実装
→ code-quality スキルで品質チェック
→ 仕様書にない機能は実装禁止
```

### Phase 4: 検証

```
→ qa-engineer がテストを作成・実行
→ security-auditor がセキュリティレビュー
→ visual-testing スキルでUI検証
```

## カスタマイズ

### 新しいエージェントの追加

`.claude/agents/my-agent.md`:

```markdown
---
name: my-agent
description: 説明文。どんな時に使うかを記載。
model: sonnet
tools: Read, Glob, Grep, Write, Edit, Bash
permissionMode: default
---

# Role: My Agent

あなたの役割は...

## Workflow

1. ステップ1
2. ステップ2

## Rules

- ルール1
- ルール2
```

### 新しいスキルの追加

`.claude/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: 説明文
allowed-tools: Bash, Read
user-invocable: true
---

# My Skill

## Workflow

1. 手順1
2. 手順2
```

### 新しいフックの追加

`.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ToolName",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/my-hook.sh"
          }
        ]
      }
    ]
  }
}
```

## ベストプラクティス

### 1. コンテキスト管理

- 大きなファイルの読み込みはサブエージェントに委譲
- 長いセッションでは定期的にコミットして「記憶をオフロード」
- 試行錯誤はサブエージェント内で完結させる

### 2. 仕様ファースト

- 曖昧な要件は必ず明確化してから実装
- `docs/specs/SPEC-TEMPLATE.md` を使用
- 仕様書の変更は承認プロセスを経る

### 3. セキュリティ

- シークレットは必ず環境変数で管理
- `security-auditor` エージェントでリリース前レビュー
- フックによる自動検出を信頼しつつ、手動確認も実施

### 4. テスト駆動

- 実装前にテストを書く（Red-Green-Refactor）
- `qa-engineer` エージェントでE2Eテストを自動生成
- `visual-testing` スキルでUI回帰を検出

## トラブルシューティング

### フックが実行されない

```bash
# フックスクリプトに実行権限があるか確認
chmod +x .claude/hooks/*.sh .claude/hooks/*.py
```

### MCP サーバーに接続できない

```bash
# 環境変数が設定されているか確認
echo $GITHUB_TOKEN
echo $DATABASE_URL

# MCP サーバーを手動でテスト
npx @modelcontextprotocol/server-github
```

### エージェントが自動選択されない

CLAUDE.md の「Hub-and-Spoke Protocol」セクションを確認し、タスクカテゴリとエージェントのマッピングが正しいか確認してください。

## 参考資料

- [Claude Code 公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Claude Code Subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- [Claude Code Skills](https://docs.anthropic.com/en/docs/claude-code/skills)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## ライセンス

MIT License - 詳細は [LICENSE](./LICENSE) を参照してください。

---

**Built with Claude Code** - Transforming software development with agentic architecture.
