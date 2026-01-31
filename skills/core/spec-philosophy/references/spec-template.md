# Specification Template Reference

Authoritative templates are maintained in `docs/specs/`. This file provides a quick reference.

## Template Selection

| Condition | Template |
|-----------|----------|
| Small change (Low complexity) | `docs/specs/SPEC-TEMPLATE-MINIMAL.md` |
| Standard feature (Medium complexity) | `docs/specs/SPEC-TEMPLATE.md` |
| P0 / Security / Architecture | `docs/specs/SPEC-TEMPLATE-CRITICAL.md` |
| Design document (accompanies spec) | `docs/specs/DESIGN-TEMPLATE.md` |

## Key Sections (All Templates)

### Overview Table

| 項目 | 内容 |
|------|------|
| **What** | 1文で何を実装するか |
| **Why** | 1文でビジネス価値・解決する問題 |
| **Risk** | 主要なリスクや注意点 |
| **Complexity** | Low / Medium / High |
| **Scope** | IN: 含有項目 / OUT: 除外項目 |

### Must Requirements (Top 3)

> 実装者が最初に確認すべき最重要要件

1. **FR-XXX**: 最重要要件の1行要約
2. **FR-XXX**: 2番目の要件の1行要約
3. **FR-XXX**: 3番目の要件の1行要約

### Known Pitfalls (STANDARD/CRITICAL)

| やりがちな間違い | 正しいアプローチ | 理由 |
|-----------------|------------------|------|
| [よくあるミス] | [正解] | [なぜ重要か] |

## CRITICAL Template Additional Sections

- **Security**: Overview内にセキュリティ上の主要懸念点
- **Critical Constraints**: 絶対守るべき制約（3項目以内）
- **Security Considerations**: Threat Analysis、Security Checklist、Data Protection
- **Rollback Plan**: ロールバック条件と手順

## For Full Templates

See the authoritative files in `docs/specs/`:
- `SPEC-TEMPLATE.md` - Standard template with Quick Navigation and writing guides
- `SPEC-TEMPLATE-MINIMAL.md` - Quick specs for low complexity changes
- `SPEC-TEMPLATE-CRITICAL.md` - Extended template for security/P0 features
- `DESIGN-TEMPLATE.md` - Design document with Implementation Map and Build Sequence
