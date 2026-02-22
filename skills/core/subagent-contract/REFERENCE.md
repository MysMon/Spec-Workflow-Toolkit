# エージェント固有の結果フォーマット例

このファイルには各エージェントタイプの詳細な例を含む。サブエージェント出力のフォーマット実装時にこれらを参照。

## 探索エージェント（code-explorer, Explore）

```markdown
## Code Explorer 結果

### ステータス
SUCCESS

### サマリー
ログインエンドポイントから JWT バリデーション、セッション作成までの認証フローをトレース。

### 調査結果

#### エントリーポイント
| エントリ | File:Line | タイプ |
|---------|-----------|--------|
| POST /auth/login | `src/api/auth.ts:45` | REST エンドポイント |
| POST /auth/refresh | `src/api/auth.ts:89` | REST エンドポイント |

#### 実行フロー
1. リクエスト → `src/api/auth.ts:45` (loginHandler)
2. バリデーション → `src/validators/auth.ts:23` (validateLogin)
3. サービス → `src/services/auth.ts:67` (authenticate)
4. リポジトリ → `src/repositories/user.ts:34` (findByEmail)
5. レスポンス ← トークン生成

#### アーキテクチャパターン
- パターン: Repository + Service + Controller
- 証拠: `src/services/auth.ts:8`, `src/repositories/user.ts:5`

#### 依存関係
- 内部: UserRepository, SessionService
- 外部: bcrypt, jsonwebtoken

### 主要な参照
| 項目 | 場所 | 関連性 |
|------|------|--------|
| AuthService | `src/services/auth.ts:8` | コア認証ロジック |
| JWTMiddleware | `src/middleware/jwt.ts:15` | トークンバリデーション |
| UserRepository | `src/repositories/user.ts:5` | ユーザーデータアクセス |

### 信頼度
92 - 明確なパターン、すべてのパスを完了までトレース

### 次のステップ
1. 実装の詳細は `src/services/auth.ts` を読む
2. トークン設定は `src/config/jwt.ts` をレビュー
```

## 設計エージェント（code-architect, system-architect）

```markdown
## Code Architect 結果

### ステータス
SUCCESS

### サマリー
既存の認証パターンに従って OAuth 統合を設計。単一の推奨アプローチと実装マップ付き。

### 調査結果

#### パターン分析
| パターン | 例 | 推奨 |
|---------|-----|------|
| サービスレイヤー | `src/services/auth.ts:8` | OAuthService で拡張 |
| リポジトリ | `src/repositories/user.ts:5` | OAuthCredential モデルを追加 |
| 設定 | `src/config/auth.ts:12` | OAuth プロバイダー設定を追加 |

#### 推奨アーキテクチャ

**アプローチ**: 既存の AuthService を OAuth 機能で拡張

**根拠**:
- `src/services/auth.ts:8` の既存サービスパターンと整合
- 既存コードへの変更が最小限
- `src/middleware/jwt.ts:15` の JWT インフラを再利用

#### 実装マップ

| コンポーネント | ファイル | アクション |
|------------|------|----------|
| OAuthService | `src/services/oauth.ts` | 作成 |
| OAuthConfig | `src/config/oauth.ts` | 作成 |
| AuthService | `src/services/auth.ts:145` | 変更（OAuth メソッド追加） |
| routes | `src/routes/auth.ts:78` | 変更（OAuth ルート追加） |

#### ビルド順序
1. プロバイダー設定で OAuthConfig を作成
2. プロバイダー処理で OAuthService を作成
3. OAuth フローで AuthService を拡張
4. OAuth ルートを追加
5. 統合テストを作成

### 主要な参照
| 項目 | 場所 | 関連性 |
|------|------|--------|
| AuthService | `src/services/auth.ts:8` | 拡張のベース |
| JWTConfig | `src/config/jwt.ts:5` | 従うべきトークンパターン |
| UserModel | `src/models/user.ts:12` | OAuth リンクが必要な可能性 |

### 信頼度
88 - 明確なパターン、ユーザーモデルについて 1 つの仮定あり

### 検討したトレードオフ
- 別の OAuth マイクロサービス: 却下（このスケールではオーバーヘッド）
- プロバイダー SDK の直接使用: 却下（抽象化が不足）
```

## レビューエージェント（qa-engineer, security-auditor）

```markdown
## Security Auditor 結果

### ステータス
PARTIAL

### サマリー
認証モジュールをレビュー。2 つのクリティカルな問題と 3 つの推奨事項を発見。

### 調査結果

#### 検出された問題

| ID | 問題 | File:Line | 重大度 | 信頼度 |
|----|------|-----------|--------|--------|
| SEC-001 | ハードコードされた JWT シークレット | `src/config/jwt.ts:8` | Critical | 98 |
| SEC-002 | レート制限の欠如 | `src/api/auth.ts:45` | Critical | 95 |
| SEC-003 | 冗長なエラーメッセージ | `src/services/auth.ts:89` | Important | 85 |

#### 問題の詳細

**SEC-001: ハードコードされた JWT シークレット**
```typescript
// src/config/jwt.ts:8
const JWT_SECRET = 'hardcoded-secret-key-123'; // CRITICAL
```
**リスク**: トークン偽造、認証の完全バイパス
**修正**: 環境変数 `process.env.JWT_SECRET` を使用

**SEC-002: レート制限の欠如**
```typescript
// src/api/auth.ts:45 - レート制限なし
router.post('/login', loginHandler);
```
**リスク**: ログインへのブルートフォース攻撃
**修正**: express-rate-limit ミドルウェアを追加

**SEC-003: 冗長なエラーメッセージ**
```typescript
// src/services/auth.ts:89
throw new Error(`User ${email} not found in database`);
```
**リスク**: 情報漏洩（メールの存在を確認可能）
**修正**: 汎用的な「無効な認証情報」メッセージ

#### コンプライアンスチェック
| 基準 | ステータス | 備考 |
|------|----------|------|
| OWASP A07 認証の失敗 | FAIL | SEC-001, SEC-002 |
| OWASP A01 アクセス制御 | PASS | 適切な認可チェック |

### 主要な参照
| 項目 | 場所 | 関連性 |
|------|------|--------|
| JWT Config | `src/config/jwt.ts:8` | ハードコードされたシークレットを含む |
| Login Handler | `src/api/auth.ts:45` | レート制限が欠如 |

### 信頼度
94 - コード証拠で問題を検証済み

### 重大度サマリー
- Critical: 2
- Important: 1
- Minor: 0

### 次のステップ
1. SEC-001 を直ちに修正（セキュリティクリティカル）
2. デプロイ前にレート制限を追加
3. 情報漏洩についてすべてのエラーメッセージをレビュー
```

## 実装エージェント（frontend-specialist, backend-specialist）

```markdown
## Backend Specialist 結果

### ステータス
SUCCESS

### サマリー
登録、ログイン、パスワードリセットを含む UserService を実装。すべてのテストが合格。

### 調査結果

#### 作成されたファイル
| ファイル | 目的 | 行数 |
|---------|------|------|
| `src/services/user.ts` | ユーザービジネスロジック | 145 |
| `src/repositories/user.ts` | データアクセス | 78 |
| `tests/services/user.test.ts` | ユニットテスト | 234 |

#### 変更されたファイル
| ファイル | 変更内容 | 変更行数 |
|---------|---------|---------|
| `src/routes/index.ts:45` | ユーザールートを追加 | +5 |
| `src/services/index.ts:8` | UserService をエクスポート | +1 |

#### テスト結果
```
PASS tests/services/user.test.ts
  UserService
    createUser
      ✓ should create user with hashed password (45ms)
      ✓ should reject duplicate email (23ms)
      ✓ should validate password length (12ms)
    login
      ✓ should return token for valid credentials (34ms)
      ✓ should reject invalid password (18ms)

Tests: 5 passed, 5 total
Coverage: 94%
```

#### 実装メモ
- `src/repositories/product.ts:8` のリポジトリパターンに従った
- コストファクター 12 の bcrypt を使用（既存と一致）
- JWT トークンの有効期限は 24 時間（環境変数で設定可能）

### 主要な参照
| 項目 | 場所 | 関連性 |
|------|------|--------|
| UserService | `src/services/user.ts:8` | メイン実装 |
| createUser | `src/services/user.ts:45` | 登録ロジック |
| login | `src/services/user.ts:89` | 認証ロジック |

### 信頼度
96 - テスト合格、パターンに従った

### 次のステップ
1. 承認のために実装をレビュー
2. 利用可能であれば統合テストを実行
3. API ドキュメントを更新
```

## エラー結果フォーマット

サブエージェントがエラーに遭遇した場合:

```markdown
## [エージェント名] 結果

### ステータス
FAILED

### サマリー
[エラーカテゴリ] のためタスクを完了できず。

### エラー詳細
| 項目 | 値 |
|------|-----|
| タイプ | [ErrorType] |
| メッセージ | [エラーメッセージ] |
| 発生場所 | [file:line またはステップ] |
| 回復可能 | [true/false] |

### 試行したアクション
1. [最初に試したこと]
2. [次に試したこと]
3. [失敗前の最後の試行]

### 根本原因分析
[エラーが発生した理由の分析]

### 回復オプション
1. [オプション 1]: [説明]
2. [オプション 2]: [説明]

### ブロッカー
- [進行を妨げているものの説明]
  解決策: [ブロック解除に必要なこと]
```
