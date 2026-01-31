---
name: spec-reading-guide
description: |
  Guide for reading and understanding specification and design templates.

  Use when:
  - Reading or reviewing spec files (docs/specs/*.md)
  - Understanding the structure of specifications
  - Extracting key information from spec/design documents

  Trigger phrases: spec structure, reading spec, understanding spec, spec template
allowed-tools: Read, Glob
model: sonnet
user-invocable: false
---

# Specification Reading Guide

This skill provides guidance on how to read and understand the specification and design templates used in this project.

## Template Overview

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `SPEC-TEMPLATE-MINIMAL.md` | Quick specs for small changes | Low complexity, <1 day effort |
| `SPEC-TEMPLATE.md` | Standard feature specifications | Medium complexity features |
| `SPEC-TEMPLATE-CRITICAL.md` | Security/P0/Architecture specs | High-risk or security-sensitive |
| `DESIGN-TEMPLATE.md` | Implementation design | Accompanies spec for implementation |

## How to Read a Specification

### Step 1: Quick Overview (30 seconds)

Start with the **Overview** table at the top:

| Field | What to Extract |
|-------|-----------------|
| **What** | 1-sentence description of the feature |
| **Why** | Business value or problem being solved |
| **Risk** | Key risks to watch for |
| **Complexity** | Low/Medium/High - affects effort estimation |
| **Scope** | What's IN and what's OUT |

### Step 2: Must Requirements (Top 3)

Immediately after Overview, check the **Must Requirements (Top 3)** section:

```markdown
### Must Requirements (Top 3)
1. **FR-XXX**: Most critical requirement
2. **FR-XXX**: Second critical requirement
3. **FR-XXX**: Third critical requirement
```

These are the non-negotiable requirements that must be implemented.

### Step 3: Known Pitfalls (Before Implementation)

Before implementing, review the **Known Pitfalls** section:

| Column | Meaning |
|--------|---------|
| やりがちな間違い | Common mistakes to avoid |
| 正しいアプローチ | Correct approach to use |
| 理由 | Why this matters |

### Step 4: Full Requirements (As Needed)

For detailed work, read the full **Functional Requirements** section:

| Priority | Meaning |
|----------|---------|
| Must | Required for release |
| Should | Important but adjustable |
| Could | Nice to have |

### Step 5: Quick Navigation

Use the **Quick Navigation** links at the top to jump to specific sections:

- Overview - 30秒で概要把握
- Must Requirements - 最重要要件
- Functional Requirements - 詳細仕様
- Technical Considerations - 技術制約
- Acceptance Criteria - 受入条件

## How to Read a Design Document

### Step 1: Design Summary

Start with the **Design Summary** table:

| Field | What to Extract |
|-------|-----------------|
| **Approach** | 1-sentence design approach |
| **Key Decision** | Most important design choice |
| **Complexity** | Implementation complexity |
| **Files to Change** | Estimated scope |

### Step 2: Build Sequence

Check the **Build Sequence** for implementation order:

1. What to build first (and why)
2. Dependencies between tasks
3. Affected files for each task

### Step 3: Implementation Map

Review the **Implementation Map** for:

- Which requirement maps to which file
- Create vs Modify actions
- Implementation notes

### Step 4: Rejected Approaches

Read **Rejected Approaches** to understand:

- What was considered but not chosen
- Why alternatives were rejected
- Trade-offs that were made

## Template-Specific Sections

### CRITICAL Template Only

| Section | Purpose |
|---------|---------|
| **Critical Constraints** | Absolute rules (max 3 items) |
| **Security Considerations** | Threat analysis, security checklist |
| **Rollback Plan** | When and how to roll back |

### MINIMAL Template

Simplified structure with only essential sections:

- Overview (What/Why/Risk/Complexity)
- Requirements table
- Out of Scope
- Technical Notes
- Acceptance Criteria (single scenario)

## Reading Strategy by Role

| Role | Focus On |
|------|----------|
| **Implementer** | Overview → Top 3 → Known Pitfalls → Build Sequence |
| **Reviewer** | Overview → Full Requirements → Acceptance Criteria |
| **Architect** | Overview → Technical Considerations → Rejected Approaches |
| **QA** | Acceptance Criteria → Non-Functional Requirements |

## Quick Reference: Section Purposes

| Section | Question It Answers |
|---------|---------------------|
| Overview | What are we building and why? |
| Must Requirements | What must be done? |
| Known Pitfalls | What mistakes should I avoid? |
| Build Sequence | In what order should I implement? |
| Implementation Map | Which files need to change? |
| Acceptance Criteria | How do I verify it works? |
| Out of Scope | What should I NOT build? |
| Rejected Approaches | Why wasn't X chosen? |
