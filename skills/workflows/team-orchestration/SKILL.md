---
name: team-orchestration
description: |
  Agent Team を活用した並列レビュー・実装の協調プロトコル。
  チーム作成、フォールバック検出、スポーンプロンプト、
  インサイトキャプチャ、Progress file 管理を定義する。

  Use when:
  - spec-review --auto のチームモード実行時
  - 複数エージェントの並列レビューでチーム協調が必要な時

  Trigger phrases: agent team, team mode, parallel review team
allowed-tools: Read, Write, Glob, Grep, Task, TaskCreate, TaskUpdate, TaskList, TaskGet, SendMessage, TeamCreate, AskUserQuestion
model: sonnet
user-invocable: false
---

# Team Orchestration Protocol

Agent Team を活用した並列レビュー・実装の協調プロトコル。
既存の Task tool サブエージェントパターンを基盤とし、Agent Team を enhancement として活用する。

## 1. Agent Team 検出とフォールバック

### 検出手順

```
1. TeamCreate ツールの利用可能性を確認
2. 利用可能 → Agent Team パスで実行
3. 利用不可 → Task tool による並列サブエージェント実行にフォールバック
```

### フォールバック通知テンプレート

Agent Team が利用できない場合、ユーザーに以下を通知:

```
Agent Team ツールは現在の環境で利用できません。
既存のサブエージェント並列実行モードで続行します。

機能的な差異:
- レビュアー間の相互議論は行われません
- 各レビュアーは独立して結果を返します
- 品質・精度に大きな差はありません
```

Agent Team が利用可能な場合:

```
Agent Team モードで実行します。
3名のレビュアーがチームとして相互検証を行います。
```

## 2. スポーンプロンプトテンプレート

Phase 1 対象: spec-review --auto の3ロール。

### 共通 Completion Protocol (L1 - MUST)

全チームメイトのスポーンプロンプトに以下を含める:

```
## Completion Protocol (L1 - MUST)

リーダーへの報告（SendMessage）前に必ず実行すること:

1. INSIGHT RECORDING: 予期しない発見があれば以下のマーカーを使用:
   - PATTERN: [説明] (file:line)
   - LEARNED: [説明] (file:line)
   - INSIGHT: [説明] (file:line)

2. REFERENCE VERIFICATION: 全ての file:line 参照を Read ツールで
   存在確認すること。未検証の参照には [UNVERIFIED] を付与。

3. RESULT FORMAT: subagent-contract フォーマットで報告:
   ## [ロール名] Result
   ### Status: SUCCESS / PARTIAL / FAILED
   ### Summary: [2-3文の要約]
   ### Findings: [構造化された発見事項]
   ### Key References: [file:line テーブル]
   ### Confidence: [0-100] with justification
```

### security-auditor（概要）

- ツール制限 (L1): Write/Edit 禁止、Bash は読み取り専用監査コマンドのみ
- 分析対象: OWASP Top 10、認証/認可、入力バリデーション、データ露出
- チーム連携: qa-engineer とテスト可能性を相互確認、重大脆弱性はリーダーに即報告
- 完全なスポーンプロンプトは reference.md を参照

### qa-engineer（概要）

- ツール制限 (L1): 全標準ツール利用可能（Write/Edit/Bash 含む）
- 分析対象: テストカバレッジギャップ、エッジケース、受入基準の検証可能性
- チーム連携: security-auditor の指摘のテスト可能性評価、品質ゲートをリーダーに報告
- 完全なスポーンプロンプトは reference.md を参照

### system-architect（概要）

- ツール制限 (L1): Write/Edit/Bash 全て禁止、Read/Glob/Grep のみ
- 分析対象: アーキテクチャ整合性、スケーラビリティ、技術的負債の影響
- チーム連携: security-auditor の提案の技術的妥当性検証、実現可能性の懸念をリーダーに報告
- 完全なスポーンプロンプトは reference.md を参照

## 3. インサイトキャプチャプロトコル（リーダー側）

チームメイトの SendMessage からインサイトマーカーを抽出し保存する。

### 抽出手順

```
1. チームメイトの SendMessage を受信
2. PATTERN/LEARNED/INSIGHT/DECISION/ANTIPATTERN マーカーを検索
3. 各マーカーに対して:
   a. 一意の insight ID を生成 (INS-YYYYMMDDHHMMSS-xxxxxxxx)
   b. .claude/workspaces/{id}/insights/pending/ に JSON を書き出し:
      {
        "id": "INS-20260211-001",
        "timestamp": "ISO-8601",
        "category": "pattern|learned|insight|decision|antipattern",
        "content": "[マーカーの内容]",
        "source": "team-member-[role]",
        "status": "pending",
        "workspaceId": "[workspace-id]"
      }
   c. Write ツールで直接書き出す（Bash でスクリプト呼び出しはしない）
```

### 検証の連携

confidence >= 85 かつ参照の相互検証が必要な場合:
- verification-specialist をサブエージェント（Task tool）として起動
- SubagentStop hooks が自動発火し verify_references.py が参照を検証

## 4. Progress File Single Writer プロトコル

### フロー

```
チームメイト          リーダー              ファイルシステム
     |                   |                       |
     |-- SendMessage --->|                       |
     |  "タスク開始"      |-- Write ------------>|
     |                   |  claude-progress.json  |
     |-- SendMessage --->|                       |
     |  "発見事項報告"    |-- Write ------------>|
     |                   |  insights/pending/     |
     |                   |-- Write ------------>|
     |                   |  claude-progress.json  |
```

### teamContext フィールド（informational only）

claude-progress.json に追加するオプショナルフィールド:

```json
{
  "teamContext": {
    "mode": "agent-team",
    "startedAt": "ISO-8601"
  }
}
```

- オプショナル: 非チームセッションでは省略
- informational only: resume や recovery には使用しない
- 既存フィールド (currentPhase, currentTask, log) はリーダーが従来通り更新

### チーム内タスク管理との分離

| 管理対象 | ツール | 永続性 |
|---------|--------|--------|
| チーム内タスク | TaskCreate/Update/List | チーム存続期間のみ |
| セッション横断進捗 | claude-progress.json | プロジェクト全体 |
| 実装タスクリスト | feature-list.json | spec-implement 全期間 |

## 5. AskUserQuestion 中継フロー

### ユーザー対話プロトコル (L1)

チームメイトはユーザーと直接対話できない。以下のフローで中継する:

```
チームメイト: SendMessage → リーダー
  "ユーザーに確認が必要: [質問内容]"

リーダー: AskUserQuestion → ユーザー
  "[チームメイト名]からの確認事項: [質問内容]"

ユーザー: 回答

リーダー: SendMessage → チームメイト
  "ユーザーからの回答: [回答内容]"
```

## 6. サーキットブレイカー（3段階判断モデル）

チームメイト障害時の判断を TeammateIdle イベント中心で行い、LLM の時間認識への依存を最小化する。

```
個別障害（1体無応答）- 3段階判断:
  一次: TeammateIdle イベント受信を契機にタイムアウト判断
    - 中間報告（SendMessage）受信済み → 正常完了の可能性あり、結果待機を継続
    - 中間報告なし → ハングと判断、同ロールのサブエージェントを代替スポーン
  二次: フォールバック固定タイムアウト（TeammateIdle 未受信の異常系）
    - security-auditor: 7分、qa-engineer: 5分、system-architect: 5分
    - 上限キャップ: 全ロール共通10分
  → 元チームメイトに shutdown_request
  → 残2体のチームはそのまま継続（2体でも相互検証は成立）

チーム障害（2体以上無応答）:
  → 全チームメイトに shutdown_request
  → 従来パターン（5体サブエージェント）にフォールバック
  → ログに team-fallback-full を記録
  ※ 1体のみ残存ではチーム協調の価値がないため全体ブレイク

API エラー（TeamCreate/SendMessage 失敗）:
  → 即時ブレイク → 従来パターンで実行
  → 同一セッション内はチームモードを再試行しない（open 状態維持）
```

### 3段階判断の根拠

- **一次（TeammateIdle）**: ツール呼び出し有無をシステムレベルで検知する正確なシグナル。LLMの時間認識に依存しない
- **二次（固定タイムアウト）**: TeammateIdle が来ない異常ケースのフォールバック。security-auditor は OWASP 全項目横断+相互検証で実作業中央値6分のため7分、qa-engineer/system-architect はフロア値3分の約1.7倍で5分
- **中間報告義務**: チームメイトのスポーンプロンプトに中間報告（作業開始+主要発見）の送信を義務付け、リーダーの判断精度を向上

## Rules (L1 - Hard)

Agent Team 運用の安全性と一貫性のために必須。

- MUST: TeamCreate 前に利用可能性を確認し、利用不可なら Task tool にフォールバック
- MUST: リーダーのみが claude-progress.json / feature-list.json に書き込む
- MUST: チームメイトはユーザーとの対話を SendMessage 経由でリーダーに中継
- MUST: 全チームメイトに Completion Protocol を含むスポーンプロンプトを使用
- MUST: チームメイト無応答時は3段階判断（TeammateIdle+中間報告→固定タイムアウト security-auditor: 7分/他: 5分→上限10分）で代替サブエージェントをスポーン
- NEVER: チームメイトが直接 AskUserQuestion を呼び出す
- NEVER: チームメイトが progress/feature ファイルに直接書き込む
- NEVER: リーダーがコード実装・テスト・セキュリティ分析を自分で行う（既存 orchestrator ルール）
- ALWAYS: Agent Team 利用不可時もユーザーへの通知を省略しない

## Defaults (L2 - Soft)

品質向上のための推奨事項。合理的な理由があれば変更可。

- チームメイト間の相互検証を促進する（security-auditor と qa-engineer の発見を相互参照）
- インサイトマーカーの抽出はリーダーが Write ツールで直接行う
- チームメイト数は初期段階では最大3名に制限
- verification-specialist は SubagentStop hooks 活用のため Task tool で起動

## Guidelines (L3)

状況に応じて判断する推奨事項。

- prefer: 長時間実行のチームメイトよりも短期タスク型を推奨（Context Rot 防止）
- consider: チームメイト間の議論が発生しない場合は Task tool フォールバックを検討
- consider: TeammateIdle hook が正常動作する場合は Layer 2 自動化として活用
