# evaluator-optimizer Examples

エバリュエーター・オプティマイザーパターンの実践例。反復ごとのスコア推移と改善プロセスを示す。

## 例 1: ドキュメント最適化

```markdown
## 反復 1

### ジェネレーター出力
```typescript
/**
 * Creates a user
 * @param data - user data
 */
function createUser(data: UserData): User { ... }
```

### エバリュエーターフィードバック
スコア: 65
問題点:
- 不足: パラメータドキュメントが不完全
- 不足: 戻り値の説明
- 不足: エラー条件
- 不足: 使用例

### 反復 2

### ジェネレーター出力（改善版）
```typescript
/**
 * 提供されたデータで新しいユーザーアカウントを作成する。
 *
 * @param data - ユーザー作成データ
 * @param data.email - 有効なメールアドレス（一意である必要あり）
 * @param data.password - パスワード（最低8文字、保存前にハッシュ化）
 * @param data.name - 表示名（オプション）
 *
 * @returns 生成された ID を持つ作成済み User オブジェクト
 *
 * @throws {DuplicateEmailError} メールが既に存在する場合
 * @throws {ValidationError} データがバリデーションに失敗した場合
 *
 * @example
 * const user = await createUser({
 *   email: 'john@example.com',
 *   password: 'securePass123'
 * });
 */
function createUser(data: UserData): Promise<User> { ... }
```

### エバリュエーターフィードバック
スコア: 92
判定: PASS
```

## 例 2: アルゴリズム最適化

```markdown
## 反復 1

### ジェネレーター出力
function findDuplicates(arr) {
  const duplicates = [];
  for (let i = 0; i < arr.length; i++) {
    for (let j = i + 1; j < arr.length; j++) {
      if (arr[i] === arr[j] && !duplicates.includes(arr[i])) {
        duplicates.push(arr[i]);
      }
    }
  }
  return duplicates;
}

### エバリュエーターフィードバック
スコア: 55
問題点:
- パフォーマンス: O(n²) の時間計算量、includes で O(n)
- 正確性: 動作するが非効率
修正: Set または Map で O(n) の解法にする

### 反復 2

### ジェネレーター出力（改善版）
function findDuplicates(arr) {
  const seen = new Set();
  const duplicates = new Set();

  for (const item of arr) {
    if (seen.has(item)) {
      duplicates.add(item);
    } else {
      seen.add(item);
    }
  }

  return [...duplicates];
}

### エバリュエーターフィードバック
スコア: 95
判定: PASS
強み:
- O(n) の時間計算量
- O(n) の空間計算量（この問題では最適）
- クリーンで読みやすい実装
```
