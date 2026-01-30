#!/bin/bash
# SessionStart Hook: Enforce Japanese language mode for all outputs
# This hook runs once at session start to set language context
#
# Based on research findings:
# - Claude Opus 4.5 Japanese performance: 96.9% of English baseline
# - No evidence that English thinking is more efficient for Japanese users
# - Japanese documentation improves maintainability for Japanese teams

# Minimal banner - detailed rules are in language-enforcement skill
echo "**言語モード**: 日本語 (Japanese). 詳細は \`language-enforcement\` スキル参照。"
echo ""

exit 0
