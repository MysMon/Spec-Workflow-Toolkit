# Spec-Workflow Toolkit

**Claude Code 向け仕様駆動開発ツールキット**

複雑な機能開発を、専門AIエージェントの支援を受けながら段階的に進めるプラグインです。
各段階で確認・判断でき、中断した作業も途中から再開できます。

---

## クイックスタート

### インストール

```bash
# 1. リポジトリをクローン
git clone https://github.com/MysMon/cc-web-dev.git spec-workflow-toolkit

# 2. プラグインをロードしてClaude Codeを起動
claude --plugin-dir ./spec-workflow-toolkit
```

**既存プロジェクトで使う場合:**
```bash
# 作業ディレクトリにクローン
git clone https://github.com/MysMon/cc-web-dev.git .plugins/spec-workflow-toolkit

# Claude Code起動
claude --plugin-dir .plugins/spec-workflow-toolkit
```

### 基本的な使い方

```bash
# 計画（仕様と設計をユーザーと対話しながら作成）
/spec-plan ユーザー認証機能を OAuth 対応で実装

# 仕様・設計レビュー → 修正
/spec-review docs/specs/user-authentication.md

# 承認済み仕様から実装
/spec-implement docs/specs/user-authentication.md

# 小規模タスクの高速実装
/quick-impl README のタイポを修正

# セッション再開
/resume
```

---

## コマンド一覧

### 計画・実装

| コマンド | 説明 |
|----------|------|
| `/spec-plan` | 新機能の仕様と設計を対話的に作成 |
| `/spec-review` | 仕様・設計をレビューし修正 |
| `/spec-implement` | 承認済みの仕様に基づいて実装 |
| `/spec-revise` | 実装後の変更依頼を設計書と照合し対応方法を判断 |
| `/quick-impl` | 小規模タスクを迅速に実装（仕様書不要） |

### レビュー

| コマンド | 説明 |
|----------|------|
| `/code-review` | コミット前にコードの品質をチェック |
| `/review-response` | PR レビューのコメントに対応 |
| `/review-insights` | 開発中に記録された知見を評価・反映 |

### トラブルシューティング

| コマンド | 説明 |
|----------|------|
| `/debug` | エラーを段階的に分析し根本原因を特定 |
| `/ci-fix` | CI/CD パイプラインの失敗を診断・修正 |
| `/hotfix` | 本番環境の障害を迅速に修正 |
| `/merge-conflict` | マージ時の競合を解決 |

### セットアップ・管理

| コマンド | 説明 |
|----------|------|
| `/project-setup` | プロジェクト固有の開発ルールを自動生成 |
| `/stack-consult` | 新規プロジェクトの技術スタックを選定 |
| `/resume` | 中断したセッションを進捗ファイルから再開 |
| `/doc-audit` | コードとドキュメントの整合性を検証 |

---

## 計画 → レビュー → 実装 → 改訂

大きな機能開発を、計画・レビュー・実装・改訂の4つのフェーズに分けて進めます。

**分離する理由**
- 各フェーズでコンテキストを最大限使える（Anthropic公式推奨パターン）
- 計画後にレビューを挟め、手戻りコストを最小化
- 各フェーズ内でユーザーと対話的に改善できる
- 長時間作業でも途中で中断・再開が可能

```mermaid
flowchart LR
    subgraph plan["/spec-plan"]
        D[1. Discovery] --> E[2. Exploration]
        E --> C[3. Spec Drafting]
        C -->|"refinement ←→ user"| C
        C --> A[4. Architecture]
        A -->|"refinement ←→ user"| A
        A -->|"back to spec"| C
    end
    subgraph review["/spec-review"]
        R1[Completeness] & R2[Feasibility] & R3[Security] & R4[Testability] & R5[Consistency]
    end
    subgraph impl["/spec-implement"]
        I[Implementation] -->|"divergence → user"| I
        I --> QR[Quality Review] --> S[Summary]
    end
    subgraph revise["/spec-revise"]
        CR[Change Request] --> IA[Impact Analysis]
        IA -->|"TRIVIAL/SMALL"| EX[Execute]
        IA -->|"MEDIUM"| review
        IA -->|"LARGE/NEW"| plan
    end
    plan --> review --> impl --> revise

    style plan fill:#e1f5fe
    style review fill:#fff3e0
    style impl fill:#e8f5e9
    style revise fill:#fce4ec
```

| フェーズ | コマンド | ユーザーの関わり方 | 出力 |
|----------|----------|---------------------|------|
| 計画 | `/spec-plan` | 要件説明、仕様の修正依頼、設計の変更・代替案探索 | 仕様書 + 設計書 |
| レビュー | `/spec-review` | 指摘事項を確認、仕様・設計の修正（整合性チェック付き） | レビューレポート |
| 実装 | `/spec-implement` | 進捗確認、仕様乖離時の判断、品質レビュー対応 | 動作するコード |
| 改訂 | `/spec-revise` | 変更内容の説明、影響の確認、進め方の選択 | 更新された仕様・設計 or 次ステップ案内 |

---

## セッション再開

Claude Code では 2 つの再開方法があります。

| 方法 | コマンド | 用途 |
|------|----------|------|
| **Claude Code 標準** | `claude --continue` | 直前のセッションをそのまま継続 |
| **Spec-Workflow Toolkit** | `/resume` | 進捗ファイルから状態を復元 |

| シナリオ | 推奨 |
|----------|------|
| ネットワーク切断後すぐに再接続 | `--continue` |
| 翌日に作業を再開 | `/resume` |
| 別のターミナルで作業継続 | `/resume` |
| コンテキスト肥大化時 | `/resume` |

---

## 開発インサイトの記録

開発中に発見したパターンや決定事項を自動記録し、プロジェクトルールに反映できます。

- サブエージェントが発見した内容を自動キャプチャ
- `/review-insights` で一つずつ評価し、CLAUDE.md や `.claude/rules/` に反映
- セッション開始時に未評価のインサイトがあれば通知

---

## ベストプラクティス

### 推奨

- 複雑な作業は `/spec-plan` で計画から開始
- 探索作業はサブエージェント（`code-explorer`）に移譲
- 主要タスク間で `/clear` を使用
- コードより先に仕様を書く
- コミット前に `/code-review` を実行

### 非推奨

- 探索フェーズのスキップ
- メインスレッドでのコンテキスト蓄積
- 秘密情報のハードコード
- security-auditor の指摘を無視

### よくある失敗パターン

| パターン | 問題 | 対策 |
|----------|------|------|
| 一括実装 | 全機能を一度に実装しようとする | 1機能ずつ実装・テスト |
| 探索なしでコーディング | コードベース理解なしに実装 | `code-explorer` で事前分析 |
| 曖昧な仕様での実装 | 不明確な要件で進行 | `/spec-plan` で仕様を対話的に改善 |

---

## プロジェクト固有ルール

Spec-Workflow Toolkit は汎用ワークフローを提供します。プロジェクト固有のルールは `.claude/rules/` で管理できます。

```bash
# プロジェクト固有ルールを自動生成
/project-setup
```

詳細: [Manage Claude's memory](https://code.claude.com/docs/en/memory)

---

## エージェント一覧

| カテゴリ | エージェント | 用途 |
|----------|--------------|------|
| **分析** | `code-explorer` | コードベース分析（読み取り専用） |
| | `code-architect` | 機能設計ブループリント |
| | `system-architect` | システムレベル設計、ADR |
| **実装** | `frontend-specialist` | UI 実装 |
| | `backend-specialist` | API 実装 |
| | `product-manager` | 要件収集、PRD 作成 |
| **レビュー** | `qa-engineer` | テスト戦略、カバレッジ分析 |
| | `security-auditor` | OWASP Top 10、脆弱性レビュー |
| **検証** | `verification-specialist` | ファクトチェック、参照検証 |
| **その他** | `devops-sre` | インフラ、CI/CD |
| | `ui-ux-designer` | デザインシステム |
| | `technical-writer` | ドキュメント |
| | `legacy-modernizer` | 安全なリファクタリング |

---

## 参照資料

| 記事 | 内容 |
|------|------|
| [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) | エージェント設計パターン |
| [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | 長時間作業のハーネス設計 |
| [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) | コンテキスト管理 |

---

## 開発者向け

このプラグインを拡張・修正する場合は `docs/DEVELOPMENT.md` を参照してください。

---

## ライセンス

MIT
