---
description: "弁証法的探索による構造化マルチエージェントディスカッションをトピックについて開始する"
argument-hint: "<トピック> [--quick|--deep] [--members ロール1,ロール2,ロール3] [--context ファイル1,ファイル2] [--timeout 分]"
allowed-tools: Read, Write, Glob, Grep, Bash, Task, AskUserQuestion, TeamCreate, TaskCreate, TaskUpdate, TaskList, TaskGet, SendMessage
---

# /discuss - マルチエージェント構造化ディスカッション

## Language Mode

すべての出力は日本語で行う。詳細は `language-enforcement` スキルを参照。

---

構造化された多角的探索（Position -> Challenge -> Synthesis）で
設計判断・技術選定・方針決定の合意形成を支援する。

結果は最終決定ではなく、ユーザーへの判断材料として提示する。

## オプション

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--quick` | 2ラウンド（Position + Synthesis） | - |
| `--deep` | 最大5ラウンド | - |
| `--members ロール1,ロール2,...` | カスタムロール指定 | トピックに応じて自動選出 |
| `--context ファイル1,ファイル2,...` | コンテキストファイルを指定 | なし |
| `--timeout N` | 全体タイムアウト（分） | 10 |

## 実行手順

### ステップ 1: トピック解析とロール選出

`$ARGUMENTS` からトピックとオプションを解析する。

**トピックが未指定の場合:**
- AskUserQuestion でトピックを確認

**ロール選出:**

`--members` が指定された場合はそのロールを使用。
未指定の場合、トピックの性質に応じて自動選出:

| トピックの性質 | 推奨ロール構成 |
|--------------|-------------|
| 技術選定 | パフォーマンス専門家、セキュリティ専門家、保守性専門家 |
| 設計判断 | UX専門家、アーキテクト、コスト分析家 |
| 方針決定 | ビジネス視点、技術視点、ユーザー視点 |
| その他 | トピックに最適な3つの対立的視点を選出 |

対立軸を含む構成を推奨（推進派 vs 慎重派、抽象 vs 具体 等）。

**コンテキスト読み込み:**

`--context` で指定されたファイルを Read で読み込み、各メンバーに配布する。
未指定でも関連ファイルの自動検出は行わない（明示的指定のみ）。

### ステップ 2: チーム作成とメンバースポーン

`discussion-protocol` スキルを読み込み、スポーンプロンプトテンプレートとラウンド管理の情報を取得する。

#### Agent Team モード（自動検出）

TeamCreate ツールが利用可能な場合:

**ステップ 2a: チーム作成**

TeamCreate で `discuss-{topic-slug}` チームを作成する。
TeamCreate が失敗またはツールが利用不可の場合、ステップ 2 フォールバックに移行。

**ステップ 2b: チームメイトスポーン（4体）**

以下の 4 体を Task tool で team_name を指定してスポーン。
各チームメイトのスポーンプロンプトは discussion-protocol skill の reference.md から取得:

```
1-3. 議論参加者 x3:
   subagent_type: general-purpose
   team_name: discuss-{topic-slug}
   mode: plan
   prompt: reference.md の汎用テンプレート
         + ロール名・専門領域の差し替え
         + トピック + コンテキスト

4. devils-advocate:
   subagent_type: general-purpose
   team_name: discuss-{topic-slug}
   mode: plan
   prompt: reference.md の devils-advocate テンプレート
         + トピック + コンテキスト
```

**ステップ 2c: ユーザー通知**

```
Agent Team モードでディスカッションを開始します。
トピック: {topic}
参加者: {role1}, {role2}, {role3}, devils-advocate + モデレーター（リーダー）
ラウンド: {preset_description}
```

#### ステップ 2 フォールバック（Task tool による並列実行）

Agent Team が利用不可の場合:

```
Agent Team ツールは現在の環境で利用できません。
サブエージェント（Task tool）モードでディスカッションを実行します。

機能的な差異:
- ラウンド間の動的な立場変更追跡は簡略化されます
- 各メンバーは独立して全ラウンドの立場を一括提出します
- 結果の多角性は同等です
```

4体のサブエージェントを並列起動（Task tool、チームなし）。
各サブエージェントに Position → Self-Challenge → Final Position を一括実行させる。

### ステップ 3: ラウンド管理（Agent Team モードのみ）

モデレーター（リーダー）が以下のラウンド制御を行う。

#### ラウンド 1 - Position（必須）

1. 全メンバーにラウンド 1 開始を通知（SendMessage）
2. L1: メンバー間の直接通信を禁止（独立提出）
3. 全 Position を受信するまで待機
4. 収束判定を実施

#### 収束判定後の分岐

| 収束状態 | `--quick` | デフォルト | `--deep` |
|---------|----------|----------|---------|
| DIVERGENT | → Synthesis | → Challenge | → Challenge |
| NARROWING | → Synthesis | → Challenge | → Challenge |
| CONVERGING | → Synthesis | → Synthesis（Challenge スキップ） | → Challenge |
| CONSENSUS | → 偽合意検出 | → 偽合意検出 | → Challenge（強制） |

#### ラウンド 2 - Challenge（条件付き）

1. 全メンバーの Position を配布（SendMessage、300語以内）
2. L1: 同意・賛同の表明を禁止することを通知
3. 全 Challenge を受信
4. 収束判定を実施

#### ラウンド 3 - Synthesis（条件付き）

モデレーター判定: 未解決の重要な対立があれば実施、なければスキップ。

1. 全メンバーの Challenge を配布
2. 立場修正 + 折衷案を要請
3. 全 Synthesis を受信
4. 収束判定を実施

#### 追加ラウンド（`--deep` のみ、最大5ラウンド）

DIVERGENT が続く場合、論点を絞って追加ラウンドを実施。

#### 最終立場回収

全ラウンド完了後:
1. 全メンバーに最終立場の報告を要請（500語以内、構造化フォーマット）
2. 全最終立場を受信

### ステップ 4: 結果統合

#### 統合レポート作成

discussion-protocol skill の reference.md「結果統合フォーマット」に従い統合レポートを作成:
- 合意マトリクス（論点別合意状態）
- モデレーター裁定（分裂論点への判断材料整理）
- 立場変遷（各メンバーの立場変化）
- 少数意見（棄却理由付き）
- devils-advocate 総括
- 次のアクション

#### 偽の合意検出（CONSENSUS 時）

1. 各メンバーの合意根拠を比較
2. 根拠が同質的 → 「表面的合意」と判定
3. devils-advocate に追加反論を要求
4. ユーザーに警告表示

#### チームクリーンアップ

1. 各チームメイトに shutdown_request を送信
2. TeamDelete でチームを削除

### ステップ 5: ユーザーへの結果提示とフィードバックループ

統合レポートをユーザーに提示し、フィードバックを受け付ける。

```
## ディスカッション結果: {topic}

[統合レポートの主要部分を表示]

### 次のステップ
このディスカッション結果をどうしますか？
```

AskUserQuestion で以下の選択肢を提示:

| 選択肢 | 説明 |
|-------|------|
| 結果を採用 | 結果ファイルを保存して終了 |
| 議論を深掘り | 特定の論点について追加ラウンドを実施 |
| 新しい視点を追加 | メンバーを追加して再議論 |
| spec-plan に反映 | 結果を spec-plan のコンテキストとして使用 |

#### 「結果を採用」の場合

結果ファイルを `docs/specs/{feature}-discussion-{topic-slug}.md` に保存。

#### 「議論を深掘り」の場合

AskUserQuestion でどの論点を深掘りするか確認し、
指定された論点について追加ラウンドを実施。

#### 「spec-plan に反映」の場合

結果ファイルを保存し、次のコマンドを提案:
```
/spec-plan {feature} --context docs/specs/{feature}-discussion-{topic-slug}.md
```

### ステップ 6: 結果保存

最終結果を以下に保存:
- 結果ファイル: `docs/specs/{feature}-discussion-{topic-slug}.md`

## サーキットブレイカー

discussion-protocol skill の定義に従う:
- 各ターンタイムアウト: 3分
- 全体タイムアウト: `--timeout` で指定（デフォルト10分）
- team-orchestration スキルの3段階判断モデルを踏襲

## 使用例

```bash
# 技術選定の議論
/discuss "認証方式の選定: JWT vs Session vs OAuth"

# 設計判断（コンテキスト付き）
/discuss "キャッシュ戦略" --context docs/specs/performance.md

# 軽量な意見収集
/discuss "API レスポンスフォーマット" --quick

# カスタムロール指定
/discuss "マイクロサービス vs モノリス" --members "スケーリング専門家,運用専門家,開発速度専門家"

# 深い議論（最大5ラウンド）
/discuss "データベース移行戦略" --deep --timeout 15
```

---

## ルール（L1 - ハード）

- MUST: 3名以上のディスカッションには必ず1名を devils-advocate として割り当てる
- MUST: Challenge Round では同意・賛同の表明を禁止する
- MUST: Position Round は他者の意見を見ずに独立して実行する
- MUST: モデレーター（リーダー）はプロセス介入のみ行い、内容に関する判断を表明しない
- MUST: 全メンバーの最終立場を構造化フォーマットで回収する
- MUST: CONSENSUS 到達時に同意バイアス検証を実施する
- MUST: 少数意見を結果に記録する（棄却理由も付記）
- MUST: Agent Team 利用不可時はフォールバック通知をユーザーに表示する
- NEVER: モデレーターが「A案が正しい」等の内容判断を表明する
- NEVER: チームメイトが直接 AskUserQuestion を呼び出す（リーダー経由で中継）

## デフォルト（L2 - ソフト）

- デフォルト3ラウンド（Position -> Challenge -> Synthesis）、適応型で2ラウンドに短縮可能
- チーム構成はデフォルト5名（3+1+1）
- 結果ファイルは `docs/specs/{feature}-discussion-{topic-slug}.md` に保存
- 全体タイムアウトは10分
- 5名以下はメッシュ型通信

## ガイドライン（L3）

- recommend: 対立軸を含むロール構成を推奨
- recommend: 結果は「合意事項」より「選択肢+トレードオフ+判断問い」として提示することを推奨
- consider: 短時間プロセスのため、中断時はやり直しで対応
- consider: 議論品質の指標として立場変遷（Position変更の有無）を確認
- consider: spec-plan Phase 4 との連携を検討
