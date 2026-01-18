# SDD Toolkit v8.3.0

**Claude Code 向け仕様駆動開発ツールキット**

長時間の自律作業セッションを実現するマルチスタック対応エージェントフレームワーク。7フェーズワークフロー、積極的なサブエージェント移譲、JSON ベースの進捗追跡、再開可能セッションを備え、公式 Anthropic ベストプラクティスに基づいています。

---

## このプラグインの目的

このプラグインは**4つの核心目標**を達成するために設計されています:

### 1. 長時間の自律作業セッション

コンテキストウィンドウの制限を克服し、複雑なタスクを複数セッションにわたって継続的に完了させます。

- **Initializer + Coding パターン**: 初回セッションで環境構築、以降は増分実装
- **JSON 進捗ファイル**: `claude-progress.json` と `feature-list.json` で状態を永続化
- **SessionStart フック**: 自動的に進捗ファイルを検出し、再開コンテキストを提供

### 2. 徹底したスペック駆動開発

コードを書く前に必ず仕様を確定させ、曖昧さをゼロにします。

- **7フェーズワークフロー**: Discovery → Exploration → Clarification → Design → Implementation → Review → Summary
- **No Code Without Spec**: 承認された仕様なしに実装を開始しない
- **`/spec-review` コマンド**: 実装前に仕様の妥当性を検証

### 3. サブエージェントへの積極的移譲

メインコンテキストを保護し、探索・分析作業はサブエージェントに移譲します。

- **コンテキスト保護**: サブエージェントは独立したコンテキストウィンドウで実行
- **結果のみ返却**: 完全な探索データではなく、サマリーと `file:line` 参照のみがメインに戻る
- **並列実行**: 独立したタスクは複数エージェントを同時実行

### 4. ユーザーへの十分な質問

曖昧さを許容せず、不明点は必ずユーザーに確認します。

- **Phase 3: Clarifying Questions**: エッジケース、エラー処理、統合ポイントを明確化
- **AskUserQuestion ツール**: 実装中も必要に応じて質問
- **信頼度 80% 閾値**: 確信度の低い判断は報告しない

---

## 公式ベストプラクティスとの関係

> このプラグインは公式プラグインを模倣するのではなく、その**考え方を活用**して独自の目的を達成します。

| 公式の考え方 | このプラグインでの活用 |
|--------------|------------------------|
| サブエージェントによるコンテキスト管理 | 12の専門エージェントで徹底移譲 |
| 信頼度ベースのフィルタリング (80%) | 全レビューに統一適用 |
| Initializer + Coding パターン | SessionStart で自動ロール検出 |
| One Feature at a Time | 進捗ファイルで 1 機能ずつ追跡 |

### 意図的な差異

| 公式 `feature-dev` | このプラグイン | 理由 |
|--------------------|----------------|------|
| 3つのアプローチを提示 | **単一の決定的推奨** | 決定疲れを軽減、code-architect が内部で代替案を検討済み |
| `claude-progress.txt` (テキスト) | `claude-progress.json` (JSON) | 機械可読で誤変更されにくい |
| 汎用エクスプローラー | **12の専門エージェント** | ドメイン専門性で品質向上 |

---

## 参照資料

- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Official Plugin Marketplace](https://github.com/anthropics/claude-plugins-official)
- [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)

---

## クイックスタート

### インストール

```bash
# プラグインディレクトリからインストール
/plugin install sdd-toolkit@your-marketplace

# または開発用にローカルロード
claude --plugin-dir /path/to/sdd-toolkit
```

### 基本的な使い方

```bash
# 複雑な機能開発（7フェーズワークフロー）
/sdd ユーザー認証機能を OAuth 対応で実装

# 仕様のレビュー
/spec-review docs/specs/user-auth.md

# コードレビュー（並列エージェント、信頼度 >= 80）
/code-review staged

# 小規模タスクの高速実装
/quick-impl README のタイポを修正
```

---

## 7フェーズ SDD ワークフロー

`/sdd` コマンドは包括的な開発ワークフローを実行します:

| フェーズ | 目的 | 実行内容 |
|----------|------|----------|
| 1. Discovery | 構築内容の理解 | 問題定義、制約特定、ユーザー確認 |
| 2. Codebase Exploration | 既存コードの把握 | 2-3 の `code-explorer` エージェントを並列実行 |
| 3. Clarifying Questions | 曖昧さの解消 | エッジケース、エラー処理、統合ポイントを確認 |
| 4. Architecture Design | 設計決定 | 2-3 の `code-architect` エージェントで分析し、統合推奨 |
| 5. Implementation | 機能構築 | 専門エージェントに移譲、1 機能ずつ実装 |
| 6. Quality Review | 品質確保 | qa-engineer、security-auditor、code-explorer を並列実行 |
| 7. Summary | 完了記録 | 変更内容、決定事項、次のステップを文書化 |

---

## エージェント一覧

### コア分析エージェント

| エージェント | モデル | 用途 |
|--------------|--------|------|
| `code-explorer` | Sonnet | 深いコードベース分析、`file:line` 参照で実行フロー追跡 |
| `code-architect` | Sonnet | 既存パターンに基づく機能設計ブループリント |
| `system-architect` | **Opus** | システムレベル設計、ADR、API コントラクト（深い推論が必要） |

### 実装エージェント

| エージェント | モデル | 用途 |
|--------------|--------|------|
| `frontend-specialist` | **inherit** | UI 実装（ユーザーのセッションモデルを使用） |
| `backend-specialist` | **inherit** | API 実装（ユーザーのセッションモデルを使用） |
| `product-manager` | **Opus** | 要件収集、PRD 作成（曖昧な要件から本質を抽出） |

### レビューエージェント

| エージェント | モデル | 用途 |
|--------------|--------|------|
| `qa-engineer` | Sonnet | テスト戦略、カバレッジ分析（信頼度 >= 80） |
| `security-auditor` | Sonnet | OWASP Top 10、脆弱性レビュー（読み取り専用） |

### その他の専門エージェント

| エージェント | モデル | 用途 |
|--------------|--------|------|
| `devops-sre` | Sonnet | インフラ、CI/CD、デプロイメント |
| `ui-ux-designer` | Sonnet | デザインシステム、アクセシビリティ |
| `technical-writer` | Sonnet | ドキュメント、変更履歴 |
| `legacy-modernizer` | Sonnet | 安全なリファクタリング、特性テスト |

### モデル選択戦略

| モデル | 使用場面 | 理由 |
|--------|----------|------|
| **Opus** | system-architect, product-manager | ADR やシステム設計、曖昧な要件の本質抽出は深い推論が必要 |
| **Sonnet** | 分析・レビュー系 | バランスの取れたコスト/能力 |
| **Haiku** | 組み込み Explore、スコアリング | 高速で軽量な探索 |
| **inherit** | 実装系 | ユーザーがコスト/品質のトレードオフを制御 |

---

## 長時間作業サポート

[Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) に基づく設計:

### Initializer + Coding パターン

| ロール | タイミング | 実行内容 |
|--------|------------|----------|
| **INITIALIZER** | 初回セッション | 進捗ファイル作成、機能分解、状態初期化 |
| **CODING** | 各セッション | 進捗読み込み、1 機能実装、テスト、進捗更新 |

### 進捗ファイル

```
.claude/
├── claude-progress.json    # 進捗ログと再開コンテキスト
└── feature-list.json       # 機能/タスクのステータス追跡
```

#### claude-progress.json

```json
{
  "project": "feature-name",
  "status": "in_progress",
  "currentTask": "認証サービスの実装",
  "resumptionContext": {
    "position": "Phase 5 - Implementation",
    "nextAction": "src/services/auth.ts に AuthService を作成",
    "blockers": []
  }
}
```

#### feature-list.json

```json
{
  "features": [
    {"id": "F001", "name": "ユーザー登録", "status": "completed"},
    {"id": "F002", "name": "ユーザーログイン", "status": "in_progress"},
    {"id": "F003", "name": "パスワードリセット", "status": "pending"}
  ]
}
```

> **なぜ JSON か？** 「モデルは Markdown ファイルと比較して JSON ファイルを不適切に変更する可能性が低い」- Anthropic

---

## コマンド

| コマンド | 用途 |
|----------|------|
| `/sdd` | 新機能、複雑な変更（7フェーズワークフロー） |
| `/spec-review` | 実装前の仕様検証 |
| `/code-review` | コミット前のコードレビュー（並列エージェント） |
| `/quick-impl` | 明確な小規模タスク |

---

## スキル

### コアスキル

| スキル | 用途 |
|--------|------|
| `sdd-philosophy` | 仕様駆動開発の原則 |
| `security-fundamentals` | セキュリティベストプラクティス（OWASP、秘密情報） |
| `interview` | 構造化された要件収集 |
| `stack-detector` | プロジェクト技術スタックの自動検出 |

### ワークフロースキル

| スキル | 用途 |
|--------|------|
| `code-quality` | リンティング、フォーマット、型チェック |
| `git-mastery` | Conventional Commits、変更履歴 |
| `testing` | テストピラミッド、戦略、フレームワーク |
| `long-running-tasks` | 状態永続化、セッション再開 |
| `parallel-execution` | マルチエージェント調整 |
| `progress-tracking` | JSON ベースの状態永続化 |

---

## フック

| フック | イベント | 用途 |
|--------|---------|------|
| `sdd_context.sh` | SessionStart | SDD コンテキスト注入、**進捗ファイル検出**、再開サポート |
| `safety_check.py` | PreToolUse (Bash) | 危険なコマンドをブロック |
| `prevent_secret_leak.py` | PreToolUse (Write/Edit) | 秘密情報の検出 |
| `post_edit_quality.sh` | PostToolUse (Write/Edit) | リンター/フォーマッター自動実行 |
| `subagent_summary.sh` | SubagentStop | 完了ログ記録 |
| `session_summary.sh` | Stop | git status サマリー |

---

## ベストプラクティス

### 推奨

- 複雑な作業は `/sdd` で開始
- 探索作業は積極的にサブエージェント（特に `code-explorer`）に移譲
- 主要タスク間で `/clear` を使用
- コードより先に仕様を書く
- コミット前に `/code-review` を実行
- 長時間タスクには JSON 進捗追跡を使用
- 信頼度 >= 80 のエージェント出力を信頼

### 非推奨

- 探索フェーズのスキップ
- メインスレッドでのコンテキスト蓄積
- 秘密情報のハードコード
- security-auditor の指摘を無視
- 信頼度 < 80 の問題を報告

---

## プラグイン構造

```
sdd-toolkit/
├── .claude-plugin/
│   └── plugin.json           # プラグインメタデータ (v8.2.0)
├── commands/                  # ワークフローコマンド
│   ├── sdd.md                # 7フェーズワークフロー
│   ├── spec-review.md        # 仕様レビュー
│   ├── code-review.md        # コードレビュー（信頼度 >= 80）
│   └── quick-impl.md         # 高速実装
├── agents/                    # 12の専門エージェント
│   ├── code-explorer.md      # 深いコードベース分析（読み取り専用）
│   ├── code-architect.md     # 機能設計ブループリント
│   ├── system-architect.md   # システム設計（Opus）
│   ├── frontend-specialist.md
│   ├── backend-specialist.md
│   ├── qa-engineer.md
│   ├── security-auditor.md
│   └── ...
├── skills/                    # タスク指向スキル
│   ├── core/                  # 普遍的原則
│   ├── detection/             # スタック検出
│   └── workflows/             # クロススタックワークフロー
├── hooks/                     # 実行フック
│   ├── hooks.json
│   ├── sdd_context.sh        # SessionStart
│   └── ...
└── docs/
    └── specs/
        └── SPEC-TEMPLATE.md
```

---

## カスタマイズ

### 新しいコマンドの追加

`commands/my-command.md` を YAML フロントマターで作成。

### 新しいエージェントの追加

`agents/my-agent.md` を作成。`description`、`model`、`tools`、`skills` を含む YAML フロントマターが必要。

### 新しいスキルの追加

`skills/category/my-skill/SKILL.md` を YAML フロントマターで作成。

詳細なテンプレートは `CLAUDE.md` を参照。

---

## ライセンス

MIT
