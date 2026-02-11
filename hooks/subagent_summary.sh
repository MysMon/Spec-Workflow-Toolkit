#!/bin/bash
# SubagentStop フック: サブエージェントの完了をログに記録しサマリーを出力
# サブエージェントが作業を完了した時に実行される
# マルチプロジェクト開発をサポートするため、ログはワークスペースごとに分離される
#
# SubagentStop フック入力形式（Claude Code から）:
#   {
#     "session_id": "...",
#     "transcript_path": "~/.claude/projects/.../xxx.jsonl",
#     "permission_mode": "default",
#     "hook_event_name": "SubagentStop",
#     "stop_hook_active": true/false
#   }

# ワークスペースユーティリティを読み込み
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# フック入力を読み取り（JSON メタデータ）
INPUT=$(cat)

# 環境変数からエージェント情報を取得（Claude Code が設定）
AGENT_NAME="${CLAUDE_AGENT_NAME:-unknown}"
AGENT_ID="${CLAUDE_AGENT_ID:-}"
AGENT_STATUS="completed"
SESSION_ID=""
TRANSCRIPT_PATH=""

# メタデータ JSON をパースしてセッション情報を取得
if command -v python3 &> /dev/null && [ -n "$INPUT" ]; then
    HOOK_INPUT_VAR="$INPUT" \
    PARSED=$(python3 << 'PYEOF'
import json
import os
import sys

hook_input = os.environ.get('HOOK_INPUT_VAR', '')
if not hook_input:
    print('|||')
    sys.exit(0)

try:
    metadata = json.loads(hook_input)
    session_id = metadata.get('session_id', '')
    transcript_path = metadata.get('transcript_path', '')
    stop_hook_active = 'true' if metadata.get('stop_hook_active', False) else 'false'
    print(f'{session_id}|{transcript_path}|{stop_hook_active}')
except json.JSONDecodeError:
    print('|||')
except Exception:
    print('|||')
PYEOF
)

    IFS='|' read -r SESSION_ID TRANSCRIPT_PATH STOP_HOOK_ACTIVE <<< "$PARSED"
fi

# ログディレクトリの決定（ワークスペース分離またはフォールバック）
LOG_DIR=""
LOG_FILE=""

if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)
    LOG_DIR=$(get_logs_dir "$WORKSPACE_ID")
    LOG_FILE=$(get_subagent_log "$WORKSPACE_ID")

    # ワークスペースのディレクトリ構造が存在することを確認
    ensure_workspace_exists "$WORKSPACE_ID"
else
    # プラグインレベルのログにフォールバック（レガシー動作）
    LOG_DIR="${CLAUDE_PLUGIN_ROOT:-.}/logs"
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/subagent_activity.log"
fi

# 完了タイムスタンプをログに記録
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 詳細なログエントリを構築
LOG_ENTRY="[$TIMESTAMP] エージェント: $AGENT_NAME | ステータス: $AGENT_STATUS"
[ -n "$AGENT_ID" ] && LOG_ENTRY="$LOG_ENTRY | ID: $AGENT_ID"
[ -n "$SESSION_ID" ] && LOG_ENTRY="$LOG_ENTRY | セッション: $SESSION_ID"
[ -n "$WORKSPACE_ID" ] && LOG_ENTRY="$LOG_ENTRY | ワークスペース: $WORKSPACE_ID"

# アクティビティログに追記
echo "$LOG_ENTRY" >> "$LOG_FILE"

# セッション固有のファイルにもログを記録（利用可能な場合）
if command -v get_session_log &> /dev/null; then
    SESSION_LOG=$(get_session_log "$WORKSPACE_ID")
    echo "$LOG_ENTRY" >> "$SESSION_LOG"
fi

# JSON systemMessage 経由でサマリーを出力（SubagentStop では stdout はユーザーに表示されない）
# サマリーメッセージを構築
SUMMARY="---
**サブエージェント完了:** \`$AGENT_NAME\` (ステータス: $AGENT_STATUS)

上記の出力を確認し、次の判断をしてください:
- 承認して次のフェーズに進む
- 明確化や変更を依頼する
- 別のエージェントにフォローアップを委任する
---"

# JSON の systemMessage として出力（ユーザーに表示される）
python3 -c "import json; print(json.dumps({'systemMessage': '''$SUMMARY'''}))" 2>/dev/null || \
    echo '{"systemMessage": "サブエージェントが完了しました: '"$AGENT_NAME"'"}'

exit 0
