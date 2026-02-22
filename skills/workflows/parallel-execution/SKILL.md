---
name: parallel-execution
description: |
  並列サブエージェント実行によるコンテキスト効率最大化パターン。
  Use when: 複数独立タスクの同時実行、並列レビュー、多角的コードベース探索。
  Trigger phrases: parallel review, concurrent agents, multi-agent, run simultaneously
allowed-tools: Read, Glob, Grep, Task
model: sonnet
user-invocable: true
context: fork
agent: general-purpose
---

詳細手順は同ディレクトリの `INSTRUCTIONS.md` を参照。
