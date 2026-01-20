# SDD Toolkit

**Claude Code 向け仕様駆動開発ツールキット**

Anthropic の 6 つの Composable パターンをすべて実装した、長時間自律作業のためのエージェントフレームワーク。

---

## このプラグインの目的

| 目標 | 実現方法 |
|------|----------|
| **長時間の自律作業** | Initializer + Coding パターン、JSON 進捗ファイル、SessionStart フック |
| **徹底したスペック駆動** | 7フェーズワークフロー、No Code Without Spec、`/spec-review` |
| **サブエージェントへの移譲** | 12専門エージェント、コンテキスト保護、結果サマリーのみ返却 |
| **ユーザーへの十分な質問** | Phase 3: Clarifying Questions、AskUserQuestion ツール、信頼度 80% 閾値 |

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

# 新規プロジェクトのスタック相談・構築
/stack-consult

# セッション再開（進捗ファイルから）
/resume

# 体系的デバッグ
/debug エラーメッセージをここに
```

---

## コマンド一覧

| コマンド | 用途 | 使用場面 |
|----------|------|----------|
| `/sdd` | 7フェーズワークフロー | 新機能、複雑な変更 |
| `/spec-review` | 仕様検証 | 実装前の仕様確認 |
| `/code-review` | コードレビュー | コミット前（並列エージェント） |
| `/quick-impl` | 高速実装 | 明確な小規模タスク |
| `/project-setup` | ルール生成 | プロジェクト固有ルールの自動生成 |
| `/stack-consult` | スタック相談 | 新規プロジェクトの技術選定・構築 |
| `/resume` | セッション再開 | 進捗ファイルから作業を再開 |
| `/debug` | 体系的デバッグ | エラー分析・根本原因特定・修正 |

---

## 7フェーズ SDD ワークフロー

`/sdd` コマンドは包括的な開発ワークフローを実行します:

```mermaid
flowchart LR
    D[1. Discovery<br/>問題定義] --> E[2. Exploration<br/>コード探索]
    E --> C[3. Clarification<br/>質問]
    C --> A[4. Architecture<br/>設計]
    A --> I[5. Implementation<br/>実装]
    I --> R[6. Review<br/>品質確認]
    R --> S[7. Summary<br/>完了記録]

    style D fill:#e1f5fe
    style E fill:#e1f5fe
    style C fill:#fff3e0
    style A fill:#e8f5e9
    style I fill:#e8f5e9
    style R fill:#fce4ec
    style S fill:#f3e5f5
```

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

## 長時間作業サポート

[Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) に基づく設計:

```mermaid
flowchart TD
    subgraph Session1[初回セッション]
        I[INITIALIZER] --> PF[進捗ファイル作成]
        PF --> FD[機能分解]
    end

    subgraph SessionN[継続セッション]
        SS[SessionStart Hook] --> RP[進捗読み込み]
        RP --> C[CODING: 1機能実装]
        C --> T[テスト]
        T --> UP[進捗更新]
    end

    Session1 --> SessionN
    SessionN --> SessionN

    style I fill:#e8f5e9
    style C fill:#e1f5fe
```

| ロール | タイミング | 実行内容 |
|--------|------------|----------|
| **INITIALIZER** | 初回セッション | 進捗ファイル作成、機能分解、状態初期化 |
| **CODING** | 各セッション | 進捗読み込み、1 機能実装、テスト、進捗更新 |

### 進捗ファイル

```
.claude/workspaces/
└── {workspace-id}/           # 形式: {branch}_{path-hash} 例: main_a1b2c3d4
    ├── claude-progress.json  # 進捗ログと再開コンテキスト
    ├── feature-list.json     # 機能/タスクのステータス追跡
    └── logs/
        ├── subagent_activity.log
        └── sessions/
```

**ワークスペース ID**: Git ブランチ名とパスのハッシュで構成。Git worktree ごとに分離され、複数プロジェクトの同時実行をサポート。

> **なぜ JSON か？** 「モデルは Markdown ファイルと比較して JSON ファイルを不適切に変更する可能性が低い」- Anthropic

---

## エージェント一覧

```mermaid
flowchart TB
    Main[メインエージェント<br/>Orchestrator]

    subgraph Analysis[分析]
        CE[code-explorer<br/>Sonnet]
        CA[code-architect<br/>Sonnet]
        SA[system-architect<br/>Opus]
    end

    subgraph Implementation[実装]
        FE[frontend-specialist<br/>inherit]
        BE[backend-specialist<br/>inherit]
        PM[product-manager<br/>Opus]
    end

    subgraph Review[レビュー]
        QA[qa-engineer<br/>Sonnet]
        SEC[security-auditor<br/>Sonnet]
    end

    subgraph Other[その他]
        DO[devops-sre]
        UI[ui-ux-designer]
        TW[technical-writer]
        LM[legacy-modernizer]
    end

    Main --> Analysis
    Main --> Implementation
    Main --> Review
    Main --> Other
```

| カテゴリ | エージェント | 用途 |
|----------|--------------|------|
| **分析** | `code-explorer` | 深いコードベース分析（読み取り専用） |
| | `code-architect` | 機能設計ブループリント |
| | `system-architect` | システムレベル設計、ADR（Opus） |
| **実装** | `frontend-specialist` | UI 実装 |
| | `backend-specialist` | API 実装 |
| | `product-manager` | 要件収集、PRD 作成（Opus） |
| **レビュー** | `qa-engineer` | テスト戦略、カバレッジ分析 |
| | `security-auditor` | OWASP Top 10、脆弱性レビュー |
| **その他** | `devops-sre` | インフラ、CI/CD |
| | `ui-ux-designer` | デザインシステム |
| | `technical-writer` | ドキュメント |
| | `legacy-modernizer` | 安全なリファクタリング |

---

## ベストプラクティス

### 推奨

- 複雑な作業は `/sdd` で開始
- 探索作業は積極的にサブエージェント（特に `code-explorer`）に移譲
- 主要タスク間で `/clear` を使用
- コードより先に仕様を書く
- コミット前に `/code-review` を実行
- 長時間タスクには JSON 進捗追跡を使用

### 非推奨

- 探索フェーズのスキップ
- メインスレッドでのコンテキスト蓄積
- 秘密情報のハードコード
- security-auditor の指摘を無視

---

## プロジェクト固有ルールとの併用

SDD Toolkit はスタック非依存の汎用ワークフローを提供します。プロジェクト固有のルールは Claude Code の公式機能 `.claude/rules/` で管理できます。

### 使い分け

| 用途 | 推奨アプローチ |
|------|----------------|
| **汎用ワークフロー** | SDD Toolkit のスキル・エージェント |
| **プロジェクト固有の規約** | `.claude/rules/` |
| **技術スタック固有のルール** | `.claude/rules/` + `paths:` 条件 |

### `/project-setup` コマンド

プロジェクト固有ルールを自動生成:

```bash
/project-setup           # プロジェクト全体を分析
/project-setup frontend  # フロントエンドにフォーカス
```

詳細: [Manage Claude's memory](https://code.claude.com/docs/en/memory)

---

## 参照資料

### Anthropic Engineering Blog

| 記事 | 内容 |
|------|------|
| [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) | 6 Composable パターン |
| [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Initializer + Coding パターン |
| [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) | コンテキスト管理 |
| [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | コンテキストエンジニアリング |
| [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk) | 検証アプローチ |
| [Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) | Orchestrator-Workers |
| [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | スキルパターン |
| [The "think" tool](https://www.anthropic.com/engineering/claude-think-tool) | 構造化推論 |
| [Demystifying evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) | 評価メトリクス |

### Claude Code 仕様

- [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)
- [Agent Skills](https://code.claude.com/docs/en/skills)
- [Hooks Reference](https://code.claude.com/docs/en/hooks)

---

## プラグイン開発

このプラグインを拡張・修正する場合は `docs/DEVELOPMENT.md` を参照してください。

---

## ライセンス

MIT
