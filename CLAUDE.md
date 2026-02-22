# Spec-Workflow Toolkit プラグイン - 開発者ガイド

このファイルは**このプラグインリポジトリで作業する Claude** 向けのもの。
ユーザーは `SessionStart` フック経由でコンテキストを受け取るため、このファイルは不要。

## このプラグインの機能

Anthropic の6つの合成可能パターンを長時間の自律作業に実装する Claude Code プラグイン:
Plan→Review→Implement→Revise ワークフロー（反復的改善を含む4コマンド）、13の専門サブエージェント、TDD 統合、エバリュエーター-オプティマイザーループ、チェックポイントベースのエラーリカバリ、進捗追跡。

## プロジェクト構造

```
.claude-plugin/plugin.json   # プラグインメタデータ
commands/                    # 17 スラッシュコマンド
agents/                      # 13 サブエージェント定義
skills/                      # 25 スキル定義
  core/                      #   6 コアスキル (subagent-contract, spec-philosophy, security-fundamentals, interview, bounded-autonomy, language-enforcement)
  detection/                 #   1 検出スキル (stack-detector)
  workflows/                 #   18 ワークフロースキル (team-orchestration, discussion-protocol を含む)
hooks/                       # イベントハンドラー (9 イベントタイプ, 14 ハンドラー) + Python バリデーター
docs/                        # DEVELOPMENT.md (詳細仕様), specs/
```

## 主要エントリーポイント

| タスク | 参照先 |
|------|------------|
| 計画（改善ループ付き）の理解 | `commands/spec-plan.md` |
| インタラクティブプランレビューの理解 | `commands/spec-review.md` |
| 実装フェーズの理解 | `commands/spec-implement.md` |
| 実装後の変更の理解 | `commands/spec-revise.md` |
| エージェントの動作を確認 | `agents/code-explorer.md`, `agents/code-architect.md` |
| スキルパターンの理解 | `skills/core/subagent-contract/SKILL.md` |
| フック実装の確認 | `hooks/hooks.json`, `hooks/spec_context.sh` |
| インサイト追跡の理解 | `commands/review-insights.md`, `hooks/insight_capture.sh` |
| Agent Team 統合の理解 | `skills/workflows/team-orchestration/SKILL.md` |
| マルチエージェント議論の理解 | `commands/discuss.md`, `skills/workflows/discussion-protocol/SKILL.md` |

## 開発ルール

### エージェントの編集 (`agents/*.md`)

YAML フロントマターフィールド:
- `name`: エージェント名（必須）
- `description`: 簡潔な説明（必須、プロアクティブ起動条件を含む）
- `model`: sonnet（デフォルト）、opus、haiku、inherit
- `tools`: 利用可能なツール
- `disallowedTools`: 明示的に禁止するツール
- `permissionMode`: default、acceptEdits、plan、dontAsk
- `skills`: スキル名の YAML 配列（コンテキスト保護のため最小限に）
- `hooks`: エージェント固有フック定義（任意。詳細は `docs/DEVELOPMENT.md`「コンポーネントスコープフック」参照）

### スキルの編集 (`skills/**/SKILL.md`)

**二段階ロード構造:** SKILL.md はコンテキストに常時注入されるため、フロントマター + ポインターのみに留める。詳細手順は `INSTRUCTIONS.md` に分離し、必要時のみ Read ツールで読み込む。

YAML フロントマターフィールド:
- `name`: スキル名（必須）
- `description`: 説明（必須、`Use when:` / `Trigger phrases:` を含む。3-4行に圧縮）
- `allowed-tools`: 実行中に利用可能なツール
- `model`: sonnet（デフォルト）
- `user-invocable`: ユーザーから直接呼び出し可能か（デフォルト: false）

コンテンツ分離（二段階ロード）:
- `INSTRUCTIONS.md`: 詳細手順（オンデマンド読み込み。SKILL.md 本文からポインターで参照）
- `REFERENCE.md`, `EXAMPLES.md`: 補足資料（オンデマンド読み込み）
- `scripts/`: 実行可能ヘルパー（read ではなく run）

### コマンドの編集 (`commands/*.md`)

- `description`: `/help` に表示
- `argument-hint`: 引数のプレースホルダー
- `allowed-tools`: 実行中に利用可能なツール

### フックの編集 (`hooks/hooks.json`)

PreToolUse hooks の exit code:
- exit 0 + `permissionDecision: "deny"` = 安全なブロック（推奨）
- exit 2 = blocking error
- exit 1, 3, etc. = non-blocking error（ツールが実行される可能性あり）

**グローバルフック（9 イベントタイプ、hooks.json に 14 ハンドラー）:**

| フック | スクリプト | 目的 |
|------|--------|---------|
| SessionStart | `spec_context.sh` | 進捗ファイルの読み込みと未評価インサイトの通知 |
| SessionStart | `enforce_japanese_mode.sh` | 日本語モードの強制 |
| PreToolUse (Bash) | `safety_check.py` | 危険なコマンドのブロック |
| PreToolUse (Write\|Edit) | `prevent_secret_leak.py` | 秘密情報の漏洩防止 |
| PreToolUse (WebFetch\|WebSearch) | `external_content_validator.py` | 外部 URL の検証（SSRF 防止） |
| PostToolUse | `audit_log.sh` | ツール使用状況追跡の監査ログ |
| PostToolUseFailure | `audit_log.sh` | 失敗したツール呼び出しの監査ログ |
| PreCompact | `pre_compact_save.sh` | コンテキストコンパクション前の進捗保存 |
| SubagentStop | `subagent_summary.sh` | サブエージェント結果のサマリ |
| SubagentStop | `insight_capture.sh` | サブエージェント出力からマーク済みインサイトのキャプチャ |
| SubagentStop | `verify_references.py` | サブエージェント出力の file:line 参照の検証 |
| Stop | `session_summary.sh` | 終了時のセッションサマリ記録 |
| TeammateIdle | `teammate_quality_gate.sh` | チームメンバーの品質ゲート |
| SessionEnd | `session_cleanup.sh` | セッション終了時のリソースクリーンアップ |

**エージェント固有フック:** エージェントは YAML フロントマターで独自のフックを定義可能（例: `security-auditor.md` はより厳格な Bash バリデーターを定義）。そのエージェントがアクティブな場合のみ実行される。詳細は `docs/DEVELOPMENT.md`「コンポーネントスコープフック」を参照。

完全なフック仕様とコード例は `docs/DEVELOPMENT.md` を参照。

## コンテンツガイドライン

**スキルの SKILL.md はコンテキストに常時注入される。SKILL.md はフロントマター + ポインターのみ（500バイト以内目標）とし、詳細手順は `INSTRUCTIONS.md` に分離する（二段階ロード構造）。エージェントも同様にコンテキストに注入されるため簡潔に保つ。**

### URL と参照

skills/agents/commands では URL を使わず、プレーンテキストで出典を示す。
URL は `README.md` と `docs/DEVELOPMENT.md` にのみ記載する。

| する | しない |
|----|-------|
| `From Claude Code Best Practices:` | `From [Claude Code Best Practices](https://...):` |
| プレーンテキスト出典表記 | `## Sources` や `## References` セクション |

外部リソースを採用する場合は `docs/DEVELOPMENT.md` "Official References" に URL を追加する。

### README

README.md は**ユーザー向けドキュメント**（200-250行）。

**含めるもの:** プラグイン概要、クイックスタート、コマンド一覧、1つのダイアグラム、ベストプラクティス、DEVELOPMENT.md へのリンク

**除外するもの（DEVELOPMENT.md に移動）:** 実装の詳細、複数のダイアグラム、網羅的なリファレンス、L1/L2/L3 の詳細

**テスト**: 新規ユーザーが30秒でこれが何かを理解し使い始められるか？

### 変更後チェックリスト

コマンド・スキル・エージェント・フックの追加・削除・リネーム時のチェックリスト:

1. `CLAUDE.md`: プロジェクト構造のカウントを更新
2. `README.md`: コマンド一覧テーブルに追加/削除（250行以内を維持）
3. `docs/DEVELOPMENT.md`: 関連セクションがあれば更新（テンプレート・スペック変更時）

### バージョン

バージョンは `plugin.json` のみで管理する（Single Source of Truth）。

### 陳腐化の防止

外部ツール・API の変更で陳腐化するコンテンツを避ける。

| 避ける | 代わりに |
|-------|---------|
| 特定の API メソッド名 | 概念的な説明（「参照を検索」） |
| バージョン番号（"v2.1.0"） | 「利用可能な場合」または省略 |
| 規定的なツール要件 | 代替案付きの例 |

Skills ではプロセスを定義し、静的知識は避ける。年が必要な場合はシステム時刻から導出（`date +%Y`）。

詳細は `docs/DEVELOPMENT.md`「コマンドとエージェントのコンテンツガイドライン」を参照。

### 表記基準

L1/L2/L3 マーカーとセクション見出しの詳細な書式は `docs/specs/notation-standard.md` を参照。
ファイルの編集・作成時は表記基準に従うこと。

## バリデーション

```bash
/plugin validate
```

## ルール階層（L1/L2/L3）

このプラグインは正確性と創造的な問題解決のバランスを取るため、3レベルのルール階層を使用:

| レベル | 名前 | 適用 | スキル/コマンドでの表記 |
|-------|------|-------------|-------------------|
| **L1** | ハードルール | 絶対に破らない | `NEVER`、`ALWAYS`、`MUST` |
| **L2** | ソフトルール | デフォルト、根拠があればオーバーライド | `should`、`by default` |
| **L3** | ガイドライン | 推奨事項 | `consider`、`prefer`、`recommend` |

**マーカーの書式:**
- L1 項目: `- MUST: 内容` / `- NEVER: 内容` / `- ALWAYS: 内容`（コロン必須、太字不要）
- L2 項目: マーカーなし平文（セクション見出しで L2 を明示）
- L3 項目: `- consider: 内容` / `- prefer: 内容` / `- recommend: 内容`

**見出しの書式（日本語ファイル）:**
- `## ルール（L1 - ハード）` / `## デフォルト（L2 - ソフト）` / `## ガイドライン（L3）`（全角括弧）

**指示を書く際:**
- L1 は控えめに使用（セキュリティ、安全性、データ整合性）
- L2 は例外がありうるベストプラクティスに
- L3 はコンテキストに依存する提案に

完全な仕様は `docs/DEVELOPMENT.md`「指示設計ガイドライン」を参照。

## ルール（L1 - ハード）

- MUST: SKILL.md はフロントマター + ポインター行のみ（500 バイト以内目標）。詳細手順は `INSTRUCTIONS.md` に分離（二段階ロード構造）
- MUST: コマンドの `allowed-tools` にコマンド内で参照する全ツールを含める
- MUST: コマンド・スキル・エージェント・フックの追加・削除・リネーム時は変更後チェックリストを実行し、3ファイル全ての更新が完了するまで作業完了としない
- MUST: PreToolUse hooks では JSON decision control (`permissionDecision: "deny"`) with exit 0 を使用
- MUST: バージョンは `plugin.json` のみで管理する（Single Source of Truth）
- NEVER: skills/agents/commands に URL を記載しない
- NEVER: ドキュメントタイトルや本文にバージョン番号を記載しない
- NEVER: PreToolUse hooks で exit 1, 3 等を安全なブロックとして使用しない
- MUST: L1/L3 マーカー（MUST:/NEVER:/ALWAYS:/consider:/prefer:/recommend:）はリテラルキーワードとして保持し、日本語に翻訳しない
- NEVER: L1 マーカーの日本語訳（必ず、絶対に、常に）をルール項目のプレフィックスとして使用しない
- MUST: L1 マーカーの書式は `- MUST: 内容` の形式を使用する（コロン必須、太字不要）
- MUST: L1/L2/L3 セクション見出しは標準形式を使用する（日本語: `## ルール（L1 - ハード）` 等）

## デフォルト（L2 - ソフト）

- セマンティックコミットを使用: `feat:`, `fix:`, `docs:`, `refactor:`
- フックスクリプトは bash と zsh の両方でテスト
- 外部リソース採用時は `docs/DEVELOPMENT.md` "Official References" に URL を追加
- skills/agents/commands ではプレーンテキスト帰属のみ使用
- README.md の参照は必要最小限（3-5件以内）
- README.md は 200-250 行以内に収める
- スキルの詳細手順は `INSTRUCTIONS.md` に、補足資料は `REFERENCE.md`, `EXAMPLES.md` に分離
- 日本語ファイルの括弧は全角 `（）`、英語ファイルは半角 `()` を使い分ける
- リストマーカーはハイフン `-` に統一（`*` は使用しない）
- 表記の詳細基準は `docs/specs/notation-standard.md` を参照

## ガイドライン（L3）

- consider: 実行可能ヘルパーは `scripts/` に配置（read ではなく run）
- consider: Skills ではプロセスを定義し、静的知識は避ける
- prefer: 年が必要な場合はシステム時刻から導出（`date +%Y`）
- consider: 外部ツール・API のバージョン固有情報を避け、陳腐化を防止
- consider: L1/L2/L3 セクションをネストする場合は `###` で同じラベル形式を使用する

## 詳細情報

- **詳細仕様とテンプレート**: `docs/DEVELOPMENT.md`
- **ユーザー向けドキュメント**: `README.md`
