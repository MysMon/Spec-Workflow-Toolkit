# 言語強制スキル

すべてのユーザー向け出力をコードの可読性を維持しつつ日本語にするスキル。

## ルール階層

### ルール（L1 - ハード）

| ルール | スコープ |
|--------|----------|
| すべてのユーザーレスポンスは 100% 日本語であること | ユーザーインタラクション |
| 仕様書/設計文書の本文は日本語であること | ドキュメント |
| エラーメッセージと説明は日本語であること | エラー処理 |
| NEVER: 英語の説明をユーザーに出力しない | すべての出力 |

### デフォルト（L2 - ソフト）

| ルール | オーバーライド条件 |
|--------|-------------------|
| コードコメントは日本語にすべき | 英語のみのチームと協業する場合 |
| 技術用語は括弧内に英語を含めてよい | 用語が曖昧な場合 |
| コミットメッセージは日本語にすべき | リポジトリの慣例が英語の場合 |

### ガイドライン（L3）

| ガイドライン | 理由 |
|-------------|------|
| 変数名/関数名は英語を維持 | プログラミング言語の慣例 |
| ファイルパスと URL はそのまま | システム互換性 |
| JSON キーは英語を維持 | API 互換性 |
| コード識別子は英語を維持 | IDE/ツールサポート |

## 技術用語マッピング

一貫した用語のためにこのマッピングを使用:

| English | 日本語 | コンテキスト |
|---------|--------|-------------|
| specification | 仕様書 | ドキュメント |
| architecture | アーキテクチャ | 設計 |
| implementation | 実装 | コード |
| refactoring | リファクタリング | コード変更 |
| dependency | 依存関係 | パッケージ |
| repository | リポジトリ | Git |
| deployment | デプロイ | 運用 |
| endpoint | エンドポイント | API |
| middleware | ミドルウェア | バックエンド |
| component | コンポーネント | フロントエンド |
| hook | フック | イベント/React |
| state management | 状態管理 | フロントエンド |
| authentication | 認証 | セキュリティ |
| authorization | 認可 | セキュリティ |
| validation | バリデーション | 入力 |
| serialization | シリアライズ | データ |
| caching | キャッシュ | パフォーマンス |
| logging | ロギング | オブザーバビリティ |
| monitoring | モニタリング | オブザーバビリティ |
| testing | テスト | QA |

## 出力形式の例

### 良い例（正しい）

```markdown
## アーキテクチャ設計

### 概要
このフィーチャーは既存の認証パターンを拡張し、OAuth 2.0をサポートします。

### 実装方針
1. `src/services/auth.ts:45` の既存パターンに従う
2. 新規エンドポイントを `src/api/oauth.ts` に追加
3. 型定義を `src/types/oauth.ts` に作成

### コード例
```typescript
// OAuth認証のコールバック処理
export async function handleOAuthCallback(
  code: string,
  provider: OAuthProvider
): Promise<AuthResult> {
  // プロバイダーからトークンを取得
  const token = await exchangeCodeForToken(code, provider);
  return { success: true, token };
}
```

### トレードオフ
- JWT vs セッション: JWTを採用（スケーラビリティ重視）
```

### 悪い例（不正確）

```markdown
## Architecture Design

### Overview
This feature extends existing auth patterns to support OAuth 2.0.

### Implementation Approach
1. Follow existing pattern at `src/services/auth.ts:45`
2. Add new endpoints to `src/api/oauth.ts`
```

## バリデーションチェックリスト

出力を返す前に確認:

- [ ] すべての説明テキストが日本語であること
- [ ] 技術用語が一貫した日本語用語を使用していること
- [ ] コード識別子が英語のままであること
- [ ] ファイルパスと参照が変更されていないこと
- [ ] 説明に英語のみの文がないこと

## 他のスキルとの統合

このスキルは以下と連携:
- `subagent-contract`: サブエージェント出力が言語ルールに従うことを保証
- `spec-philosophy`: 仕様書に適用
- `evaluator-optimizer`: 品質チェックに言語検証を含む

## エッジケース

### 英語が許容される場合

1. **コードブロック**: 変数名、関数名、クラス名
2. **ファイルパス**: `src/components/Button.tsx`
3. **技術参照**: `file:line` 形式
4. **URL と外部リンク**: 元の形式を維持
5. **JSON/YAML キー**: `{ "status": "success" }`
6. **エラーコード**: `ERR_AUTH_001`
7. **CLI コマンド**: `npm install`, `git commit`

### 英語括弧書きを使用する場合

明確さのために、形式: 日本語 (English) を使用

```markdown
認証 (authentication) と認可 (authorization) の違いを理解することが重要です。
```

使用する場合:
- 日本語で曖昧な用語の場合
- 技術概念の初回導入時
- ユーザーが明示的に英語の用語を求めた場合
