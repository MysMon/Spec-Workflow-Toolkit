# 進捗トラッキングシステム

複数セッションやコンテキストウィンドウにまたがる可能性のある自律的なロングランニングタスクのための JSON ベース進捗トラッキング。

Anthropic の「ロングランニングエージェントのための効果的なハーネス」パターンに基づく。

## マルチプロジェクト分離

Claude Code の公式 git worktree 推奨に基づき、このシステムは各ワークスペースを分離し、複数のプロジェクトやセッションを同時実行する際の競合を防止する。

### ワークスペース構造

```
.claude/
└── workspaces/
    └── {workspace-id}/           # 形式: {branch}_{path-hash}
        ├── claude-progress.json  # 再開コンテキスト付き進捗ログ
        ├── feature-list.json     # 機能/タスク追跡
        ├── session-state.json    # 現在のセッション状態（オプション）
        └── logs/
            ├── subagent_activity.log
            └── sessions/
                └── {session-id}.log
```

### ワークスペース ID の生成

ワークスペース ID は以下から生成:
- **ブランチ名**: 現在の git ブランチ（例: `main`、`feature-auth`）
- **パスハッシュ**: 作業ディレクトリパスの MD5 ハッシュ（8 文字）

ワークスペース ID の例:
- `main_a1b2c3d4` - ハッシュ a1b2c3d4 のディレクトリの main ブランチ
- `feature-auth_e5f6g7h8` - 別の worktree の feature/auth ブランチ

### この構造の理由

Claude Code Issue #1985（セッション分離）より:
> 「あるセッションのファイルパスが完全に別のセッションのコンテキストに出現した」

この構造により:
1. **Worktree 分離**: 異なる git worktree は異なるワークスペースを取得
2. **ブランチ分離**: 同じディレクトリ、異なるブランチ = 異なるワークスペース
3. **セッション追跡**: 各セッションが独自のログファイルを持つ
4. **再開機能**: ブランチ名による容易な特定

## 基本原則

**コンテキストウィンドウには制限がある。** 複雑なタスクは単一ウィンドウで完了できない。このシステムが提供するもの:

1. **claude-progress.json** - 構造化された進捗ログ
2. **feature-list.json** - ステータス付き機能/タスク追跡
3. **再開コンテキスト** - 新しいセッション用の明確な状態

## なぜ Markdown ではなく JSON か？

Anthropic のリサーチより: 「モデルは Markdown ファイルと比べて JSON ファイルを不適切に変更する可能性が低い。」

- JSON は厳密なスキーマを持つ - 誤って破損しにくい
- フィールドを独立して更新可能
- 自動化用に機械可読
- データとプレゼンテーションの明確な分離

## claude-progress.json スキーマ

```json
{
  "workspaceId": "main_a1b2c3d4",
  "project": "project-name",
  "started": "2025-01-16T10:00:00Z",
  "lastUpdated": "2025-01-16T14:30:00Z",
  "status": "in_progress",
  "currentTask": "Implementing user authentication",
  "sessions": [
    {
      "id": "20250116_100000_abc1",
      "started": "2025-01-16T10:00:00Z",
      "ended": "2025-01-16T12:00:00Z",
      "summary": "Set up project structure, created database schema",
      "filesModified": ["schema.prisma", "src/models/user.ts"],
      "nextSteps": ["Implement auth service", "Add JWT handling"]
    }
  ],
  "log": [
    {
      "timestamp": "2025-01-16T10:15:00Z",
      "action": "Created database schema",
      "details": "Added User, Session, and Token models",
      "files": ["prisma/schema.prisma"]
    }
  ],
  "resumptionContext": {
    "position": "Completed Phase 2 (Database), starting Phase 3 (Services)",
    "nextAction": "Create AuthService in src/services/auth.ts",
    "dependencies": ["Database migrations must be run first"],
    "blockers": []
  }
}
```

## feature-list.json スキーマ

```json
{
  "workspaceId": "main_a1b2c3d4",
  "project": "project-name",
  "totalFeatures": 10,
  "completed": 3,
  "features": [
    {
      "id": "F001",
      "name": "User registration",
      "description": "Users can create accounts with email/password",
      "status": "completed",
      "completedAt": "2025-01-16T11:30:00Z"
    },
    {
      "id": "F002",
      "name": "User login",
      "description": "Users can log in and receive JWT token",
      "status": "in_progress",
      "startedAt": "2025-01-16T12:00:00Z"
    },
    {
      "id": "F003",
      "name": "Password reset",
      "description": "Users can reset password via email",
      "status": "pending"
    }
  ]
}
```

## ワークフロー

### 新しいタスクの開始

1. **ワークスペース ID を決定**
   ```bash
   # フックにより自動生成:
   # {branch}_{path-hash} 例: main_a1b2c3d4
   ```

2. **進捗ファイルを初期化**
   ```
   .claude/workspaces/{workspace-id}/claude-progress.json を以下で作成:
   - ワークスペース ID
   - プロジェクト名
   - 開始タイムスタンプ
   - 初期ステータス
   - 最初のセッションエントリ
   ```

3. **機能リストを作成**（複数機能の場合）
   ```
   .claude/workspaces/{workspace-id}/feature-list.json を以下で作成:
   - 実装する全機能
   - 全て初期状態は "pending"
   ```

4. **TodoWrite を並行使用**
   ```
   TodoWrite でリアルタイム可視化
   JSON ファイルでセッション横断の永続化
   ```

### 作業中

1. **重要なアクション後に進捗ログを更新**
   ```json
   {
     "timestamp": "...",
     "action": "Implemented AuthService",
     "details": "Added login, logout, and token refresh methods",
     "files": ["src/services/auth.ts"]
   }
   ```

2. **機能完了時にステータスを更新**
   ```json
   {
     "status": "completed",
     "completedAt": "..."
   }
   ```

3. **再開コンテキストを最新に保つ**
   ```json
   {
     "position": "現在の位置",
     "nextAction": "次にやること",
     "dependencies": ["必要なもの"],
     "blockers": ["障害になっているもの"]
   }
   ```

### セッション終了時

1. **セッションサマリーを更新**
   ```json
   {
     "ended": "...",
     "summary": "達成したこと",
     "filesModified": [...],
     "nextSteps": [...]
   }
   ```

2. **再開コンテキストが完全であることを確認**
   - 位置が明確であること
   - 次のアクションが具体的であること
   - ブロッカーが文書化されていること

### 作業の再開

1. **利用可能なワークスペースを一覧**
   ```
   .claude/workspaces/ で利用可能なワークスペースを確認
   プロジェクト名とステータス付きでワークスペース ID を表示
   ```

2. **選択したワークスペースの進捗ファイルを読む**
   ```
   .claude/workspaces/{workspace-id}/claude-progress.json を読む
   .claude/workspaces/{workspace-id}/feature-list.json を読む（存在する場合）
   ```

3. **現在の状態を理解**
   - resumptionContext.position を確認
   - 最後のセッションサマリーをレビュー
   - ブロッカーを確認

4. **記録された地点から続行**
   - 新しいセッションエントリを開始
   - 再開コンテキストの nextAction に従う

## TodoWrite との統合

両方のシステムを併用:

| システム | 目的 | スコープ |
|---------|------|---------|
| TodoWrite | リアルタイム可視化 | 現在のセッション |
| JSON ファイル | 永続化 | セッション横断 |

```
フロー:
1. feature-list.json から TodoWrite にポピュレート
2. 作業に応じて TodoWrite の項目をマーク
3. マイルストーンで JSON ファイルを更新
4. 新しいセッションで JSON から TodoWrite に同期
```

## セッション開始プロトコル

開始または再開時:

```
1. 現在のワークスペース ID を取得（ブランチ + パスハッシュ）
2. .claude/workspaces/{workspace-id}/claude-progress.json が存在するか確認
3. 存在する場合:
   - resumptionContext を読む
   - 最後のセッションサマリーを読む
   - 報告: "再開位置: [position]"
   - 報告: "ワークスペース: [workspace-id]"
   - 報告: "次のアクション: [nextAction]"
4. 存在しない場合:
   - 新しい進捗トラッキングを初期化
   - 複数機能の場合は機能リストを作成
```

## PreCompact フック統合

このプラグインはコンテキストコンパクション前に自動的に状態を保存する `PreCompact` フックを含む。

### コンパクションプロセスフロー

1. コンテキストが上限に接近（約 50-70% フル）
2. **PreCompact フック** が発火 → ワークスペース進捗ファイルに状態を保存
3. システムがコンテキストをコンパクション（要約、詳細が失われる可能性）
4. エージェントが縮小されたコンテキストで続行 → **状態復元のために進捗ファイルを読む必要あり**

### コンパクション後のリカバリプロトコル

**コンパクション後は必ず:**

1. **進捗ファイルを読む**（コンテキストの復元）:
   ```
   .claude/workspaces/{workspace-id}/claude-progress.json を読む
   ```

2. **コンパクション履歴を確認**:
   ```json
   {
     "compactionHistory": [
       {
         "timestamp": "2025-01-16T14:30:00Z",
         "contextBeforeCompaction": "Phase 5 - Implementation"
       }
     ]
   }
   ```

3. **記録された位置から再開**:
   - `resumptionContext.position` を確認
   - `resumptionContext.nextAction` に従う
   - `blockers` に注意

4. **必要に応じて主要ファイルを再読み込み**:
   - 重要な参照は `resumptionContext.keyFiles` を確認
   - `file:line` 形式で関連コードを素早く特定

### コンパクション安全な状態形式

進捗ファイルにリカバリに十分なコンテキストを含める:

```json
{
  "workspaceId": "main_a1b2c3d4",
  "resumptionContext": {
    "position": "Phase 5 - Implementation: AuthService login method",
    "nextAction": "Add token refresh logic to src/services/auth.ts:67",
    "keyFiles": [
      "src/services/auth.ts:45",
      "src/config/jwt.ts:12"
    ],
    "recentDecisions": [
      "Using JWT with 24h expiry",
      "Refresh tokens stored in Redis"
    ],
    "blockers": []
  },
  "compactionHistory": [
    {
      "timestamp": "2025-01-16T14:30:00Z",
      "positionAtCompaction": "Starting token refresh implementation"
    }
  ]
}
```

### なぜこれが重要か

コンパクション後に適切なリカバリがないと:
- エージェントが何をしたか見失う
- 作業を繰り返したりステップをスキップする可能性
- コンパクション前の決定が忘れられる
- 品質が著しく低下

適切なリカバリにより:
- エージェントが中断箇所から正確に再開
- 全ての決定が JSON に保持
- 主要ファイル参照で素早いコンテキストロードが可能
- コンパクション境界を越えてもスムーズに作業継続

## Context Editing（上級）

Claude Code には **Context Editing** が含まれている — トークン制限に近づいた時に古くなったツール呼び出しと結果を自動的に削除する機能。

Anthropic の Context Management アナウンスより:

> 「Context editing はトークン制限に近づいた時にコンテキストウィンドウ内の古くなったツール呼び出しと結果を自動的にクリアし...トークン消費を 84% 削減する。」

### Context Editing の仕組み

コンパクション（会話を要約する）とは異なり、context editing は以下を保持しながら完了したツールインタラクションを**外科的に除去**:
- 会話の流れ
- 重要な決定
- 現在のタスク状態

```
Context Editing 前:
[Turn 1: Read file A → Result: 500 lines]
[Turn 2: Read file B → Result: 800 lines]
[Turn 3: Edit file A → Success]
[Turn 4: Current task discussion]

Context Editing 後:
[Turn 1: Read file A → [removed - stale]]
[Turn 2: Read file B → [removed - stale]]
[Turn 3: Edit file A → [removed - completed]]
[Turn 4: Current task discussion]  ← 保持
```

### 進捗ファイル + Context Editing = 長時間セッション

進捗ファイルと context editing の組み合わせで長時間の自律作業が可能:

| 機能 | コンパクション | Context Editing |
|------|-------------|-----------------|
| **トリガー** | 手動または約 70% フル | 制限近くで自動 |
| **方法** | 会話を要約 | 古くなったツール呼び出しを除去 |
| **保持** | サマリーのみ | 会話 + 決定 |
| **リカバリ** | 進捗ファイルが必要 | 多くの場合セルフリカバリ |
| **トークン節約** | 約 60-70% | 最大 84% |

### ベストプラクティス: 両方を使用

1. **Context Editing** がルーティンのクリーンアップを自動処理
2. **進捗ファイル** が重大なコンテキスト喪失に対する保険を提供
3. **PreCompact フック** がコンパクション前に状態を保存

**推奨**: context editing があっても、以下のために進捗ファイルを維持:
- マルチセッション作業
- あらゆるコンテキスト喪失を生き残る必要がある複雑な決定
- 複数日にわたる作業

## ベストプラクティス

### すべきこと

- 各重要なアクション後に進捗を更新
- 再開コンテキストを具体的でアクション可能に保つ
- 複数の成果物があるタスクには feature-list.json を使用
- 永続化のために進捗ファイルを git にコミット
- ログエントリにファイルパスを含める
- 全進捗ファイルに workspaceId を含める

### すべきでないこと

- 更新をバッチ処理しない（失敗時に進捗を失うリスク）
- 曖昧な再開コンテキストを使わない（「作業を続行」）
- 完了時の機能ステータス更新を忘れない
- ブロッカーを文書化しないまま放置しない
- 異なるワークスペースの進捗を混在させない

## 例: データベースマイグレーション

```json
{
  "workspaceId": "feature-prisma_b2c3d4e5",
  "project": "sequelize-to-prisma-migration",
  "status": "in_progress",
  "currentTask": "Migrating Order model",
  "features": [
    {"id": "M001", "name": "User model", "status": "completed"},
    {"id": "M002", "name": "Product model", "status": "completed"},
    {"id": "M003", "name": "Order model", "status": "in_progress"},
    {"id": "M004", "name": "OrderItem model", "status": "pending"},
    {"id": "M005", "name": "Repository layer", "status": "pending"}
  ],
  "resumptionContext": {
    "position": "Order model migration - relations defined, testing CRUD",
    "nextAction": "Write integration tests for Order repository",
    "dependencies": ["User and Product models must pass tests"],
    "blockers": []
  }
}
```

## Rules (L1 - Hard)

セッション継続性とデータ整合性に不可欠。

- ALWAYS: セッション終了前に再開コンテキストを更新する（リカバリを可能にする）
- NEVER: nextAction を空または曖昧にしない（エージェントが再開できない）
- ALWAYS: 進捗ファイルに workspaceId を含める（分離）
- NEVER: 現在のワークスペース外の進捗ファイルに書き込まない（競合防止）
- ALWAYS: コンパクション直後に進捗ファイルを読む（決定コンテキストの復元）
- NEVER: コンパクション後に resumptionContext.position を確認せずに作業を続行しない

## Defaults (L2 - Soft)

効果的な進捗トラッキングに重要。適切な理由がある場合はオーバーライド可。

- 3 ステップを超えるタスクには進捗ファイルを作成
- 状態には JSON 形式を使用（Markdown ではなく）
- ログエントリにファイルパスを含める
- 再開時に TodoWrite を feature-list と同期

## Guidelines (L3)

より良い進捗管理のための推奨事項。

- consider: 永続化のために進捗ファイルを git にコミットすることを検討
- prefer: バッチでの大規模更新より頻繁な小規模更新を推奨
- consider: 継続性のために再開コンテキストに最近の決定を含めることを検討
