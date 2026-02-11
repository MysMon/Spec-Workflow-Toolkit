---
name: tdd-workflow
description: |
  Red-Green-Refactor サイクルによるテスト駆動開発ワークフロー。
  Anthropic 推奨のエージェントコーディング向け TDD パターンに基づく。

  以下の場合に使用:
  - 明確な受入基準のある新機能の実装
  - テストファーストアプローチでリグレッションを防止するバグ修正
  - ユーザーが「TDD」「テストを先に書く」「red-green-refactor」と言った場合
  - 既存コードのリファクタリング（変更前にテストが必要）
  - テストで容易に検証可能な機能

  Trigger phrases: TDD, test-driven, test first, red-green-refactor, write tests before code
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, TodoWrite, AskUserQuestion
model: sonnet
user-invocable: true
---

# テスト駆動開発ワークフロー

Red-Green-Refactor サイクルを通じて品質を保証する規律ある TDD アプローチ。

Claude Code Best Practices より:

> "Test-driven development (TDD) becomes even more powerful with agentic coding: Ask Claude to write tests based on expected input/output pairs."

> "It's crucial to be explicit that you are doing TDD, which helps Claude avoid creating mock implementations or stubbing out imaginary code prematurely."

## 基本原則

### 1. テストは常に先

**ルール**: 失敗するテストなしに実装コードを書かない。

「機能を作って」と言われた場合:「まずテストを書きましょう」と応答する。

### 2. 最小限の実装

**ルール**: 現在のテストを通過する最もシンプルなコードを書く。

- 早すぎる最適化をしない
- 投機的な機能を追加しない
- 「念のため」のコードを書かない

### 3. グリーンの時だけリファクタリング

**ルール**: リファクタリングは全テストが通過している場合のみ行う。

- 動作を変えずに構造を改善する
- リファクタリングの各ステップ後にテストを実行する
- リファクタリングはアトミックで可逆に保つ

## Red-Green-Refactor サイクル

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌─────────┐      ┌─────────┐      ┌──────────┐               │
│  │   RED   │─────▶│  GREEN  │─────▶│ REFACTOR │───┐           │
│  │         │      │         │      │          │   │           │
│  │ 失敗する │      │ 最小限の │      │ コード   │   │           │
│  │ テスト   │      │ コードで │      │ 品質の   │   │           │
│  │ を書く   │      │ 通過     │      │ 改善     │   │           │
│  └─────────┘      └─────────┘      └──────────┘   │           │
│       ▲                                            │           │
│       │                                            │           │
│       └────────────────────────────────────────────┘           │
│                      次の機能                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 1: RED - 失敗するテストを書く

### ステップ

1. **要件を明確に理解する**
2. 期待される動作を表現する**テストを書く**
3. テストを**実行**し、失敗を確認する
4. **失敗を記録する** - テストが有効であることを証明する

### テスト記述ガイドライン

```typescript
// GOOD: 説明的、具体的、1 つの動作をテスト
describe('UserService', () => {
  describe('createUser', () => {
    it('should hash password before storing', async () => {
      const plainPassword = 'password123';
      const user = await userService.createUser({
        email: 'test@example.com',
        password: plainPassword
      });

      expect(user.password).not.toBe(plainPassword);
      expect(await bcrypt.compare(plainPassword, user.password)).toBe(true);
    });
  });
});

// BAD: 曖昧、複数のことをテスト
it('should create user', async () => {
  // 一度に多くのことをテスト
});
```

### 失敗の検証（重要）

**テストが正しい理由で失敗することを常に確認する:**

```
Expected: 'hashed_password_value'
Received: undefined
       ↑ 関数がまだ存在しないことを示す - 正常！

vs.

TypeError: Cannot read property 'hash' of undefined
       ↑ インフラの問題 - まず修正！
```

## Phase 2: GREEN - テストを通過させる

### ステップ

1. テストを通過する**最小限のコード**を書く - それ以上は不要
2. テストを**実行**し、通過を確認する
3. **全テストを実行**してリグレッションがないことを確認する
4. **テストが失敗した場合**、次に進む前にすぐ修正する

### 最小限の実装ルール

| やるべきこと | やってはいけないこと |
|------------|------------------|
| テストが 1 つならハードコード値を返す | 完全なアルゴリズムを実装 |
| シンプルなデータ構造を使用 | 複雑な抽象化を作成 |
| 現在のテストに集中 | 将来のテストを考える |
| 明白で読みやすいコード | 早すぎる最適化 |

### 例: 最小限の実装

```typescript
// テスト:
it('should return greeting with name', () => {
  expect(greet('World')).toBe('Hello, World!');
});

// 最小限の GREEN 実装:
function greet(name: string): string {
  return `Hello, ${name}!`;
}

// これはダメ（早すぎる複雑化）:
function greet(name: string, locale: string = 'en'): string {
  const greetings = { en: 'Hello', es: 'Hola', fr: 'Bonjour' };
  return `${greetings[locale] || 'Hello'}, ${name}!`;
}
```

## Phase 3: REFACTOR - 品質を改善する

### リファクタリングのタイミング

以下の場合のみリファクタリングする:
- 全テストが GREEN
- コードは動くがよりクリーンにできる
- 重複が存在する
- 名前をより明確にできる

### リファクタリングチェックリスト

- [ ] 開始前に全テストが通過
- [ ] 1 つの小さな変更を行う
- [ ] 変更後にテストを実行
- [ ] まだグリーンならコミット
- [ ] 満足するまで繰り返す

### 安全なリファクタリングパターン

| パターン | 適用するタイミング |
|---------|-----------------|
| メソッドの抽出 | 長い関数、繰り返しロジック |
| リネーム | 不明確な名前 |
| 定数の抽出 | マジックナンバー/マジックストリング |
| 条件の簡素化 | 複雑な if/else チェーン |
| 重複の除去 | コピペされたコード |

## TodoWrite との統合

TodoWrite で TDD の進捗を追跡:

```
1. [in_progress] RED: ユーザー登録の失敗テストを書く
2. [pending] GREEN: 最小限の登録ロジックを実装
3. [pending] REFACTOR: バリデーションロジックを抽出
4. [pending] RED: メールの一意性テストを書く
5. [pending] GREEN: 一意メールチェックを追加
...
```

**ルール**: 各 Red-Green-Refactor サイクルは 3 つの todo。

## サブエージェントへの委任

### qa-engineer によるテスト作成

```
qa-engineer に委任:

タスク: [機能]の失敗テストを書く
要件:
- テストファイル: tests/[feature].test.ts
- カバー: [仕様からの受入基準]
- 含む: エッジケース、エラー条件
- 形式: Jest/Vitest の describe/it ブロック

期待される出力:
- テストファイル作成済み
- テストが実行され失敗（RED 状態を確認）
- 失敗理由を文書化
```

### frontend/backend-specialist による実装

```
[specialist] に委任:

タスク: [機能]のテストを通過させる
テスト: tests/[feature].test.ts
制約:
- 最小限の実装のみ
- 追加機能なし
- 早すぎる最適化なし
- 全テストが通過すること

期待される出力:
- 実装が作成済み
- 全テストが通過
- 新たな失敗テストの導入なし
```

## TDD と仕様の連携

### 仕様からテストへ

```markdown
## 仕様: ユーザー登録

**受入基準:**
1. ユーザーはメールとパスワードで登録できる
2. メールは一意でなければならない
3. パスワードは 8 文字以上でなければならない
4. パスワードは保存前にハッシュ化されなければならない

## 導出されたテスト:

1. `it('should create user with valid email and password')`
2. `it('should reject duplicate email')`
3. `it('should reject password shorter than 8 characters')`
4. `it('should hash password before storing')`
```

## よくあるアンチパターン

| アンチパターン | 悪い理由 | 代わりに |
|--------------|---------|---------|
| 実装を先に書く | テストがバグを検出する証拠がない | 常に RED から |
| 複数のテストを一度に書く | どのテストがどのコードを駆動するか不明確 | 一度に 1 つのテスト |
| モックでテストを通す | テストが実際の動作を証明しない | 実際の実装を使用 |
| REFACTOR をスキップ | 技術的負債が蓄積 | コンテキストが新鮮なうちにリファクタリング |
| 実装の詳細をテスト | リファクタリングでテストが壊れる | 内部ではなく動作をテスト |

## TDD によるバグ修正

### バグ修正ワークフロー

1. **バグを再現するテストを書く**
   - 現在のコードでテストが失敗すること
   - 失敗メッセージがバグを説明すること

2. **テストが失敗することを確認する**
   - バグの存在を証明
   - テストがそれを検出することを証明

3. **バグを修正する**
   - テストを通過するための最小限の変更
   - 「近くの」問題は修正しない

4. **全テストを実行する**
   - 元のテストが通過
   - リグレッションの導入なし

## /spec-implement との統合

`/spec-implement` の実装フェーズ中:

```
1. 仕様と設計を読む
2. 受入基準を抽出する
3. 各基準について:
   a. RED: 失敗テストを書く
   b. GREEN: 最小限の実装
   c. REFACTOR: クリーンアップ
4. フルテストスイートを実行
5. 進捗ファイルを更新
6. 動作するコードをコミット
```

## Rules (L1 - Hard)

TDD の核心的な規律。違反は方法論全体を損なう。

- NEVER: テストの前に実装を書かない（TDD の目的を無効化）
- NEVER: RED の確認ステップをスキップしない（テストの有効性を証明）
- NEVER: RED の状態でリファクタリングしない（テスト失敗中のコード変更）
- ALWAYS: コミット前に全テストを実行する（リグレッションの検出）
- ALWAYS: 各 Red-Green-Refactor サイクルを 3 つの別々の todo として追跡する（規律の維持）
- NEVER: 複数の TDD サイクルを 1 つの todo にまとめない（漸進主義を無効化）

## Defaults (L2 - Soft)

テスト品質に重要。適切な理由がある場合はオーバーライド可。

- テストを高速かつ集中的に保つ（遅いテストはスキップされる）
- 実装の詳細ではなく動作をテストする（脆いテスト）
- 一度に 1 つのテストを書く（因果関係の明確化）

## Guidelines (L3)

効果的な TDD 実践のための推奨事項。

- consider: テストの存在理由をコメントやテスト名に記述することを検討
- prefer: 実用的な場合はモックより実際の実装を推奨
- consider: 再利用のためのテストフィクスチャの抽出を検討
