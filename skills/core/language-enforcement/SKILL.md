---
name: language-enforcement
description: |
  Enforces Japanese language output for all user-facing content.

  Use when:
  - Agent outputs need to be in Japanese
  - Verifying language consistency across responses
  - Generating specifications or documentation in Japanese

  Trigger phrases: Japanese, 日本語, language mode, output language
---

# Language Enforcement Skill

This skill ensures all user-facing output is in Japanese while maintaining code readability.

## Rule Hierarchy

### L1 Hard Rules (MUST - Never Break)

| Rule | Scope |
|------|-------|
| All user responses must be 100% Japanese | User interaction |
| Specification/design document body must be Japanese | Documentation |
| Error messages and explanations must be Japanese | Error handling |
| NEVER output English explanations to users | All outputs |

### L2 Soft Rules (Should - Default Behavior)

| Rule | Override Condition |
|------|-------------------|
| Code comments should be Japanese | When collaborating with English-only team |
| Technical terms may include English in parentheses | When term is ambiguous |
| Commit messages should be Japanese | When repo convention is English |

### L3 Guidelines (Consider - Recommendations)

| Guideline | Rationale |
|-----------|-----------|
| Keep variable/function names in English | Programming language conventions |
| Keep file paths and URLs unchanged | System compatibility |
| Keep JSON keys in English | API compatibility |
| Keep code identifiers in English | IDE/tooling support |

## Technical Term Mapping

Use this mapping for consistent terminology:

| English | 日本語 | Context |
|---------|--------|---------|
| specification | 仕様書 | Documents |
| architecture | アーキテクチャ | Design |
| implementation | 実装 | Code |
| refactoring | リファクタリング | Code changes |
| dependency | 依存関係 | Packages |
| repository | リポジトリ | Git |
| deployment | デプロイ | Operations |
| endpoint | エンドポイント | API |
| middleware | ミドルウェア | Backend |
| component | コンポーネント | Frontend |
| hook | フック | Events/React |
| state management | 状態管理 | Frontend |
| authentication | 認証 | Security |
| authorization | 認可 | Security |
| validation | バリデーション | Input |
| serialization | シリアライズ | Data |
| caching | キャッシュ | Performance |
| logging | ロギング | Observability |
| monitoring | モニタリング | Observability |
| testing | テスト | QA |

## Output Format Examples

### Good Example (Correct)

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

### Bad Example (Incorrect)

```markdown
## Architecture Design

### Overview
This feature extends existing auth patterns to support OAuth 2.0.

### Implementation Approach
1. Follow existing pattern at `src/services/auth.ts:45`
2. Add new endpoints to `src/api/oauth.ts`
```

## Validation Checklist

Before returning output, verify:

- [ ] All explanatory text is in Japanese
- [ ] Technical terms use consistent Japanese terminology
- [ ] Code identifiers remain in English
- [ ] File paths and references are unchanged
- [ ] No English-only sentences in explanations

## Integration with Other Skills

This skill works with:
- `subagent-contract`: Ensures subagent outputs follow language rules
- `spec-philosophy`: Applies to specification documents
- `evaluator-optimizer`: Quality checks include language verification

## Edge Cases

### When English is Acceptable

1. **Code blocks**: Variable names, function names, class names
2. **File paths**: `src/components/Button.tsx`
3. **Technical references**: `file:line` format
4. **URLs and external links**: Keep original format
5. **JSON/YAML keys**: `{ "status": "success" }`
6. **Error codes**: `ERR_AUTH_001`
7. **CLI commands**: `npm install`, `git commit`

### When to Use English Parenthetical

For clarity, use format: 日本語 (English)

```markdown
認証 (authentication) と認可 (authorization) の違いを理解することが重要です。
```

Only use when:
- Term is ambiguous in Japanese
- First introduction of technical concept
- User explicitly asks for English term
