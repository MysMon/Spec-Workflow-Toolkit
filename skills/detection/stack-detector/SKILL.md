---
name: stack-detector
description: |
  設定ファイルとソースコードからプロジェクトの技術スタックを自動検出。
  Use when: 新規コードベースでの作業開始、言語/フレームワーク/ツールの特定。
  Trigger phrases: detect stack, what framework, identify technology, project setup
allowed-tools: Read, Glob, Grep, Bash
model: haiku
user-invocable: false
context: fork
agent: Explore
---

詳細手順は同ディレクトリの `INSTRUCTIONS.md` を参照。
検出テーブル一覧は `REFERENCE.md` を参照。
