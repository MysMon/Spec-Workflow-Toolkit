# SDD Toolkit Plugin v8.2.0 - 開発者ガイド

> **重要**: このファイルはこのリポジトリで作業する**プラグイン開発者向け**です。
> ユーザーがプラグインをインストールすると、コンテキストは `SessionStart` フック（`hooks/sdd_context.sh`）を通じて配信されます。

---

## プラグインの核心目標

このプラグインは以下の**4つの目標**を達成するために設計されています:

1. **長時間の自律作業セッション** - コンテキストウィンドウを越えた継続的なタスク完了
2. **徹底したスペック駆動開発** - 曖昧さゼロ、コードより先に仕様
3. **サブエージェントへの積極的移譲** - メインコンテキスト保護
4. **ユーザーへの十分な質問** - 不明点は必ず確認

---

## v8.2.0 の新機能

[Anthropic 公式ベストプラクティス](https://www.anthropic.com/engineering/claude-code-best-practices)、[長時間実行エージェント向けハーネス](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)、[公式プラグイン](https://github.com/anthropics/claude-plugins-official) に基づく継続的な改善:

### v8.2.0 の主な改善点

1. **SessionStart でのロール検出強化** - 進捗ファイルの有無に基づいて「INITIALIZER」または「CODING」ロールを明示的に表示
2. **コンテキスト保護の強化** - 長時間自律セッション向けに「自分でコードを探索しないで」指令を明確な根拠と共に追加
3. **公式パターンとのツール整合** - `code-explorer` と `code-architect` に Jupyter ノートブックサポート用の `NotebookRead` を追加
4. **徹底度ベースのモデル指針** - `code-explorer` の説明に組み込み Explore (Haiku) とこのエージェント (Sonnet) の使い分けを記載
5. **モデル選択戦略ドキュメント** - Opus/Sonnet/Haiku/inherit の使用に関するより明確なガイダンス

---

## 公式ベストプラクティスとの関係

このプラグインは以下の公式資料に基づいています:

- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Official Plugin Marketplace](https://github.com/anthropics/claude-plugins-official)
- [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)

### 公式との意図的な差異

このプラグインは公式 Anthropic プラグインに**触発されて**いますが、**コピーではありません**。

| 項目 | 公式 `feature-dev` | このプラグイン (SDD) | 理由 |
|------|-------------------|---------------------|------|
| **アーキテクチャ選択肢** | 3つのアプローチを提示 | **単一の決定的推奨** | 決定疲れを軽減; code-architect が内部で代替案を検討済み |
| **進捗形式** | `claude-progress.txt` (テキスト) | `claude-progress.json` (JSON) | 機械可読、誤変更されにくい |
| **エージェント専門化** | 汎用エクスプローラー | **12の専門エージェント** | ドメイン専門性で品質向上 |
| **信頼度閾値** | 80% (code-review のみ) | **全レビューで80%統一** | 一貫性で混乱を軽減 |
| **ワークフローフェーズ** | 7フェーズ | 7フェーズ + **明示的進捗追跡** | より良い再開サポート |

---

## ディレクトリ構造

```
sdd-toolkit/
├── .claude-plugin/
│   └── plugin.json          # プラグインメタデータ (v8.2.0)
├── commands/                # スラッシュコマンド
│   ├── sdd.md              # /sdd - 並列エージェントを使った7フェーズワークフロー
│   ├── code-review.md      # /code-review - 並列レビュー（信頼度 >= 80）
│   ├── spec-review.md      # /spec-review - 仕様検証
│   └── quick-impl.md       # /quick-impl - 高速実装
├── agents/                  # 専門サブエージェント（12ロール）
│   ├── code-explorer.md    # 深いコードベース分析（読み取り専用、permissionMode: plan）
│   ├── code-architect.md   # 機能実装ブループリント（決定的推奨）
│   ├── product-manager.md  # 要件収集（Bash/Edit 禁止）
│   ├── system-architect.md # システムレベル設計（ADR、model: opus）
│   ├── frontend-specialist.md  # UI 実装（model: inherit）
│   ├── backend-specialist.md   # API 実装（model: inherit）
│   ├── qa-engineer.md      # テスト（信頼度 >= 80）
│   ├── security-auditor.md # 監査（permissionMode: plan、信頼度 >= 80）
│   ├── devops-sre.md
│   ├── ui-ux-designer.md
│   ├── technical-writer.md
│   └── legacy-modernizer.md
├── skills/
│   ├── core/               # 普遍的原則
│   │   ├── sdd-philosophy/
│   │   ├── interview/
│   │   └── security-fundamentals/
│   ├── detection/
│   │   └── stack-detector/
│   └── workflows/          # クロススタックパターン
│       ├── code-quality/
│       ├── testing/
│       ├── git-mastery/
│       ├── api-design/
│       ├── migration/
│       ├── observability/
│       ├── long-running-tasks/
│       ├── parallel-execution/
│       └── progress-tracking/  # JSON ベースの状態永続化
├── hooks/
│   ├── hooks.json
│   ├── sdd_context.sh      # SessionStart - コンテキスト + 進捗検出
│   ├── subagent_init.sh    # SubagentStart
│   ├── safety_check.py     # PreToolUse (Bash)
│   ├── prevent_secret_leak.py  # PreToolUse (Write/Edit)
│   ├── security_audit_bash_validator.py  # PreToolUse (security-auditor Bash)
│   ├── post_edit_quality.sh    # PostToolUse
│   ├── subagent_summary.sh # SubagentStop
│   └── session_summary.sh  # Stop
└── docs/
    └── specs/
        └── SPEC-TEMPLATE.md
```

---

## 設計哲学: このプラグインが存在する理由

### プラグインの目的

このプラグインは特定の問題を解決するために存在します: **Claude が複雑で長時間実行される開発タスクをコンテキストやフォーカスを失うことなく完了できるようにすること**。

主要目標:
1. **メインコンテキストの保護** - 探索と分析をサブエージェントに移譲
2. **完全性の確保** - 全体像を理解せずに実装しない
3. **再開のサポート** - セッションの中断と継続を可能に
4. **品質の維持** - 信頼度ベースのフィルタリングでノイズを削減

---

## 主要設計決定

### 1. サブエージェントによるコンテキスト保護

メインオーケストレーターは専門エージェントに移譲してトークンを保護:
- 探索は独立したコンテキストウィンドウで実行
- 結果/サマリーのみがメインコンテキストに戻る
- 長時間セッションの効果を維持

### 2. 7フェーズワークフロー（公式パターン）

[feature-dev plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/feature-dev) に基づく:
1. Discovery
2. **Codebase Exploration**（並列 code-explorer エージェント）
3. Clarifying Questions
4. **Architecture Design**（決定的推奨を持つ並列 code-architect エージェント）
5. Implementation
6. **Quality Review**（並列レビューエージェント + Haiku スコアラー）
7. Summary

### 3. code-explorer エージェント

深いコードベース分析スペシャリスト（公式パターンに準拠）:
- 4フェーズ分析: Discovery → Flow Tracing → Architecture → Implementation Details
- **必須**: すべての発見に file:line 参照を提供
- ツール: Glob, Grep, LS, Read, NotebookRead, WebFetch, WebSearch, TodoWrite
- 真の読み取り専用操作のための `permissionMode: plan`
- オーケストレーターが読むべきキーファイルリスト（5-10）を返す
- 徹底度レベル: quick（組み込み Explore を検討）、medium、very thorough

### 4. code-architect エージェント

機能実装ブループリントスペシャリスト（公式パターンに準拠）:
- **決定的推奨を提供**（複数オプションではなく）
- 3フェーズ設計: Analysis → Design → Delivery
- file:line エビデンス付きで既存コードベースパターンに基づく推奨
- 具体的なファイルパスとビルドシーケンスを含む実装マップを返す
- 設計のみの操作のための `permissionMode: plan`（実装なし）

### 5. 長時間タスクサポート（Initializer + Coding パターン）

[Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) に基づく:

**問題**: 複雑なタスクは単一のコンテキストウィンドウでは完了できない。新しいセッションは以前の作業の記憶なしに開始される。

**解決策**: 2ロールパターン:

| ロール | タイミング | 実行内容 |
|--------|------------|----------|
| **Initializer** | 初回セッション | 進捗ファイル作成、機能分解、状態初期化 |
| **Coding** | 各セッション | 進捗読み込み、1機能実装、テスト、進捗更新 |

**主要ファイル:**
```
.claude/
├── claude-progress.json    # 再開コンテキスト付き進捗ログ
└── feature-list.json       # 機能/タスクのステータス追跡
```

**重要な洞察**: 「一度に1機能」- 一度に多くのことをやりすぎない。次に移る前に1つの機能を完了してテストすることに集中。

**なぜ Markdown より JSON か**: 「モデルは Markdown ファイルと比較して JSON ファイルを不適切に変更する可能性が低い」

**SessionStart フック**: 進捗ファイルを自動検出し、再開コンテキストを抽出。

### 6. 信頼度スコアリング（詳細なルーブリック付き80%閾値）

[公式 code-reviewer パターン](https://github.com/anthropics/claude-plugins-official) に基づく:

| スコア | 意味 | 使用場面 |
|--------|------|----------|
| **0** | 全く自信なし | 誤検出、既存の問題 |
| **25** | やや自信あり | 実際かもしれないが未検証 |
| **50** | 中程度の自信 | 実際だが軽微/まれ |
| **75** | 高い自信 | 検証済み、重大な影響 |
| **100** | 完全に確信 | 確実に実際、頻繁に発生 |

- 信頼度 >= 80% の問題のみ報告
- Haiku エージェントを使って各問題を並列スコアリング
- CLAUDE.md の問題については、ガイドラインが明示的にその問題に言及していることを確認

### 7. 再開可能セッション

SessionStart フックは自動的に:
- `.claude/claude-progress.json` または `claude-progress.json` を検出
- 再開コンテキスト（位置、次のアクション、ブロッカー）を抽出
- `feature-list.json` から機能進捗を報告
- 明確な再開指示を提供

### 8. 並列エージェント実行

独立した作業には複数エージェントを同時起動:
- Phase 2: 2-3 の code-explorer エージェント（異なるフォーカス）
- Phase 4: 2-3 の code-architect エージェント（異なる優先度）
- Phase 6: 3 つのレビューエージェント（qa、security、verification）+ N の Haiku スコアラー
- /code-review: 5 つの並列 Sonnet エージェント + N の並列 Haiku スコアラー

### 9. 読み取り専用監査モード

`permissionMode: plan` を使用するエージェント:
- `code-explorer` - 副作用なしで徹底的な探索を確保
- `code-architect` - 設計のみ、実装なし
- `security-auditor` - 監査の整合性を維持

---

## ツール設定

公式パターンに沿ったツール構成:

| エージェント | ツール | 備考 |
|--------------|--------|------|
| `code-explorer` | Glob, Grep, LS, Read, NotebookRead, WebFetch, WebSearch, TodoWrite | Jupyter ノートブック分析用に `NotebookRead` |
| `code-architect` | Glob, Grep, LS, Read, NotebookRead, WebFetch, WebSearch, TodoWrite | データサイエンスワークフロー分析用に `NotebookRead` |
| `security-auditor` | Read, Glob, Grep, Bash（検証済み） | Bash は PreToolUse フックで読み取り専用監査コマンドに制限 |

**注**: `KillShell` と `BashOutput` は、このプラグインの分析重視エージェントには一般的に不要なため除外。

---

## モデル選択戦略

[公式サブエージェントドキュメント](https://code.claude.com/docs/en/sub-agents) に基づく:

| モデル | 推奨用途 |
|--------|----------|
| **Opus** | 複雑な推論、マルチステップ操作、高影響度の決定 |
| **Sonnet** | ほとんどのタスクのデフォルト、バランスの取れたコスト/能力 |
| **Haiku** | 高速な読み取り専用探索、単純なスコアリングタスク |
| **inherit** | 親会話のモデルに合わせる（実装エージェント向け） |

### このプラグインのモデル割り当て

| エージェントタイプ | モデル | 理由 |
|-------------------|--------|------|
| **system-architect** | **Opus** | ADR とシステム設計は深い推論とマルチステップ分析が必要 |
| 分析エージェント（code-explorer, code-architect） | Sonnet | 深い分析には推論が必要だが、システム設計ほど複雑ではない |
| 実装エージェント（frontend/backend-specialist） | **inherit** | 親モデルに従う; ユーザーがコスト/品質のトレードオフを制御 |
| スコアリングエージェント（/code-review の Haiku） | Haiku | 高速、低コスト、信頼度スコアリングには十分 |
| その他のエージェント | Sonnet | 専門タスクに対するバランスの取れたコスト/能力 |

**組み込み Explore エージェントとの違い**:
- 組み込み `Explore` は高速で軽量な探索に Haiku を使用
- 私たちの `code-explorer` はより多くの推論を必要とする深い4フェーズ分析に Sonnet を使用
- 私たちの `system-architect` はアーキテクチャ決定が永続的で横断的な影響を持つため **Opus** を使用

---

## 開発ガイドライン

### 新しいエージェントの追加

`agents/[name].md` を YAML フロントマターで作成:

```yaml
---
name: agent-name
description: |
  [簡潔な説明]
  以下の場合に積極的に使用:
  - [トリガー条件 1]
  - [トリガー条件 2]
  トリガーフレーズ: keyword1, keyword2, keyword3
model: sonnet  # sonnet, opus, haiku, または inherit
tools: Read, Glob, Grep, Write, Edit, Bash
disallowedTools: [任意のリスト]
permissionMode: default  # default, acceptEdits, plan, dontAsk, bypassPermissions
skills: skill1, skill2
---

# Role: [タイトル]

[エージェント指示...]
```

**permissionMode の説明**:
| モード | 用途 |
|--------|------|
| `default` | 標準の権限プロンプト |
| `acceptEdits` | ファイル変更を自動承認 |
| `plan` | 読み取り専用モード（監査向け） |
| `dontAsk` | 権限プロンプトを黙って拒否 |

### 新しいスキルの追加

`skills/[category]/[name]/SKILL.md` を作成:

```yaml
---
name: skill-name
description: |
  [機能の説明]
  トリガーフレーズ: keyword1, keyword2
allowed-tools: Read, Glob, Grep
model: sonnet
user-invocable: true
context: fork  # 任意: 独立した実行
agent: general-purpose  # 任意: エージェントタイプ
---

# スキル名

[指示...]
```

### 新しいコマンドの追加

`commands/[name].md` を作成:

```yaml
---
description: "[コマンドの説明]"
argument-hint: "[任意のヒント]"
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, Task
---

# /[command-name]

[指示...]
```

### フックの変更

`hooks/hooks.json` を編集:

| イベント | 用途 |
|----------|------|
| `SessionStart` | コンテキスト注入 + 進捗ファイル検出 |
| `SubagentStart` | サブエージェント初期化 |
| `PreToolUse` | ツール呼び出しの検証/ブロック |
| `PostToolUse` | ツール使用後の品質チェック |
| `SubagentStop` | サブエージェント完了ログ |
| `Stop` | セッションサマリー |

---

## 変更のテスト

1. このディレクトリで Claude Code を実行
2. コマンドをテスト: `/sdd`、`/code-review` など
3. エージェントをテスト: "code-explorer エージェントを起動して..."
4. スキルをテスト: リクエストでスキル名を参照
5. SessionStart フック出力を確認
6. サンプル `.claude/claude-progress.json` で進捗ファイル検出をテスト

---

## このリポジトリでの運用ルール

### セキュリティ（OPSEC）

- 実際の API キーやシークレットをコミットしない
- フックが自動的にシークレットリークを検出してブロック
- 主要な変更前に `security-auditor` を実行

### コード品質

- 実装前にテストを書く
- セマンティックコミット: `feat:`, `fix:`, `docs:`, `refactor:`
- 編集後に `code-quality` スキルを適用
- 信頼度閾値: すべてのレビューで 80%

### このリポジトリでの移譲

このプラグインで作業する際:
- 既存コードの理解には `code-explorer` を使用
- 設計決定には `system-architect` を使用
- 新しいエージェント/スキルのテストには `qa-engineer` を使用
- リリース前には `security-auditor` を使用

---

## 公式資料

- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Subagent Documentation](https://code.claude.com/docs/en/sub-agents)
- [Skills Documentation](https://code.claude.com/docs/en/skills)
- [Official Plugin Marketplace](https://github.com/anthropics/claude-plugins-official)
