#!/bin/bash
# セッションサマリフック - Stop イベント
# セッション中に行われた変更のサマリを systemMessage 経由で出力
# スタック非依存
#
# 注: Stop フックはユーザー表示のために systemMessage 付き JSON 出力を使用する。
# プレーン stdout は verbose モードでのみ表示される。

# ワークスペースユーティリティを読み込み
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# サマリを変数に構築
SUMMARY=""

add_line() {
    SUMMARY="${SUMMARY}$1
"
}

add_line ""
add_line "═══════════════════════════════════════════════════"
add_line "                  セッションサマリ                    "
add_line "═══════════════════════════════════════════════════"
add_line ""

# ワークスペース情報を表示
if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)
    add_line "[ワークスペース] $WORKSPACE_ID"

    # 進捗ファイルを確認
    PROGRESS_FILE=$(get_progress_file "$WORKSPACE_ID")
    if [ -f "$PROGRESS_FILE" ]; then
        add_line "  [進捗] 進捗ファイル: 存在します"
    fi
    add_line ""
fi

# Git リポジトリかどうかを確認
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Git ステータスサマリ
    add_line "[GIT ステータス]"
    add_line "──────────────"

    # ステージ済みの変更
    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    if [ "$STAGED" -gt 0 ]; then
        add_line "  [ステージ済み] ステージ済みファイル: $STAGED"
        while IFS= read -r file; do
            add_line "     $file"
        done < <(git diff --cached --name-only 2>/dev/null | head -5)
        [ "$STAGED" -gt 5 ] && add_line "     ... 他 $((STAGED - 5)) ファイル"
    fi

    # 未ステージの変更
    UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    if [ "$UNSTAGED" -gt 0 ]; then
        add_line "  [変更済み] 変更済みファイル: $UNSTAGED"
        while IFS= read -r file; do
            add_line "     $file"
        done < <(git diff --name-only 2>/dev/null | head -5)
        [ "$UNSTAGED" -gt 5 ] && add_line "     ... 他 $((UNSTAGED - 5)) ファイル"
    fi

    # 未追跡ファイル
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    if [ "$UNTRACKED" -gt 0 ]; then
        add_line "  [新規] 未追跡ファイル: $UNTRACKED"
        while IFS= read -r file; do
            add_line "     $file"
        done < <(git ls-files --others --exclude-standard 2>/dev/null | head -5)
        [ "$UNTRACKED" -gt 5 ] && add_line "     ... 他 $((UNTRACKED - 5)) ファイル"
    fi

    # ブランチ情報
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        add_line ""
        add_line "  [ブランチ] 現在のブランチ: $BRANCH"

        # リモートに対する先行/遅延を確認
        AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
        [ "$AHEAD" -gt 0 ] && add_line "     ^ リモートより $AHEAD コミット先行"
        [ "$BEHIND" -gt 0 ] && add_line "     v リモートより $BEHIND コミット遅延"
    fi

    # このセッションでの最近のコミット（直近1時間）
    RECENT=$(git log --oneline --since="1 hour ago" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$RECENT" -gt 0 ]; then
        add_line ""
        add_line "  [コミット] 最近のコミット:"
        while IFS= read -r commit; do
            add_line "     $commit"
        done < <(git log --oneline --since="1 hour ago" 2>/dev/null | head -5)
    fi
else
    add_line "[情報] Git リポジトリではありません"
fi

add_line ""
add_line "═══════════════════════════════════════════════════"
add_line ""

# JSON の systemMessage として出力（ユーザーに表示される）
# Python を使用してサマリの適切な JSON エスケープを行う
python3 -c "
import json
import sys
summary = '''$SUMMARY'''
print(json.dumps({'systemMessage': summary}))
" 2>/dev/null || echo '{"systemMessage": "セッションが終了しました"}'

exit 0
