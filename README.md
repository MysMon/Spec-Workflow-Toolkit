# Spec-Workflow Toolkit

**Claude Code 向け仕様駆動開発ツールキット**

複雑な機能開発を、専門AIエージェントの支援を受けながら段階的に進めるプラグインです。
各段階で確認・判断でき、中断した作業も途中から再開できます。

---

## クイックスタート

### インストール

```bash
# プラグインディレクトリからインストール
/plugin install spec-workflow-toolkit@claude-plugin-directory

# または開発用にローカルロード
claude --plugin-dir /path/to/spec-workflow-toolkit
```

### 基本的な使い方

```bash
# 複雑な機能開発（段階的に進行、中断・再開可能）
/spec-workflow ユーザー認証機能を OAuth 対応で実装

# 小規模タスクの高速実装
/quick-impl README のタイポを修正

# コードレビュー
/code-review staged

# セッション再開
/resume
```

---

## コマンド一覧

| コマンド | 用途 | 使用場面 |
|----------|------|----------|
| `/spec-workflow` | 段階的な開発ワークフロー | 新機能、複雑な変更 |
| `/quick-impl` | 高速実装 | 明確な小規模タスク |
| `/spec-review` | 仕様検証 | 実装前の仕様確認 |
| `/code-review` | コードレビュー | コミット前 |
| `/review-response` | レビュー対応 | PRレビューコメントへの対応 |
| `/review-insights` | インサイトレビュー | 蓄積されたインサイトを評価・反映 |
| `/project-setup` | ルール生成 | プロジェクト固有ルールの自動生成 |
| `/stack-consult` | スタック相談 | 新規プロジェクトの技術選定 |
| `/resume` | セッション再開 | 進捗ファイルから作業を再開 |
| `/debug` | 体系的デバッグ | エラー分析・根本原因特定 |
| `/merge-conflict` | コンフリクト解決 | マージコンフリクトの体系的解決 |
| `/doc-audit` | ドキュメント監査 | コードとドキュメントの整合性検証 |
| `/ci-fix` | CI失敗対応 | CI/CDパイプライン失敗の診断 |
| `/hotfix` | 緊急修正 | 本番障害の迅速な対応 |

---

## 7フェーズ Spec-Workflow

`/spec-workflow` は、大きな機能開発を7段階に分けて進めるコマンドです。

**7段階に分ける理由**
- 各段階で確認できるため、誤った方向に進み続けることを防ぐ
- 探索→設計→実装の順序で、手戻りコストを最小化
- 長時間作業でも途中で中断・再開が可能

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

| フェーズ | ユーザー操作 | システムの処理 |
|----------|--------------|----------------|
| 1. Discovery | 機能要件を説明 | 問題定義・制約を整理 |
| 2. Exploration | 分析結果を確認 | 既存コードを並列分析 |
| 3. Clarification | 質問に回答、仕様を承認 | 曖昧さを解消し仕様を作成 |
| 4. Architecture | 設計案を確認・承認 | 複数角度から設計を分析 |
| 5. Implementation | 進捗を確認 | 1機能ずつ実装 |
| 6. Review | 指摘事項に対応 | QA・セキュリティ検証 |
| 7. Summary | 結果を確認 | 変更内容を文書化 |

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

- 複雑な作業は `/spec-workflow` で開始
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
| 曖昧な仕様での実装 | 不明確な要件で進行 | Phase 3 で質問 |

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
