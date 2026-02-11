---
description: "進捗ファイルから作業を再開する - コンテキストを復元し、最後のチェックポイントから継続"
argument-hint: "[任意: 'list' | workspace-id | project-name]"
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite
---

# /resume - セッション再開コマンド

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

進捗ファイルから長時間の自律的作業を再開し、コンテキストを復元して最後のチェックポイントから継続する。

## 目的

Anthropic の Effective Harnesses for Long-Running Agents における Initializer + Coding Agent パターンに基づく。

**課題:** コンテキストウィンドウには制限がある。複雑なタスクは単一セッションで完了できない。新規開始時、エージェントには過去の作業の記憶がない。

**解決策:** このコマンドは構造化された進捗ファイルを読み取り、コンテキストを復元して作業が停止した正確な位置から継続する。

## マルチプロジェクトのワークスペース分離

並行プロジェクトと git worktree をサポートするため、進捗ファイルはワークスペースごとに分離される。

### ワークスペース構造

```
.claude/workspaces/
├── main_a1b2c3d4/              # main ブランチのワークスペース
│   ├── claude-progress.json
│   ├── feature-list.json
│   └── logs/
│       ├── subagent_activity.log
│       └── sessions/
└── feature-auth_e5f6g7h8/      # feature ブランチの worktree
    ├── claude-progress.json
    └── logs/
```

### ワークスペース ID 形式

`{branch}_{path-hash}` 形式:
- `branch`: 現在の git ブランチ（例: `main`, `feature-auth`）
- `path-hash`: 作業ディレクトリパスの MD5 ハッシュ（8文字）

## 使用タイミング

- `/spec-plan`、`/spec-review`、`/spec-implement` が中断された後の新しいセッション開始時
- 複数日にわたる開発作業の継続
- コンテキストコンパクション後の復旧
- 明示的な `/clear` 後の再開
- 進行中の作業状態の確認
- ワークスペース/worktree 間の切り替え

---

## 実行手順

### フェーズ 1: ワークスペース検出

**目的:** 利用可能なワークスペースと進捗ファイルを検出・検証する。

**引数が "list" の場合:**

```bash
# 利用可能なすべてのワークスペースを一覧表示
ls -la .claude/workspaces/ 2>/dev/null
```

見つかった各ワークスペースについて以下を表示する:
- ワークスペース ID
- プロジェクト名（進捗ファイルから）
- ステータス（in_progress, completed, blocked）
- 最終更新タイムスタンプ
- 現在の位置

出力例:
```markdown
## 利用可能なワークスペース

| ワークスペース ID | プロジェクト | ステータス | 最終更新 | 位置 |
|-------------------|-------------|------------|----------|------|
| main_a1b2c3d4 | auth-feature | in_progress | 2025-01-16 | impl-in-progress |
| feature-api_e5f6g7h8 | api-refactor | completed | 2025-01-15 | 完了 |
```

**引数がワークスペース ID の場合:**
- `.claude/workspaces/{workspace-id}/claude-progress.json` を検索する
- 見つからない場合、エラーを報告する

**引数がプロジェクト名の場合:**
- すべてのワークスペースで一致するプロジェクト名を検索する
- 複数一致する場合、一覧を表示しユーザーに選択させる

**引数なしの場合:**
1. SessionStart フック出力に表示されたワークスペース ID を使用する（形式: `{branch}_{path-hash}`）
2. `.claude/workspaces/{workspace-id}/claude-progress.json` でワークスペース進捗ファイルを確認する

**進捗ファイルが見つからない場合:**
- 報告: 「このワークスペースの進捗ファイルが見つかりません。」
- 利用可能なワークスペースがあれば一覧表示する
- 提案: 「`/spec-plan` で計画を開始してください。」
- 終了

### フェーズ 2: 状態分析

**目的:** 進捗ファイルから現在の状態を理解する。

**進捗ファイルの読み取りと分析:**

```json
// claude-progress.json から抽出する主要フィールド:
{
  "workspaceId": "main_a1b2c3d4",
  "project": "...",
  "status": "in_progress | completed | blocked",
  "currentTask": "...",
  "resumptionContext": {
    "position": "停止した場所",
    "nextAction": "次にすべきこと",
    "keyFiles": ["file:line の参照"],
    "decisions": ["過去の判断"],
    "blockers": []
  }
}
```

**機能リストが存在する場合は読み取る:**

```json
// feature-list.json の主要フィールド:
{
  "workspaceId": "main_a1b2c3d4",
  "features": [
    {"id": "F001", "name": "...", "status": "completed"},
    {"id": "F002", "name": "...", "status": "in_progress"},
    {"id": "F003", "name": "...", "status": "pending"}
  ]
}
```

**進捗の計算:**
- 総機能数
- 完了した機能数
- 現在進行中の機能
- 残りの機能数

### フェーズ 3: Git 状態チェック

**目的:** git の状態が期待と一致するか検証する。

**親コンテキストでの実行が許容される理由:**
- git メタデータコマンド（`status`, `branch`, `log --oneline`）は出力が最小限
- これは状態の検証であり、コンテンツの分析ではない
- 再開ワークフローでは迅速な実行が重要
- コンテキスト消費が最小限（通常50行未満）

```bash
# コミットされていない変更の確認
git status --porcelain

# 最近のコミットを確認
git log --oneline -5

# 現在のブランチを確認
git branch --show-current

# worktree 内かどうかを確認
git worktree list
```

**コミットされていない変更がある場合:**
- 未コミットの作業についてユーザーに警告する
- 続行するかコミットを先にするか確認する

**git の状態が進捗ファイルと異なる場合:**
- 不一致を報告する
- ユーザーに対応方法を確認する

**現在のブランチがワークスペースと一致しない場合:**
- 警告: 「現在のブランチ `X` はワークスペース `Y` と一致しません」
- ワークスペースを切り替えるか続行するか確認する

### フェーズ 4: コンテキスト復元の表示

**目的:** 明確な再開コンテキストをユーザーに提示する。

**再開サマリーを表示する:**

```markdown
## 再開中: [プロジェクト名]

### ワークスペース
**ID**: `main_a1b2c3d4`
**ブランチ**: `main`
**パス**: `/path/to/project`

### 進捗
[====>     ] 4/10 機能 (40%)

### 現在の位置
**フェーズ:** [進捗ファイルからのフェーズ]
**タスク:** [現在のタスク]

### 前回のセッションサマリー
[最後のセッションエントリからのサマリー]

### 過去の主要な判断
- [判断 1]
- [判断 2]

### 主要ファイル
- `src/services/auth.ts:45` - AuthService の実装
- `prisma/schema.prisma:12` - User モデル

### ブロッカー
[ブロッカーの一覧、またはなし]

### 次のアクション
> [再開コンテキストからの具体的な次のアクション]
```

### フェーズ 5: ユーザー確認

**目的:** 続行前にユーザーの承認を得る。

**ユーザーに確認する:**

```
Question: "どのように進めますか？"
Header: "再開"
Options:
- "チェックポイントから続行する"（推奨）
- "まず詳細を確認する"
- "最初からやり直す（進捗をリセット）"
- "状態確認のみ（終了）"
```

**「チェックポイントから続行」の場合:**
- フェーズ 6 に進む

**「詳細を確認」の場合:**
- 完全な進捗ログを表示する
- 主要ファイルのサマリーを code-explorer エージェントに委任する（ファイルを直接読み取らないこと）:
  ```
  code-explorer エージェントを起動:
  タスク: 詳細ステータスレビュー用に主要ファイルをサマリー化
  入力: 進捗ファイルからの file:line 参照リスト
  Thoroughness: quick
  出力: 各ファイルの現在の状態の簡潔なサマリー
  ```
- エージェントのサマリーを表示する
- 確認画面に戻る

**「最初からやり直す」の場合:**
- 確認: 「現在の進捗がアーカイブされます。よろしいですか？」
- 確認された場合: 進捗ファイルを `.claude/workspaces/{id}/archived/{timestamp}/` に移動する
  - アーカイブパス形式: `.claude/workspaces/{id}/archived/{YYYY-MM-DD_HH-MM-SS}/`
  - すべての進捗ファイル（claude-progress.json, feature-list.json 等）をこのディレクトリに移動する
- `/spec-plan` の実行を提案して終了する

**「状態確認のみ」の場合:**
- 正常に終了する

### フェーズ 6: 作業再開

**目的:** チェックポイントから適切なエージェントで作業を再開する。

**機能リストから TodoWrite を初期化する:**

```
TodoWrite を feature-list.json と同期:
- 完了した機能を completed としてマーク
- 現在の機能を in_progress としてマーク
- 保留中の機能を pending として追加
```

**サブエージェントによるコンテキスト復元:**

**重要: 主要ファイルを直接読み取らないこと。サブエージェントに委任する。**

```
code-explorer エージェントを起動:
タスク: 再開コンテキスト用に主要ファイルをサマリー化
入力: `keyFiles` からの file:line 参照リスト
Thoroughness: quick
出力: 各ファイルの役割と現在の状態の簡潔なサマリー
```

エージェントのサマリー出力をコンテキスト復元に使用する。主要ファイルを直接読み取らないこと。

**code-explorer のエラーハンドリング:**
code-explorer が失敗またはタイムアウトした場合:
1. 進捗ファイルから利用可能な再開コンテキストを表示する（position, nextAction, decisions）
2. file:line 参照付きの主要ファイルリストを表示する（サマリーなし）
3. ユーザーに警告: 「主要ファイルのコンテキストを読み込めませんでした。進捗ファイルのデータのみ使用しています。」
4. ユーザーに確認する:
   ```
   Question: "コンテキスト復元が部分的に失敗しました。どのように進めますか？"
   Header: "続行"
   Options:
   - "限定的なコンテキストで続行する（進捗ファイルのみ）"
   - "まず主要ファイルを手動でレビューする"
   - "コンテキスト復元をリトライする"
   ```

**適切なワークフローを判定する:**

| 現在のフェーズ | アクション |
|----------------|-----------|
| `plan-discovery` / `plan-discovery-complete` | `/spec-plan` で要件収集を再開 |
| `plan-exploration-complete` | `/spec-plan` で仕様書作成を再開 |
| `plan-spec-approved` | `/spec-plan` でアーキテクチャ設計を再開 |
| `plan-complete` | `/spec-review` に進む |
| `review-complete` | `/spec-implement` に進む |
| `impl-starting` / `impl-in-progress` | `/spec-implement` で実装を再開 |
| `impl-review-complete` | 実装を最終化 |
| Blocked | まずブロッカーに対処 |

**コンテキストに基づいて適切なエージェントに委任する:**

実装作業の場合:
```
現在の機能のドメインを特定する:
- フロントエンド作業 → frontend-specialist に委任
- バックエンド作業 → backend-specialist に委任
- テスト作業 → qa-engineer に委任
- ドキュメント作成 → technical-writer に委任
```

**進捗ファイルを更新する:**

```json
// 新しいセッションエントリを追加
{
  "id": "[session-id]",
  "started": "[現在のタイムスタンプ]",
  "summary": "チェックポイントから再開",
  "continuing": true
}
```

---

## 進捗ファイルスキーマ

### claude-progress.json

```json
{
  "workspaceId": "main_a1b2c3d4",
  "project": "project-name",
  "started": "ISO タイムスタンプ",
  "lastUpdated": "ISO タイムスタンプ",
  "status": "in_progress | completed | blocked",
  "currentTask": "現在のタスク説明",
  "sessions": [
    {
      "id": "20250116_100000_abc1",
      "started": "ISO タイムスタンプ",
      "ended": "ISO タイムスタンプ",
      "summary": "達成した内容",
      "filesModified": ["file1.ts", "file2.ts"],
      "nextSteps": ["ステップ 1", "ステップ 2"]
    }
  ],
  "log": [
    {
      "timestamp": "ISO タイムスタンプ",
      "action": "実行した内容",
      "status": "success | failed",
      "files": ["影響を受けたファイル"]
    }
  ],
  "resumptionContext": {
    "position": "フェーズとステップの説明",
    "nextAction": "具体的な次のアクション",
    "keyFiles": ["file:line", "file:line"],
    "decisions": ["判断 1", "判断 2"],
    "blockers": []
  },
  "compactionHistory": [
    {
      "timestamp": "ISO タイムスタンプ",
      "positionAtCompaction": "コンパクション時の位置",
      "workspaceId": "main_a1b2c3d4"
    }
  ]
}
```

### feature-list.json

```json
{
  "workspaceId": "main_a1b2c3d4",
  "project": "project-name",
  "totalFeatures": 10,
  "completed": 3,
  "features": [
    {
      "id": "F001",
      "name": "機能名",
      "description": "この機能の説明",
      "status": "pending | in_progress | completed | blocked",
      "startedAt": "ISO タイムスタンプ（開始済みの場合）",
      "completedAt": "ISO タイムスタンプ（完了済みの場合）",
      "files": ["作成/修正されたファイル"]
    }
  ]
}
```

---

## 特殊ケースの処理

### コンテキストコンパクション後

PreCompact フックが発火すると、状態が自動保存される。コンパクション後:

1. このコマンドがコンパクション履歴を検出する
2. 報告: 「コンテキストが [タイムスタンプ] にコンパクションされました」
3. 完全な再開コンテキストを読み取る
4. 通常通り続行する

### ブロック状態

ステータスが "blocked" の場合:

1. ブロッカーの詳細を目立つように表示する
2. ユーザーにブロッカーの解決を依頼する
3. 解決後、進捗ファイルを更新する
4. 作業を続行する

### 完了状態

ステータスが "completed" の場合:

1. 報告: 「このプロジェクトは [日付] に完了としてマークされています」
2. 完了サマリーを表示する
3. ユーザーに以下を確認する:
   - 実施内容をレビューする
   - 関連する新しい作業を開始する
   - アーカイブして終了する

---

## 使用例

```bash
# 現在のワークスペースで作業を再開
/resume

# 追跡されているすべてのワークスペースを一覧表示
/resume list

# 特定のワークスペースを再開
/resume main_a1b2c3d4

# プロジェクト名で再開（すべてのワークスペースを検索）
/resume auth-feature

# 続行せずに状態を確認
/resume  # その後「状態確認のみ」を選択
```

## 他のコマンドとの連携

| 実行後 | /resume を使用するタイミング |
|--------|------------------------------|
| `/spec-plan` | 計画がワークフロー途中で中断された場合 |
| `/spec-review` | レビューがワークフロー途中で中断された場合 |
| `/spec-implement` | 実装がワークフロー途中で中断された場合 |
| `/clear` | コンテキストをクリアしたが続行したい場合 |
| コンパクション | コンテキストが自動的にコンパクションされた場合 |
| セッション終了 | 翌日に新しいセッションを開始する場合 |
| `git worktree add` | 別の worktree に切り替える場合 |

## 最良の結果を得るためのヒント

1. **進捗ファイルを最新に保つ**: 再開コンテキストが良いほど、スムーズに再開できる
2. **頻繁にコミットする**: git 履歴が進捗ファイルを補完する
3. **判断を記録する**: 将来のセッションが過去の選択を理解する必要がある
4. **nextAction を更新する**: 次にすべきことを具体的に記載する
5. **主要ファイルをリストする**: 素早いコンテキスト読み込みのために file:line 参照を含める
6. **ワークスペース ID を使用する**: ブランチ + ディレクトリの組み合わせを一意に識別する

## --continue フラグとの比較

| 側面 | `claude --continue` | `/resume` |
|------|---------------------|-----------|
| 復元対象 | 会話履歴 | 構造化された進捗状態 |
| スコープ | ディレクトリ内の最後のセッション | マルチセッションのプロジェクト状態 |
| コンテキスト | 完全なメッセージ履歴 | 厳選された再開コンテキスト |
| ワークスペース対応 | なし | あり |
| 最適な用途 | 直近の中断 | 長期間のプロジェクト |

---

## ルール（L1 - ハード）

安全かつ正確なセッション再開のために重要。

- MUST: 再開前に git 状態を検証する（サイレントなデータコンフリクトを防止）
- MUST: コミットされていない変更がある場合はユーザーに警告する
- MUST: 現在のブランチがワークスペースと一致しない場合はユーザーに警告する
- NEVER: git 状態が進捗ファイルと異なる場合、ユーザー確認なしに進行する
- MUST: 以下の場合は AskUserQuestion を使用する:
  - コミットされていない変更がある場合（確認: 続行するかコミットを先にするか）
  - ブランチの不一致が検出された場合（確認: ワークスペースを切り替えるか続行するか）
  - 複数のワークスペースが一致する場合（確認: どれを再開するか）
  - ユーザーが「最初からやり直す」を選択した場合（アーカイブの確認）
- NEVER: 進捗を無断で破棄する — リセット前にアーカイブする
- MUST: 再開作業の前に進捗ファイルを読み取る

## デフォルト（L2 - ソフト）

品質の高い再開のために重要。適切な理由がある場合はオーバーライド可能。

- 再開時に TodoWrite を feature-list.json と同期する
- 主要ファイルの読み取りはコンテキストサマリーのために `code-explorer` エージェントに委任する
- 機能完了率のプログレスバーを表示する
- コンテキストのために前回のセッションサマリーを表示する

## ガイドライン（L3）

効果的なセッション再開のための推奨事項。

- consider: コンテキストがコンパクションされた場合、コンパクション履歴を表示する
- prefer: ステータスが "blocked" の場合、ブロッカーを目立つように表示する
- consider: 複数のプロジェクトが存在する場合、ワークスペース切り替えを提案する
