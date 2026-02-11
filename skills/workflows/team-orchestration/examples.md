# team-orchestration Examples

spec-review --auto 実行時の4つのシナリオ。
リーダーの判断ポイントとユーザー通知テンプレートを含む。

## シナリオ 1: 正常系（Agent Team 利用可能 -- 3+2 ハイブリッド）

Agent Team が利用可能な環境で spec-review --auto を実行する標準フロー。
3体のチームメイト + 2体のサブエージェントによるハイブリッド構成。

### タイムラインフロー

```
[T+0s]  リーダー: TeamCreate ツールの利用可能性を確認
        判断: 利用可能 → チームモードで実行

[T+5s]  リーダー: ユーザーに通知
        "Agent Team モードで実行します。
         3名のレビュアーがチームとして相互検証を行います。"

[T+10s] リーダー: チームメイト3体をスポーン
        - security-auditor (reference.md のテンプレート使用)
        - qa-engineer (reference.md のテンプレート使用)
        - system-architect (reference.md のテンプレート使用)

[T+15s] リーダー: サブエージェント2体を並列起動 (Task tool)
        - product-manager
        - verification-specialist

[T+20s] リーダー: チームメイトにタスクを割り当て (TaskCreate)
        - 各チームメイトにレビュー対象スペックを指定
        - claude-progress.json に team-review-start を記録

[T+30s] チームメイト: レビュー作業を並列実行
        - security-auditor: OWASP Top 10 観点で分析
        - qa-engineer: テストカバレッジギャップを特定
        - system-architect: アーキテクチャ整合性を検証

[T+60s] チームメイト間の相互検証 (SendMessage)
        - security-auditor → qa-engineer: "SQL インジェクションリスクあり、テスト必要"
        - qa-engineer → security-auditor: "当該箇所のテストケースを評価済み"
        - system-architect → security-auditor: "提案された修正はアーキテクチャと整合"

[T+90s] チームメイト: Completion Protocol を実行
        - INSIGHT マーカーの記録
        - file:line 参照の検証
        - subagent-contract フォーマットで結果を SendMessage

[T+95s] リーダー: チームメイトの結果を受信
        - インサイトマーカーを抽出 → insights/pending/ に Write
        - claude-progress.json を更新

[T+100s] リーダー: サブエージェントの結果を受信
         - SubagentStop hooks が自動発火
         - verify_references.py が参照を検証
         - insight_capture.sh がインサイトを抽出

[T+110s] リーダー: 全結果を統合
         - 5体分のレビュー結果を subagent-contract フォーマットで統合
         - 重複する発見事項をマージ
         - Confidence スコアの重み付け集計

[T+120s] リーダー: ユーザーに統合結果を提示
         - claude-progress.json に team-review-complete を記録
         - チームのシャットダウン
```

### リーダー判断ポイント

| タイミング | 判断内容 | 判断基準 |
|-----------|---------|---------|
| T+0s | チームモード vs サブエージェントモード | TeamCreate の利用可能性 |
| T+90s | verification-specialist 追加起動 | Confidence >= 85 かつ参照検証が必要 |
| T+110s | 結果統合の十分性 | 全5体から結果を受信済みか |

## シナリオ 2: フォールバック系（Agent Team 利用不可 -- 5並列サブエージェント）

Agent Team ツールが利用できない環境でのフォールバック実行。
既存の5並列 Task tool パスと同一。

### タイムラインフロー

```
[T+0s]  リーダー: TeamCreate ツールの利用可能性を確認
        判断: 利用不可 → フォールバック通知

[T+5s]  リーダー: ユーザーに通知
        "Agent Team ツールは現在の環境で利用できません。
         既存のサブエージェント並列実行モードで続行します。

         機能的な差異:
         - レビュアー間の相互議論は行われません
         - 各レビュアーは独立して結果を返します
         - 品質・精度に大きな差はありません"

[T+10s] リーダー: 5体のサブエージェントを並列起動 (Task tool)
        - security-auditor
        - qa-engineer
        - system-architect
        - product-manager
        - verification-specialist

[T+15s] サブエージェント: 独立してレビュー作業を実行
        (エージェント間の直接通信なし)

[T+90s] リーダー: SubagentStop hooks が順次発火
        - verify_references.py が各サブエージェントの参照を検証
        - insight_capture.sh がインサイトを抽出

[T+100s] リーダー: 全結果を統合
         - 5体分のレビュー結果をオーケストレーターが統合
         - claude-progress.json を更新

[T+110s] リーダー: ユーザーに統合結果を提示
```

### リーダー判断ポイント

| タイミング | 判断内容 | 判断基準 |
|-----------|---------|---------|
| T+0s | フォールバック実行の決定 | TeamCreate 利用不可 |
| T+5s | ユーザー通知の発行 | L1: 通知を省略しない |
| T+100s | 結果統合の十分性 | 全5体から結果を受信済みか |

## シナリオ 3: 部分障害系（3段階判断サーキットブレイカー）

チームモード実行中に1体のチームメイトがハングした場合、
3段階判断（TeammateIdle + 中間報告 + 固定タイムアウト）でサーキットブレイカーが発動する。

### タイムラインフロー

```
[T+0s]   リーダー: チームモードで実行開始（シナリオ 1 と同様）

[T+15s]  チームメイト: 中間報告を送信
         - security-auditor → リーダー: "作業開始、OWASP A01から分析中"
         - qa-engineer: (中間報告なし) ← ハング発生
         - system-architect → リーダー: "作業開始、アーキテクチャ整合性チェック中"

[T+60s]  TeammateIdle: qa-engineer のアイドルイベント受信
         リーダー: 3段階判断の一次判断を実行
         - qa-engineer から中間報告を受信していない → ハング判定
         判断: 個別サーキットブレイカー発動
         1. qa-engineer に shutdown_request を送信
         2. 代替 qa-engineer をサブエージェント（Task tool）で即座にスポーン

[T+65s]  リーダー: ユーザーに通知
         "qa-engineer をサブエージェントに切り替えました。レビューを継続します。"

[T+70s]  代替 qa-engineer (サブエージェント): レビュー作業を開始
         (チームメイトではないため SendMessage 不可、独立して作業)
         残2体（security-auditor, system-architect）のチームはそのまま継続
         → 2体でも相互検証は成立する

[T+90s]  TeammateIdle: security-auditor のアイドルイベント受信
         リーダー: 3段階判断の一次判断を実行
         - security-auditor から中間報告あり → 正常作業中と判断、待機継続

[T+280s] リーダー: 全結果を統合
         - security-auditor (チームメイト) の結果
         - system-architect (チームメイト) の結果
         - qa-engineer (代替サブエージェント) の結果
         - product-manager (サブエージェント) の結果
         - verification-specialist (サブエージェント) の結果
         判断: 5体分の結果が揃った（代替含む）

[T+290s] リーダー: ユーザーに統合結果を提示
         - qa-engineer の結果は代替実行であることを注記
         - 相互検証は security-auditor <-> system-architect 間のみ実施済みと明記
```

### フォールバックタイムアウト（TeammateIdle 未受信の場合）

```
TeammateIdle イベントが来ない異常ケースでは固定タイムアウトで強制判断:
- security-auditor: 7分（OWASP全項目横断+相互検証、実作業中央値6分+バッファ）
- qa-engineer: 5分
- system-architect: 5分
- 上限キャップ: 全ロール共通10分
```

### リーダー判断ポイント

| タイミング | 判断内容 | 判断基準 |
|-----------|---------|---------|
| TeammateIdle受信時 | 一次判断: 中間報告の有無 | 中間報告なし=ハング、あり=待機継続 |
| 7分/5分経過 | 二次判断: フォールバック | TeammateIdle未受信での強制タイムアウト |
| T+280s | 結果統合の十分性 | 5体分（代替含む）の結果が揃ったか |

### ユーザー通知テンプレート

```
[role] をサブエージェントに切り替えました。レビューを継続します。

注記: [role] の結果はサブエージェント実行のため、
他チームメイトとの相互検証は行われていません。
```

### 補足: 2体障害時（チームサーキットブレイカー）

上記シナリオで、さらに system-architect もハングと判定された場合:
- 2体以上の障害 → チームモード全体をブレイク
- 残存 security-auditor にも shutdown_request → 全5体をサブエージェントで再起動
- 以降はシナリオ 4 と同一のフローに移行

## シナリオ 4: 完全障害系（全チームメイト失敗 -- サブエージェントで再起動）

全チームメイトが失敗し、サブエージェントモードに完全フォールバックする場合。

### タイムラインフロー

```
[T+0s]   リーダー: チームモードで実行開始

[T+10s]  リーダー: チームメイト3体をスポーン + サブエージェント2体を起動

[T+30s]  障害発生: TeamCreate/SendMessage がエラーを返す
         または全チームメイトが応答しない

[T+35s]  リーダー: エラー内容をログに記録
         - claude-progress.json に記録:
           action: "team-fallback-full"
           details: "全チームメイト失敗、サブエージェントモードに切り替え"

[T+40s]  リーダー: ユーザーに通知
         "チームモードからサブエージェントモードに切り替えました。

          理由: Agent Team の全チームメイトが応答に失敗
          対応: 5体全てをサブエージェント（Task tool）で再起動します。
          影響: エージェント間の相互議論は行われませんが、
                レビュー品質に大きな差はありません。"

[T+45s]  リーダー: 5体のサブエージェントを並列起動 (Task tool)
         - security-auditor (サブエージェントとして再起動)
         - qa-engineer (サブエージェントとして再起動)
         - system-architect (サブエージェントとして再起動)
         - product-manager (既にサブエージェントとして実行中なら結果を再利用)
         - verification-specialist (既にサブエージェントとして実行中なら結果を再利用)
         判断: 既に結果を持つサブエージェントは再起動しない

[T+50s]  サブエージェント: 独立してレビュー作業を実行
         (以降はシナリオ 2 のフォールバック系と同一のフロー)

[T+150s] リーダー: 全結果を統合
         - SubagentStop hooks が自動発火
         - claude-progress.json を更新

[T+160s] リーダー: ユーザーに統合結果を提示
```

### リーダー判断ポイント

| タイミング | 判断内容 | 判断基準 |
|-----------|---------|---------|
| T+30s | 完全フォールバックの決定 | 全チームメイトの失敗または API エラー |
| T+45s | サブエージェントの再利用 | product-manager/verification-specialist が既に結果を返しているか |
| T+150s | 結果統合の十分性 | 全5体から結果を受信済みか |

### ユーザー通知テンプレート

```
チームモードからサブエージェントモードに切り替えました。

理由: [エラー内容の要約]
対応: 5体全てをサブエージェント（Task tool）で再起動します。
影響: エージェント間の相互議論は行われませんが、
      レビュー品質に大きな差はありません。
```

## シナリオ間の比較

| 項目 | 正常系 | フォールバック系 | 部分障害系 | 完全障害系 |
|-----|--------|---------------|-----------|-----------|
| 起動方式 | 3チーム+2サブ | 5サブ | 3チーム+2サブ | 3チーム+2サブ→5サブ |
| 相互検証 | あり | なし | 部分的 | なし |
| 障害検知 | - | - | 3段階判断 | TeammateIdle/固定7-5分 |
| インサイト抽出 | Primary層 | SubagentStop | 混合 | SubagentStop |
| 参照検証 | verification-specialist | SubagentStop hooks | 混合 | SubagentStop hooks |
| ユーザー通知 | チームモード開始 | フォールバック通知 | 部分障害通知 | 完全切替通知 |
| ログアクション | team-review-start | (既存ログ) | team-finding | team-fallback-full |
