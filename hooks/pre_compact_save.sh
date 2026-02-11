#!/bin/bash
# PreCompact フック: コンパクション前に重要なコンテキストを保存
# コンテキストがコンパクションされる前に進捗状態が保持されることを保証する
# ワークスペース分離された進捗ファイルをサポート

# ワークスペースユーティリティを読み込み
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# フック入力を読み取り
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('trigger','unknown'))" 2>/dev/null || echo "unknown")
CUSTOM=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('custom_instructions',''))" 2>/dev/null || echo "")

# 進捗ファイルの場所を決定（ワークスペース分離）
PROGRESS_FILE=""
WORKSPACE_ID=""

if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)

    # 多層防御: 使用前にワークスペース ID を検証
    if command -v validate_workspace_id &> /dev/null; then
        if ! validate_workspace_id "$WORKSPACE_ID"; then
            echo "警告: 無効なワークスペース ID です。進捗の保存をスキップします" >&2
            exit 0
        fi
    fi

    WORKSPACE_PROGRESS=$(get_progress_file "$WORKSPACE_ID")

    if [ -f "$WORKSPACE_PROGRESS" ]; then
        PROGRESS_FILE="$WORKSPACE_PROGRESS"
    fi
fi

# 進捗ファイルが存在する場合、バックアップを作成しコンパクションのタイムスタンプを追加
# 環境変数を使用して Python にデータを安全に渡す
if [ -n "$PROGRESS_FILE" ] && command -v python3 &> /dev/null; then
    # コンパクション前に進捗ファイルのバックアップを作成
    BACKUP_DIR="$(dirname "$PROGRESS_FILE")/backups"
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    BACKUP_FILE="$BACKUP_DIR/progress-$(date '+%Y%m%d_%H%M%S').json"
    cp "$PROGRESS_FILE" "$BACKUP_FILE" 2>/dev/null

    # 最新の5つのバックアップのみ保持
    ls -t "$BACKUP_DIR"/progress-*.json 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null

    PROGRESS_FILE_PATH="$PROGRESS_FILE" \
    COMPACT_TRIGGER="$TRIGGER" \
    COMPACT_CUSTOM="$CUSTOM" \
    COMPACT_WORKSPACE_ID="$WORKSPACE_ID" \
    python3 << 'PYEOF'
import json
import os
import sys
import fcntl
import tempfile
import signal
from datetime import datetime

# ロック取得のタイムアウト（秒）
LOCK_TIMEOUT = 5

class LockTimeoutError(Exception):
    """ロック取得がタイムアウトした場合に発生。"""
    pass

def lock_timeout_handler(signum, frame):
    raise LockTimeoutError("ロック取得がタイムアウトしました")

try:
    progress_file = os.environ.get('PROGRESS_FILE_PATH', '')
    trigger = os.environ.get('COMPACT_TRIGGER', 'unknown')
    custom = os.environ.get('COMPACT_CUSTOM', '')
    workspace_id = os.environ.get('COMPACT_WORKSPACE_ID', '')

    if not progress_file:
        sys.exit(0)

    # タイムアウト付きファイルロックで安全な並行アクセス
    lock_file = progress_file + '.lock'
    with open(lock_file, 'w') as lf:
        # ロック取得のタイムアウトを設定
        old_handler = signal.signal(signal.SIGALRM, lock_timeout_handler)
        signal.alarm(LOCK_TIMEOUT)
        try:
            fcntl.flock(lf.fileno(), fcntl.LOCK_EX)
            signal.alarm(0)  # ロック成功時にアラームをキャンセル
        except LockTimeoutError:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, old_handler)
            print(f"警告: {LOCK_TIMEOUT}秒以内にロックを取得できませんでした。進捗の更新をスキップします", file=sys.stderr)
            sys.exit(0)
        finally:
            signal.signal(signal.SIGALRM, old_handler)

        try:
            with open(progress_file, "r", encoding='utf-8') as f:
                data = json.load(f)

            # コンパクションイベントを履歴に追加（より詳細なコンテキスト付き）
            if "compactionHistory" not in data:
                data["compactionHistory"] = []

            # コンパクション前の現在の状態スナップショットをキャプチャ
            current_task = data.get("currentTask", "unknown")
            resumption_ctx = data.get("resumptionContext", {})

            data["compactionHistory"].append({
                "timestamp": datetime.now().isoformat(),
                "trigger": trigger,
                "customInstructions": custom if custom else None,
                "workspaceId": workspace_id if workspace_id else None,
                "stateSnapshot": {
                    "currentTask": current_task,
                    "position": resumption_ctx.get("position", "unknown"),
                    "nextAction": resumption_ctx.get("nextAction", "unknown")
                }
            })

            # 最新の10件のコンパクションイベントのみ保持
            data["compactionHistory"] = data["compactionHistory"][-10:]

            # 最終コンパクションのタイムスタンプを更新
            data["lastCompaction"] = datetime.now().isoformat()

            # 再開コンテキストにコンパクション警告を追加
            if "resumptionContext" not in data:
                data["resumptionContext"] = {}
            data["resumptionContext"]["lastCompactionWarning"] = (
                "コンテキストがコンパクションされました。サブエージェントの結果や中間的な発見が失われている可能性があります。"
                "必要に応じて重要なファイルを再読み込みし、重要な分析を再実行してください。"
            )

            # アトミック書き込み: 一時ファイルに書き込み、fsync、その後置換
            dir_name = os.path.dirname(progress_file)
            fd, temp_path = tempfile.mkstemp(dir=dir_name, suffix='.tmp')
            try:
                with os.fdopen(fd, 'w', encoding='utf-8') as tf:
                    json.dump(data, tf, indent=2, ensure_ascii=False)
                    tf.flush()
                    os.fsync(tf.fileno())  # リネーム前にデータがディスクに書き込まれることを保証
                os.replace(temp_path, progress_file)  # os.rename より移植性が高い
            except Exception:
                if os.path.exists(temp_path):
                    os.unlink(temp_path)
                raise
        finally:
            pass  # lf がクローズされるときにロックが解放される

except Exception as e:
    # エラー時にコンパクションをブロックしない
    print(f"警告: 進捗ファイルを更新できませんでした: {e}", file=sys.stderr)
PYEOF
fi

# JSON systemMessage 経由でコンテキストを出力（PreCompact では stdout はユーザーに表示されない）
# サマリーメッセージを構築
SUMMARY="## コンパクション前の状態を保存しました

**トリガー**: $TRIGGER
**ワークスペース ID**: ${WORKSPACE_ID:-"(未設定)"}
**進捗ファイル**: ${PROGRESS_FILE:-"(検出されませんでした)"}

コンパクション後の注意:
- 進捗ファイルを読み取ってコンテキストを復元してください
- ワークスペース: \`.claude/workspaces/${WORKSPACE_ID}/\`
- \`feature-list.json\` で現在のタスクを確認してください
- ドキュメントに記載された位置から続行してください"

# JSON の systemMessage として出力（ユーザーに表示される）
python3 -c "
import json
import sys
summary = '''$SUMMARY'''
print(json.dumps({'systemMessage': summary}))
" 2>/dev/null || echo '{"systemMessage": "コンパクション前の状態を保存しました"}'

exit 0
