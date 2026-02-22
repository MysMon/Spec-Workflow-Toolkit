---
name: long-running-tasks
description: |
  状態永続化と進捗トラッキングを伴う自律的ロングランニングタスクパターン。
  Use when: 複数ステップタスク、セッション間の状態永続化、大規模マイグレーション。
  Trigger phrases: long task, autonomous, persist state, track progress, migration, multi-step
allowed-tools: Read, Write, Glob, Grep, Bash, TodoWrite
model: sonnet
user-invocable: true
---

詳細手順は同ディレクトリの `INSTRUCTIONS.md` を参照。
