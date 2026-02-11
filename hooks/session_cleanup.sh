#!/bin/bash
# SessionEnd フック: Claude Code セッション終了時にリソースをクリーンアップ
# セッション終了時（ユーザー終了、タイムアウト等）に実行される
#
# 責務:
# - ディスク肥大化を防ぐための古いログファイルのローテーション
# - セッション中に作成された一時ファイルのクリーンアップ
# - 古いワークスペースデータのアーカイブ（30日以上経過したもの）

# ワークスペースユーティリティを読み込み
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# 設定
LOG_RETENTION_DAYS=30
MAX_LOG_SIZE_MB=10
WORKSPACE_BASE=".claude/workspaces"

# --- クロスプラットフォームユーティリティ ---
# ファイルの更新時刻をエポックからの秒数で取得（クロスプラットフォーム）
get_file_mtime() {
    local file="$1"

    # まずファイルの存在を確認（競合状態の防止）
    if [ ! -f "$file" ]; then
        echo 0
        return
    fi

    # プラットフォームに適した stat コマンドを使用（POSIX 互換）
    case "$OSTYPE" in
        darwin*)
            # macOS: stat -f%m は更新時刻を返す
            stat -f%m "$file" 2>/dev/null || echo 0
            ;;
        *)
            # Linux: stat -c %Y は更新時刻を返す
            stat -c %Y "$file" 2>/dev/null || echo 0
            ;;
    esac
}

# --- ログローテーション ---
# サイズ制限超過または保持期間を超えたログをローテーション

rotate_logs() {
    local workspace_id="$1"
    local log_dir="$WORKSPACE_BASE/$workspace_id/logs"

    if [ ! -d "$log_dir" ]; then
        return 0
    fi

    # 古いセッションログを検索して圧縮
    find "$log_dir/sessions" -name "*.log" -mtime +$LOG_RETENTION_DAYS 2>/dev/null | while read -r logfile; do
        if [ -f "$logfile" ] && [ ! -f "${logfile}.gz" ]; then
            gzip -f "$logfile" 2>/dev/null
        fi
    done

    # 非常に古い圧縮済みログを削除（保持期間の2倍）
    find "$log_dir/sessions" -name "*.log.gz" -mtime +$((LOG_RETENTION_DAYS * 2)) -delete 2>/dev/null

    # メインのアクティビティログが大きすぎる場合はローテーション
    local activity_log="$log_dir/subagent_activity.log"
    if [ -f "$activity_log" ]; then
        local size_kb=$(du -k "$activity_log" 2>/dev/null | cut -f1)
        local max_size_kb=$((MAX_LOG_SIZE_MB * 1024))

        if [ "${size_kb:-0}" -gt "$max_size_kb" ]; then
            # 最後の1000行を保持し、残りをアーカイブ
            local timestamp=$(date +%Y%m%d_%H%M%S)
            tail -n 1000 "$activity_log" > "${activity_log}.tmp"
            mv "$activity_log" "${activity_log}.${timestamp}"
            mv "${activity_log}.tmp" "$activity_log"
            gzip -f "${activity_log}.${timestamp}" 2>/dev/null
        fi
    fi
}

# --- 一時ファイルのクリーンアップ ---
# セッション中に作成された一時ファイルを削除

cleanup_temp_files() {
    local workspace_id="$1"
    local workspace_dir="$WORKSPACE_BASE/$workspace_id"

    if [ ! -d "$workspace_dir" ]; then
        return 0
    fi

    # .tmp ファイルを削除
    find "$workspace_dir" -name "*.tmp" -type f -delete 2>/dev/null

    # 空のディレクトリを削除（メインのワークスペースディレクトリは除く）
    find "$workspace_dir" -mindepth 1 -type d -empty -delete 2>/dev/null
}

# --- 古いワークスペースのアーカイブ ---
# 長期間更新されていないワークスペースをアーカイブ

archive_stale_workspaces() {
    if [ ! -d "$WORKSPACE_BASE" ]; then
        return 0
    fi

    local archive_dir="$WORKSPACE_BASE/.archive"

    # LOG_RETENTION_DAYS 日間更新されていないワークスペースを検索
    for workspace_dir in "$WORKSPACE_BASE"/*/; do
        [ -d "$workspace_dir" ] || continue

        local workspace_name=$(basename "$workspace_dir")

        # アーカイブディレクトリはスキップ
        [ "$workspace_name" = ".archive" ] && continue

        local progress_file="$workspace_dir/claude-progress.json"

        if [ -f "$progress_file" ]; then
            # 進捗ファイルが古いかチェック（クロスプラットフォーム mtime を使用）
            local file_mtime
            file_mtime=$(get_file_mtime "$progress_file")
            local file_age_days=$(( ($(date +%s) - file_mtime) / 86400 ))

            if [ "$file_age_days" -gt "$LOG_RETENTION_DAYS" ]; then
                # ステータスが completed かチェック（アーカイブしても安全）
                local status=""
                if command -v python3 &> /dev/null; then
                    status=$(PROGRESS_FILE_PATH="$progress_file" python3 -c "
import json
import os
try:
    with open(os.environ.get('PROGRESS_FILE_PATH', ''), 'r') as f:
        data = json.load(f)
    print(data.get('status', ''))
except:
    pass
" 2>/dev/null)
                fi

                # 完了済みのワークスペースのみアーカイブ
                if [ "$status" = "completed" ]; then
                    mkdir -p "$archive_dir"
                    local timestamp=$(date +%Y%m%d)
                    mv "$workspace_dir" "$archive_dir/${workspace_name}_${timestamp}" 2>/dev/null
                fi
            fi
        fi
    done
}

# --- メイン実行 ---

# 現在のワークスペース ID を取得
WORKSPACE_ID=""
if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)
fi

# 現在のワークスペースのクリーンアップを実行
if [ -n "$WORKSPACE_ID" ]; then
    rotate_logs "$WORKSPACE_ID"
    cleanup_temp_files "$WORKSPACE_ID"
fi

# 古いワークスペースのアーカイブ（定期的に実行、毎セッションではない）
# マーカーファイルが1日以上古い場合のみ実行
ARCHIVE_MARKER="$WORKSPACE_BASE/.last_archive_check"
MARKER_MTIME=$(get_file_mtime "$ARCHIVE_MARKER")
if [ ! -f "$ARCHIVE_MARKER" ] || [ $(( ($(date +%s) - MARKER_MTIME) / 86400 )) -gt 0 ]; then
    archive_stale_workspaces
    touch "$ARCHIVE_MARKER" 2>/dev/null
fi

# 正常終了（クリーンアップはベストエフォート）
exit 0
