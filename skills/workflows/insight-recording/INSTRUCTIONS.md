# インサイト記録プロトコル

自律的な作業中に開発インサイトを記録するための標準化プロトコル。マークされたインサイトは `insight_capture.sh` フック（SubagentStop 経由）により自動的にキャプチャされ、`/review-insights` でレビューできる。

## 仕組み

```
サブエージェント出力      transcript.jsonl      insight_capture.sh      /review-insights
      │                     │                       │                       │
      ├─ PATTERN: ... ─────►│                       │                       │
      ├─ LEARNED: ... ─────►├──────────────────────►├─► pending/INS-*.json ►│
      └─ その他のテキスト     │                       │                       ├─► CLAUDE.md
                            │  (コードブロックは      │  (アトミック書き込み、  ├─► .claude/rules/
                            │   フィルタ除外)         │   重複排除)            └─► ワークスペースのみ
```

フックはトランスクリプト JSONL ファイル（SubagentStop メタデータの `transcript_path` 経由）から読み取り、アシスタントメッセージを抽出し、コードブロックをフィルタリングし、インサイトマーカーを検索する。

## インサイトマーカー

以下のマーカーでインサイトを出力する（大文字小文字を区別しない）。マークされたコンテンツのみキャプチャされる。

| マーカー | 使用場面 | 例 |
|---------|---------|-----|
| `PATTERN:` | 再利用可能なパターンを発見した時 | `PATTERN: Repository pattern with Unit of Work at src/repositories/base.ts:15` |
| `ANTIPATTERN:` | 避けるべきアプローチを発見した時 | `ANTIPATTERN: Global state in config.js makes testing difficult` |
| `LEARNED:` | 予期しないことを学んだ時 | `LEARNED: The legacy auth module is deprecated but still used by admin` |
| `DECISION:` | 根拠を伴う重要な判断をした時 | `DECISION: Chose event-driven over direct calls due to async patterns` |
| `INSIGHT:` | 記録する価値のある一般的な観察 | `INSIGHT: Error handling uses custom AppError class consistently` |

## 複数行サポート

インサイトは複数行にわたることができる。コンテンツは次のマーカーまたはテキストの終わりまでキャプチャされる。

**1 行:**
```
PATTERN: Repository pattern at src/repositories/base.ts:15
```

**複数行（複雑なインサイトに推奨）:**
```
PATTERN: This codebase uses Repository pattern with Unit of Work for all
database operations. Each repository extends BaseRepository which handles
transactions - see src/repositories/base.ts:15

LEARNED: The user.status field uses magic numbers (1=active, 2=inactive) -
no documentation exists, discovered through characterization testing
```

**重要:** 複数行インサイトは次のマーカーで終了する。空行は可読性のために使用できるが、キャプチャには影響しない。

## 制約

| 制約 | 値 | 根拠 |
|------|-----|------|
| **最小長** | 11 文字 | ノイズやプレースホルダーマーカーをフィルタ |
| **最大長** | 10,000 文字 | ストレージの肥大化を防止。`... [truncated]` で切り詰め |
| **キャプチャあたり最大数** | 100 インサイト | DoS 防止のレート制限 |
| **コードブロックフィルタリング** | 有効 | \`\`\`...\`\`\` 内のマーカーは無視 |
| **インラインコードフィルタリング** | 有効 | \`...\` 内のマーカーは無視 |
| **重複排除** | コンテンツハッシュによる | 同一インサイトは一度だけキャプチャ |
| **アトミック書き込み** | temp + fsync + rename | 部分的な書き込みや破損を防止 |

## コードブロックの扱い

**コードブロック内のマーカーは無視される**（誤検出防止のため）:

```markdown
パターンの文書化の例:
```python
# PATTERN: これはキャプチャされない（コードブロック内）
def example():
    pass
```

PATTERN: これはキャプチャされる（コードブロック外）
```

これにより、例を文書化する際に誤ってキャプチャすることを防げる。

## ロール別マーカー選択

異なるロールは通常、異なるマーカーを重視する:

| ロール | 主要マーカー |
|--------|-----------|
| 探索（code-explorer） | PATTERN, LEARNED, INSIGHT |
| アーキテクチャ（code-architect, system-architect） | PATTERN, DECISION, INSIGHT |
| セキュリティ（security-auditor） | PATTERN, ANTIPATTERN, LEARNED |
| 品質（qa-engineer） | PATTERN, ANTIPATTERN, LEARNED |
| 検証（verification-specialist） | PATTERN, LEARNED, INSIGHT |
| レガシー（legacy-modernizer） | PATTERN, ANTIPATTERN, LEARNED, DECISION |
| DevOps（devops-sre） | PATTERN, LEARNED, DECISION |
| フロントエンド（frontend-specialist） | PATTERN, LEARNED, DECISION |
| バックエンド（backend-specialist） | PATTERN, ANTIPATTERN, DECISION |
| デザイン（ui-ux-designer） | PATTERN, DECISION, LEARNED |
| ドキュメント（technical-writer） | PATTERN, DECISION, LEARNED |

### このスキルを持たないエージェント

以下のエージェントは insight-recording を持たない:

| エージェント | 根拠 |
|------------|------|
| `product-manager` | コードレベルのパターンではなく、ユーザー向け要件に焦点。判断は PRD/仕様書にキャプチャされる。 |

## 出力形式の例

```markdown
PATTERN: This codebase uses Repository pattern with Unit of Work for all
database operations - see src/repositories/base.ts:15

LEARNED: The user.status field uses magic numbers (1=active, 2=inactive) -
no documentation exists, discovered through characterization testing

DECISION: Chose Strangler Fig pattern for migration due to existing
/api/v1/ that can coexist with new /api/v2/ endpoints
```

## オブザーバビリティ

インサイトキャプチャシステムが提供するもの:

- **統計**: `get_workspace_stats` 関数でステータス別のインサイト数をカウント
- **フォルダ構造**: インサイトは別のディレクトリにステータス別で整理
- **アーカイブ**: 処理済みインサイトは `archive/` ディレクトリに移動可能

**ディレクトリ構造:**
```
.claude/workspaces/{id}/insights/
├── pending/       # レビュー待ち
│   ├── INS-20250121143000-a1b2c3d4.json
│   └── INS-20250121143500-e5f6g7h8.json
├── applied/       # CLAUDE.md またはルールに適用済み
├── rejected/      # ユーザーが却下
└── archive/       # 参照用の古いインサイト
```

**個別インサイトファイル形式:**
```json
{
  "id": "INS-20250121143000-a1b2c3d4",
  "timestamp": "2025-01-21T14:30:00Z",
  "category": "pattern",
  "content": "Error handling uses AppError class...",
  "source": "code-explorer",
  "status": "pending",
  "contentHash": "a1b2c3d4e5f6",
  "workspaceId": "main_a1b2c3d4"
}
```

## Rules (L1 - Hard)

- ALWAYS: 該当する場合は file:line 参照を含める
- NEVER: 些細なまたは明白な発見を記録しない
- NEVER: シークレット、認証情報、または機密データを記録しない
- NEVER: キャプチャしたいマーカーをコードブロック内に置かない

## Defaults (L2 - Soft)

- 予期しない発見があった場合、少なくとも 1 つのインサイトを記録すべき
- インサイトはアクション可能または教育的であるべき
- 各インサイトは簡潔に（1-3 文、または複雑なトピックの場合は複数行）
- プロジェクト固有の学びに焦点を当て、一般的な知識ではなく
- マーカーは行の先頭に置く（オプションの空白の後）

## Guidelines (L3)

- consider: インサイトが重要な理由のコンテキストを含めることを検討
- recommend: 検証用に具体的なコード位置を参照
- consider: そのインサイトが将来の開発者に役立つかを検討
- prefer: 最も具体的なマーカーカテゴリを使用（該当する場合は INSIGHT より PATTERN）
