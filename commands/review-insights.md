---
description: "開発中にキャプチャされたインサイトをレビュー・承認する - インタラクティブに一つずつ処理"
argument-hint: "[workspace-id | list]"
allowed-tools: Read, Write, Edit, AskUserQuestion, Bash, Glob, Task
---

# /review-insights - インサイトレビューワークフロー

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

開発中にキャプチャされたインサイトをレビューし、適用先を決定する。各インサイトはユーザー確認付きで一つずつインタラクティブに処理される。

## アーキテクチャ（フォルダベース）

```
.claude/workspaces/{id}/insights/
├── pending/          # 新規インサイト（1インサイト1 JSON ファイル）
│   ├── INS-xxx.json
│   └── INS-yyy.json
├── applied/          # CLAUDE.md またはルールに適用済み
├── rejected/         # ユーザーが却下
└── archive/          # 参照用の古いインサイト
```

**メリット:**
- ファイルロック不要（各インサイトが個別ファイル）
- コンフリクトなしの並行キャプチャとレビュー
- 簡単なクリーンアップ（ファイルの移動/削除のみ）
- 部分的な障害への耐性

---

## 使用タイミング

- キャプチャされたインサイトのある開発セッション完了後
- SessionStart が保留中のインサイトを通知した場合
- 蓄積された知見を定期的にレビューする場合
- 類似の作業を開始する前に学びを統合する場合

## 入力形式

```bash
# 現在のワークスペースのインサイトをレビュー
/review-insights

# 特定のワークスペースをレビュー
/review-insights feature-auth_a1b2c3d4

# 保留中のインサイトがあるすべてのワークスペースを一覧表示
/review-insights list
```

---

## 実行手順

### フェーズ 1: 保留中インサイトの読み込み

**目的:** ワークスペースを特定し、フォルダから保留中のインサイトを読み込む。

**引数が "list" の場合:**

ワークスペースディレクトリを列挙し、保留中のインサイト数をカウントする:

```bash
# 保留中の件数を含むすべてのワークスペースを一覧表示
for dir in .claude/workspaces/*/insights/pending; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -name "*.json" -type f | wc -l)
        if [ "$count" -gt 0 ]; then
            workspace=$(basename "$(dirname "$(dirname "$dir")")")
            echo "$workspace: $count pending"
        fi
    fi
done
```

サマリーを表示して終了する。

**引数がワークスペース ID の場合:**

**重要: 使用前にワークスペース ID を検証すること:**
- パターン `^[a-zA-Z0-9._-]+$` に一致すること
- `..`（パストラバーサル）を含まないこと
- 検証に失敗した場合、エラーを表示して終了する

検証後、指定されたワークスペースを使用する。

**引数なしの場合:**

`workspace_utils.sh` と同じロジックで現在のワークスペース ID を決定する:
1. git ブランチを取得: `git branch --show-current`（サニタイズ: `/` とスペースを `-` に置換、`a-zA-Z0-9._-` のみ保持）
2. パスハッシュを取得: 現在のディレクトリの MD5 ハッシュの先頭8文字
3. 結合: `{branch}_{hash}`

**保留中のインサイトを読み込む:**

```bash
PENDING_DIR=".claude/workspaces/${WORKSPACE_ID}/insights/pending"
```

Glob または find を使用して pending ディレクトリ内のすべての `.json` ファイルを一覧表示する。
各ファイルを読み取り、インサイトオブジェクトを収集する。

**保留中のインサイトがない場合:**

```
ワークスペース {workspace-id} に保留中のインサイトはありません。

/review-insights list を実行して、保留中のインサイトがあるすべてのワークスペースを確認できます。
```

終了する。

### フェーズ 2: インタラクティブレビューループ

**目的:** 各インサイトをユーザーの判断で一つずつ処理する。

**保留中の各インサイトファイル（一つずつ処理）:**

**インサイトファイルの読み取り:**

```bash
INSIGHT_FILE=".claude/workspaces/${WORKSPACE_ID}/insights/pending/INS-xxx.json"
```

**インサイトの表示:**

```markdown
---
## インサイトレビュー ({current}/{total})

**ID**: {insight.id}
**キャプチャ日時**: {insight.timestamp}
**ソース**: {insight.source}
**カテゴリ**: {insight.category}

### 内容
{insight.content}

---
```

**判断を確認する:**

```
Question: "このインサイトをどうしますか？"
Header: "アクション"
Options:
- "承認: CLAUDE.md に追加（プロジェクト全体のルール）"
- "承認: .claude/rules/ に追加（カテゴリ別）"（推奨）
- "承認: ワークスペースのみに保持（このワークスペース用）"
- "今はスキップ（後でレビュー）"
- "却下（不要）"
```

**「承認: CLAUDE.md に追加」の場合:**

```
Question: "ルールレベルはどうしますか？"
Header: "レベル"
Options:
- "L1（ハードルール）- セキュリティ/安全性に重要、NEVER/ALWAYS を使用"
- "L2（ソフトルール）- 例外ありのベストプラクティス、should/by default を使用"（推奨）
- "L3（ガイドライン）- 提案、consider/prefer を使用"
```

次に確認する:

```
Question: "CLAUDE.md のどのセクションに追加しますか？"
Header: "セクション"
Options:
- "Development Rules"
- "Content Guidelines"
- "その他（フォローアップで指定）"
```

**「承認: .claude/rules/ に追加」の場合:**

```
Question: "どのカテゴリですか？"
Header: "カテゴリ"
Options:
- "hooks - フック開発パターン"
- "agents - エージェント設計パターン"
- "skills - スキル開発パターン"
- "workflows - ワークフロー改善"
```

**「承認: ワークスペースのみに保持」の場合:**

ファイルを `pending/` から `applied/` に移動する:
```bash
mv ".claude/workspaces/${WORKSPACE_ID}/insights/pending/INS-xxx.json" \
   ".claude/workspaces/${WORKSPACE_ID}/insights/applied/"
```

**「今はスキップ」の場合:**

ファイルを `pending/` に残し、次に進む。

**「却下」の場合:**

ファイルを `pending/` から `rejected/` に移動する:
```bash
mv ".claude/workspaces/${WORKSPACE_ID}/insights/pending/INS-xxx.json" \
   ".claude/workspaces/${WORKSPACE_ID}/insights/rejected/"
```

### フェーズ 3: 承認済みインサイトの適用

**目的:** 承認されたインサイトを適用先に書き込む。

**変更の複雑さに応じて実行方法を選択する:**

#### オプション A: 直接編集（単純な一行追加の場合）

簡単なインサイト追加（単一ルール、明確なセクション）の場合:

**CLAUDE.md への追加:**
1. 現在の CLAUDE.md を読み取る
2. 適切なセクションを見つける
3. L1/L2/L3 スタイルに従ってインサイトをフォーマットする:
   - L1: `- NEVER: X をする` または `- ALWAYS: Y をする`
   - L2: `- X は Y すべき` または `- デフォルトで Z する`
   - L3: `- X を検討する` または `- Z の場合は Y を優先する`
4. Edit ツールでセクションに追加する
5. インサイトファイルを `applied/` に移動する

**.claude/rules/ への追加:**
1. `.claude/rules/{category}.md` が存在するか確認する
2. 存在しない場合、Write ツールでヘッダー付きで作成する
3. Edit ツールでフォーマットされたインサイトを追加する
4. インサイトファイルを `applied/` に移動する

#### オプション B: technical-writer に委任（複雑な追加の場合）

フォーマットの判断が必要なインサイトや複数の追加の場合:

```
technical-writer エージェントを起動:
タスク: 承認済みインサイトをドキュメントに追加
インサイト内容: [ユーザーが承認した内容]
適用先: [CLAUDE.md または .claude/rules/{category}.md]
ルールレベル: [L1/L2/L3]
セクション: [対象セクション]
出力: 変更前後の diff を含む確認
```

**オプション B を使用する場合:**
- インサイトの内容に大幅なフォーマット変更が必要
- 関連する複数のインサイトをまとめて追加
- 適切なセクションが不明確
- CLAUDE.md が大きい（300行超）でナビゲーションが複雑

**ワークスペースのみの場合:**

フェーズ 2 で既にファイルが `applied/` に移動済み。

### フェーズ 4: サマリーレポート

**目的:** 実行した内容を表示する。

```markdown
## インサイトレビューサマリー

### ワークスペース: {workspace-id}

| # | インサイト | 判断 | 適用先 |
|---|-----------|------|--------|
| 1 | [先頭50文字...] | 承認 | CLAUDE.md (L2) |
| 2 | [先頭50文字...] | 承認 | .claude/rules/hooks.md |
| 3 | [先頭50文字...] | ワークスペース | applied/ |
| 4 | [先頭50文字...] | スキップ | pending/ |
| 5 | [先頭50文字...] | 却下 | rejected/ |

### 統計

- **レビュー総数**: 5
- **CLAUDE.md に追加**: 1
- **.claude/rules/ に追加**: 1
- **ワークスペースに保持**: 1
- **スキップ**: 1
- **却下**: 1

### 修正されたファイル

- `CLAUDE.md` - 1ルール追加
- `.claude/rules/hooks.md` - 1インサイト追加

### 残り

- **このワークスペースの保留中**: 1（スキップ）
- **スキップした項目を処理するには `/review-insights` を再実行してください**
```

---

## インサイトファイル形式

各インサイトは個別の JSON ファイル:

```json
{
  "id": "INS-20250121143000-a1b2c3d4",
  "timestamp": "2025-01-21T14:30:00Z",
  "category": "pattern",
  "content": "エラーハンドリングはエラーコード付きの AppError クラスを使用",
  "source": "code-explorer",
  "status": "pending",
  "contentHash": "a1b2c3d4e5f6g7h8",
  "workspaceId": "main_a1b2c3d4"
}
```

---

## インサイトマーカー（参考）

サブエージェントが以下のマーカーを出力するとインサイトがキャプチャされる:

| マーカー | 用途 |
|----------|------|
| `INSIGHT:` | 一般的な学びや発見 |
| `LEARNED:` | 経験から学んだこと |
| `DECISION:` | 行われた重要な判断 |
| `PATTERN:` | 発見された再利用可能なパターン |
| `ANTIPATTERN:` | 避けるべきパターン |

例:
```
INSIGHT: PreToolUse hooks で exit 1 はノンブロッキング - ブロッキングには JSON decision control + exit 0 を使用する
```

---

## ルール（L1 - ハード）

- MUST: 使用前にワークスペース ID を検証する（`^[a-zA-Z0-9._-]+$` に一致、`..` を含まないこと）
- NEVER: ユーザー提供のワークスペース ID を検証なしに処理する（パストラバーサル攻撃を防止）
- MUST: インサイトはユーザー確認付きで一つずつ処理する
- NEVER: ユーザーの判断なしに自動承認やバッチ承認をする
- NEVER: ユーザーに変更を表示せずに CLAUDE.md を修正する
- MUST: 元のインサイト内容を保持する（ユーザーが適用先テキストを編集可能）
- MUST: 各インサイトの判断（承認/スキップ/却下）には AskUserQuestion を使用する

## デフォルト（L2 - ソフト）

- デフォルトの推奨は ".claude/rules/"（CLAUDE.md の肥大化を防止）
- ほとんどのインサイトのデフォルトルールレベルは L2（ソフトルール）
- インサイトは時系列順（古い順）に処理する
- インサイトのソース（どのエージェントがキャプチャしたか）を表示する

## ガイドライン（L3）

- consider: インサイトの内容キーワードに基づくカテゴリ提案を行う
- consider: CLAUDE.md が大きくなりすぎている場合（500行超）に警告する
- consider: ユーザーがバッチレビューを好む場合、関連インサイトのグループ化を行う
- recommend: L1 はセキュリティ/安全性/データ整合性のルールにのみ使用する
