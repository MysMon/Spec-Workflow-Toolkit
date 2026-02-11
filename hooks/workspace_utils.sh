#!/bin/bash
# マルチプロジェクト分離のためのワークスペースユーティリティ
# ワークスペース ID の生成とパス管理のための関数を提供
#
# 使用方法: 他のフックスクリプトでこのファイルを source する
#   source "$(dirname "$0")/workspace_utils.sh"

# ============================================================================
# ワークスペース ID 生成
# ============================================================================

# Git ブランチと作業ディレクトリに基づいてユニークなワークスペース ID を生成
# 形式: {branch}_{path-hash}
# 例: main_a1b2c3d4, feature-auth_e5f6g7h8
#
# これにより以下を保証:
# - 同じリポジトリの異なるワークツリーが異なる ID を取得
# - 異なるブランチの同じディレクトリが異なる ID を取得
# - 人間が識別しやすいブランチ名
get_workspace_id() {
    local branch=""
    local path_hash=""

    # 現在の Git ブランチを取得（ファイルシステム安全のためサニタイズ）
    # 英数字、ドット、アンダースコア、ハイフン以外の全文字を除去
    if git rev-parse --git-dir > /dev/null 2>&1; then
        branch=$(git branch --show-current 2>/dev/null | tr '/' '-' | tr ' ' '-' | tr -dc 'a-zA-Z0-9._-')
        # デタッチ状態の場合は HEAD にフォールバック
        if [ -z "$branch" ]; then
            branch="detached-$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
        fi
        # ファイルシステム互換性のためブランチ名の長さを制限（最大50文字）
        branch=$(echo "$branch" | cut -c1-50)
    else
        branch="no-git"
    fi

    # 絶対作業ディレクトリパスのハッシュを生成
    # クロスプラットフォーム互換性のため md5sum を使用
    if command -v md5sum &> /dev/null; then
        # Linux: md5sum は "hash  filename" を出力、ハッシュ部分のみ抽出
        path_hash=$(pwd | md5sum | awk '{print $1}' | cut -c1-8)
    elif command -v md5 &> /dev/null; then
        # macOS: md5 はハッシュのみを出力（または -r で "MD5 (...) = hash"）
        path_hash=$(pwd | md5 | awk '{print $NF}' | cut -c1-8)
    else
        # フォールバック: 単純なハッシュを使用
        path_hash=$(pwd | cksum | awk '{print $1}' | head -c8)
    fi

    echo "${branch}_${path_hash}"
}

# ============================================================================
# パス管理
# ============================================================================

# ワークスペースディレクトリパスを取得
# 戻り値: .claude/workspaces/{workspace-id}/
get_workspace_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo ".claude/workspaces/${workspace_id}"
}

# 現在のワークスペースの進捗ファイルパスを取得
# 戻り値: .claude/workspaces/{workspace-id}/claude-progress.json
get_progress_file() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_workspace_dir "$workspace_id")/claude-progress.json"
}

# 現在のワークスペースのフィーチャーリストファイルパスを取得
# 戻り値: .claude/workspaces/{workspace-id}/feature-list.json
get_feature_file() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_workspace_dir "$workspace_id")/feature-list.json"
}

# 現在のワークスペースのセッション状態ファイルパスを取得
# 戻り値: .claude/workspaces/{workspace-id}/session-state.json
get_session_state_file() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_workspace_dir "$workspace_id")/session-state.json"
}

# 現在のワークスペースのログディレクトリを取得
# 戻り値: .claude/workspaces/{workspace-id}/logs/
get_logs_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_workspace_dir "$workspace_id")/logs"
}

# 現在のワークスペースのサブエージェントアクティビティログパスを取得
# 戻り値: .claude/workspaces/{workspace-id}/logs/subagent_activity.log
get_subagent_log() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_logs_dir "$workspace_id")/subagent_activity.log"
}

# 現在のワークスペースのセッションディレクトリを取得
# 戻り値: .claude/workspaces/{workspace-id}/logs/sessions/
get_sessions_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_logs_dir "$workspace_id")/sessions"
}

# ============================================================================
# ワークスペース管理
# ============================================================================

# ワークスペースのディレクトリ構造が存在することを確認
# 作成: .claude/workspaces/{workspace-id}/logs/sessions/
ensure_workspace_exists() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local workspace_dir="$(get_workspace_dir "$workspace_id")"
    local logs_dir="$(get_logs_dir "$workspace_id")"
    local sessions_dir="$(get_sessions_dir "$workspace_id")"

    mkdir -p "$workspace_dir"
    mkdir -p "$logs_dir"
    mkdir -p "$sessions_dir"
}

# 現在のプロジェクト内の全ワークスペースを一覧表示
# 戻り値: ワークスペース ID のリスト（1行に1つ）
list_workspaces() {
    local workspaces_dir=".claude/workspaces"
    if [ -d "$workspaces_dir" ]; then
        ls -1 "$workspaces_dir" 2>/dev/null
    fi
}

# ワークスペースに進捗ファイルがあるかチェック
# 戻り値: 進捗がある場合 0、ない場合 1
workspace_has_progress() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local progress_file="$(get_progress_file "$workspace_id")"
    [ -f "$progress_file" ]
}

# ワークスペースメタデータを取得（表示用）
# 戻り値: ワークスペース情報の JSON
# 環境変数を使用して Python にデータを安全に渡す
get_workspace_info() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local progress_file="$(get_progress_file "$workspace_id")"
    local feature_file="$(get_feature_file "$workspace_id")"

    if [ -f "$progress_file" ] && command -v python3 &> /dev/null; then
        WORKSPACE_ID_VAR="$workspace_id" \
        PROGRESS_FILE_VAR="$progress_file" \
        FEATURE_FILE_VAR="$feature_file" \
        python3 << 'PYEOF'
import json
import os

workspace_id = os.environ.get('WORKSPACE_ID_VAR', '')
progress_file = os.environ.get('PROGRESS_FILE_VAR', '')
feature_file = os.environ.get('FEATURE_FILE_VAR', '')

info = {
    "workspaceId": workspace_id,
    "hasProgress": os.path.exists(progress_file) if progress_file else False,
    "hasFeatures": os.path.exists(feature_file) if feature_file else False
}

if progress_file and os.path.exists(progress_file):
    try:
        with open(progress_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        info["project"] = data.get("project", "unknown")
        info["status"] = data.get("status", "unknown")
        info["lastUpdated"] = data.get("lastUpdated", "unknown")
        ctx = data.get("resumptionContext", {})
        info["position"] = ctx.get("position", "unknown")
    except Exception:
        pass  # 読み取り失敗時は部分的な情報を返す

print(json.dumps(info, indent=2))
PYEOF
    else
        echo "{\"workspaceId\": \"$workspace_id\", \"hasProgress\": false}"
    fi
}

# ============================================================================
# セッション管理
# ============================================================================

# セッション ID を生成（タイムスタンプ + ランダムサフィックス）
generate_session_id() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local random_suffix=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n' | head -c4)
    echo "${timestamp}_${random_suffix}"
}

# 現在のセッション ID を取得または作成
# セッション内の一貫性のために環境変数に保存
get_session_id() {
    if [ -z "$CLAUDE_SESSION_ID" ]; then
        export CLAUDE_SESSION_ID="$(generate_session_id)"
    fi
    echo "$CLAUDE_SESSION_ID"
}

# セッションログファイルを作成
# 戻り値: セッションログファイルのパス
get_session_log() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local session_id="${2:-$(get_session_id)}"
    local sessions_dir="$(get_sessions_dir "$workspace_id")"

    ensure_workspace_exists "$workspace_id"
    echo "${sessions_dir}/${session_id}.log"
}

# ============================================================================
# インサイト管理（フォルダベースアーキテクチャ）
# ============================================================================
#
# ディレクトリ構造:
#   .claude/workspaces/{id}/insights/
#   ├── pending/    # レビュー待ちの新規インサイト（1インサイト1JSONファイル）
#   ├── applied/    # CLAUDE.md またはルールに適用済み
#   ├── rejected/   # ユーザーが却下
#   └── archive/    # 参照用の古いインサイト

# 現在のワークスペースのインサイトベースディレクトリを取得
# 戻り値: .claude/workspaces/{workspace-id}/insights/
get_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_workspace_dir "$workspace_id")/insights"
}

# 保留中のインサイトディレクトリを取得（フォルダベース）
# 戻り値: .claude/workspaces/{workspace-id}/insights/pending/
get_pending_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_insights_dir "$workspace_id")/pending"
}

# 適用済みインサイトディレクトリを取得
# 戻り値: .claude/workspaces/{workspace-id}/insights/applied/
get_applied_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_insights_dir "$workspace_id")/applied"
}

# 却下済みインサイトディレクトリを取得
# 戻り値: .claude/workspaces/{workspace-id}/insights/rejected/
get_rejected_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_insights_dir "$workspace_id")/rejected"
}

# アーカイブインサイトディレクトリを取得
# 戻り値: .claude/workspaces/{workspace-id}/insights/archive/
get_archive_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_insights_dir "$workspace_id")/archive"
}

# 非推奨: 後方互換性のためのみ
# 戻り値: 空文字列（非推奨 - 代わりに get_pending_insights_dir を使用）
get_pending_insights_file() {
    echo ""
}

# 非推奨: 後方互換性のためのみ
get_approved_insights_file() {
    echo ""
}

# ワークスペース ID を検証してパストラバーサルとインジェクションを防止
# 戻り値: 有効な場合 0、無効な場合 1
# 使用方法: validate_workspace_id "workspace-id" || exit 1
# 注: bash/zsh の移植性のため POSIX 互換の case 文を使用
validate_workspace_id() {
    local id="$1"

    # 空でないことが必須
    if [ -z "$id" ]; then
        return 1
    fi

    # 許可された文字のみに一致すること（英数字、ドット、アンダースコア、ハイフン）
    # POSIX 互換のため case を使用（bash, zsh, sh で動作）
    case "$id" in
        *[!a-zA-Z0-9._-]*) return 1 ;;
    esac

    # パストラバーサルシーケンスを含まないこと
    case "$id" in
        *".."*) return 1 ;;
    esac

    # ドット（隠しファイル）またはハイフン（オプションインジェクション）で始まらないこと
    case "$id" in
        .*|-*) return 1 ;;
    esac

    # 長さチェック（妥当な制限）
    if [ ${#id} -gt 100 ]; then
        return 1
    fi

    # 追加セキュリティ: 解決済みパスが期待するディレクトリ内に留まることを検証
    # シンボリックリンクによるエスケープを防止
    local workspace_dir
    workspace_dir=".claude/workspaces/${id}"

    # ディレクトリが存在する場合のみチェック（作成は許可）
    if [ -e "$workspace_dir" ]; then
        local resolved_path
        resolved_path=$(realpath "$workspace_dir" 2>/dev/null)
        local base_dir
        base_dir=$(realpath ".claude/workspaces" 2>/dev/null)

        # 解決済みパスがベースディレクトリ配下であることを確認
        if [ -n "$resolved_path" ] && [ -n "$base_dir" ]; then
            case "$resolved_path" in
                "$base_dir"/*)
                    # パスは有効 - ベースディレクトリ配下
                    ;;
                *)
                    # パスがベースディレクトリから逃避（シンボリックリンク攻撃）
                    return 1
                    ;;
            esac
        fi
    fi

    return 0
}

# ワークスペースの保留中インサイト数をカウント（pending/ 内のファイル数）
# 戻り値: 保留中インサイト数（ない場合は 0）
count_pending_insights() {
    local workspace_id="${1:-$(get_workspace_id)}"

    # 外部から提供されたワークスペース ID を検証
    if [ -n "$1" ] && ! validate_workspace_id "$1"; then
        echo "0"
        return
    fi

    local pending_dir="$(get_pending_insights_dir "$workspace_id")"

    if [ -d "$pending_dir" ]; then
        # pending ディレクトリ内の .json ファイル数をカウント
        find "$pending_dir" -maxdepth 1 -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# ワークスペースに保留中のインサイトがあるかチェック
# 戻り値: 保留中インサイトがある場合 0、ない場合 1
workspace_has_pending_insights() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local count=$(count_pending_insights "$workspace_id")
    [ "$count" -gt 0 ]
}

# インサイトディレクトリ構造が存在することを確認
ensure_insights_dir() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local insights_dir="$(get_insights_dir "$workspace_id")"

    mkdir -p "$insights_dir/pending"
    mkdir -p "$insights_dir/applied"
    mkdir -p "$insights_dir/rejected"
    mkdir -p "$insights_dir/archive"
}

# 保留中のインサイトファイルを一覧表示
# 戻り値: インサイトファイルパスのリスト（1行に1つ）
list_pending_insights() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local pending_dir="$(get_pending_insights_dir "$workspace_id")"

    if [ -d "$pending_dir" ]; then
        find "$pending_dir" -maxdepth 1 -name "*.json" -type f 2>/dev/null | sort
    fi
}

# インサイトを別のステータスディレクトリに移動
# 使用方法: move_insight "insight-file-path" "applied|rejected|archive"
# セキュリティ: ソースパスが期待するインサイトディレクトリ内にあることを検証
move_insight() {
    local insight_file="$1"
    local target_status="$2"
    local workspace_id="${3:-$(get_workspace_id)}"

    if [ ! -f "$insight_file" ]; then
        echo "エラー: インサイトファイルが見つかりません: $insight_file" >&2
        return 1
    fi

    # セキュリティ: ソースファイルがインサイトディレクトリ内にあることを検証
    # パストラバーサルを防ぐため絶対パスに解決
    local resolved_source
    resolved_source=$(realpath "$insight_file" 2>/dev/null)
    if [ -z "$resolved_source" ]; then
        echo "エラー: パスを解決できませんでした: $insight_file" >&2
        return 1
    fi

    # ソースがインサイトディレクトリ内にあることを確認（pending, applied, rejected, archive）
    case "$resolved_source" in
        */insights/pending/*.json|*/insights/applied/*.json|*/insights/rejected/*.json|*/insights/archive/*.json)
            ;;
        *)
            echo "エラー: ソースパスが期待するインサイトディレクトリ内にありません: $resolved_source" >&2
            return 1
            ;;
    esac

    local insights_dir="$(get_insights_dir "$workspace_id")"
    local target_dir=""

    case "$target_status" in
        applied)  target_dir="$insights_dir/applied" ;;
        rejected) target_dir="$insights_dir/rejected" ;;
        archive)  target_dir="$insights_dir/archive" ;;
        *)
            echo "エラー: 無効なターゲットステータス: $target_status" >&2
            return 1
            ;;
    esac

    mkdir -p "$target_dir"

    local filename
    filename=$(basename "$insight_file")
    mv "$resolved_source" "$target_dir/$filename"
}

# 単一のインサイトファイルを読み取り JSON を出力
# 使用方法: read_insight "insight-file-path"
read_insight() {
    local insight_file="$1"

    if [ -f "$insight_file" ]; then
        cat "$insight_file"
    else
        echo "{}"
    fi
}

# ============================================================================
# ログ管理
# ============================================================================

# インサイトキャプチャログファイルパスを取得
# 戻り値: .claude/workspaces/{workspace-id}/insights/capture.log
get_insight_capture_log() {
    local workspace_id="${1:-$(get_workspace_id)}"
    echo "$(get_insights_dir "$workspace_id")/capture.log"
}

# サイズ制限を超えた場合にログファイルをローテーション
# 使用方法: rotate_log_if_needed "/path/to/log" 1048576  # 1MB
rotate_log_if_needed() {
    local log_file="$1"
    local max_size="${2:-1048576}"  # デフォルト 1MB
    local keep_count="${3:-5}"       # 最新の5つのローテーションを保持

    if [ ! -f "$log_file" ]; then
        return 0
    fi

    local current_size
    current_size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)

    if [ "$current_size" -gt "$max_size" ]; then
        local timestamp
        timestamp=$(date '+%Y%m%d_%H%M%S')
        local rotated_file="${log_file}.${timestamp}"

        # 現在のログをローテーション
        mv "$log_file" "$rotated_file" 2>/dev/null || return 1

        # gzip が利用可能な場合はローテーションしたファイルを圧縮
        if command -v gzip &> /dev/null; then
            gzip "$rotated_file" 2>/dev/null
        fi

        # keep_count を超えた古いローテーションを削除
        local pattern="${log_file}.*"
        # shellcheck disable=SC2086
        ls -t $pattern 2>/dev/null | tail -n +$((keep_count + 1)) | xargs rm -f 2>/dev/null
    fi
}

# ワークスペース内の一時ファイルをクリーンアップ
# 削除対象: .tmp ファイル、1時間以上経過した .lock ファイル、空ディレクトリ
cleanup_workspace_temp_files() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local workspace_dir="$(get_workspace_dir "$workspace_id")"

    if [ ! -d "$workspace_dir" ]; then
        return 0
    fi

    # .tmp ファイルを削除（中断されたアトミック書き込みの残り）
    find "$workspace_dir" -name "*.tmp" -type f -delete 2>/dev/null

    # 古い .lock ファイルを削除（1時間以上経過したもの）
    find "$workspace_dir" -name "*.lock" -type f -mmin +60 -delete 2>/dev/null

    # 空のディレクトリを削除（メインのワークスペースディレクトリは除く）
    find "$workspace_dir" -mindepth 1 -type d -empty -delete 2>/dev/null
}

# 処理済みの古いインサイトをアーカイブ
# applied/ と rejected/ のインサイトを archive/ ディレクトリに移動
# フォルダベース: ディレクトリ間で単純にファイルを移動
archive_processed_insights() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local insights_dir="$(get_insights_dir "$workspace_id")"
    local applied_dir="$insights_dir/applied"
    local rejected_dir="$insights_dir/rejected"
    local archive_dir="$insights_dir/archive"
    local archived_count=0

    # アーカイブディレクトリの存在を確認
    mkdir -p "$archive_dir"

    # 適用済みインサイトをアーカイブに移動
    if [ -d "$applied_dir" ]; then
        for file in "$applied_dir"/*.json 2>/dev/null; do
            [ -f "$file" ] || continue
            mv "$file" "$archive_dir/"
            archived_count=$((archived_count + 1))
        done
    fi

    # 却下済みインサイトをアーカイブに移動
    if [ -d "$rejected_dir" ]; then
        for file in "$rejected_dir"/*.json 2>/dev/null; do
            [ -f "$file" ] || continue
            mv "$file" "$archive_dir/"
            archived_count=$((archived_count + 1))
        done
    fi

    if [ "$archived_count" -gt 0 ]; then
        echo "処理済みインサイト $archived_count 件をアーカイブしました"
    fi
}

# ワークスペース統計を取得
# 戻り値: ディレクトリ別のインサイト数、ログ等を含む JSON
# フォルダベース: pending/, applied/, rejected/, archive/ ディレクトリのファイル数をカウント
get_workspace_stats() {
    local workspace_id="${1:-$(get_workspace_id)}"

    if ! command -v python3 &> /dev/null; then
        echo '{"error": "python3 が利用できません"}'
        return
    fi

    WORKSPACE_ID_VAR="$workspace_id" \
    WORKSPACE_DIR_VAR="$(get_workspace_dir "$workspace_id")" \
    INSIGHTS_DIR_VAR="$(get_insights_dir "$workspace_id")" \
    python3 << 'PYEOF'
import json
import os
import glob

workspace_id = os.environ.get('WORKSPACE_ID_VAR', '')
workspace_dir = os.environ.get('WORKSPACE_DIR_VAR', '')
insights_dir = os.environ.get('INSIGHTS_DIR_VAR', '')

def count_json_files(directory):
    """ディレクトリ内の .json ファイル数をカウント。"""
    if not directory or not os.path.isdir(directory):
        return 0
    return len(glob.glob(os.path.join(directory, '*.json')))

def get_dir_size(directory):
    """ディレクトリ内のファイルの合計サイズを取得。"""
    if not directory or not os.path.isdir(directory):
        return 0
    total = 0
    for f in glob.glob(os.path.join(directory, '*')):
        try:
            total += os.path.getsize(f)
        except OSError:
            pass
    return total

# 各ディレクトリのインサイト数をカウント（フォルダベースアーキテクチャ）
pending_count = count_json_files(os.path.join(insights_dir, 'pending')) if insights_dir else 0
applied_count = count_json_files(os.path.join(insights_dir, 'applied')) if insights_dir else 0
rejected_count = count_json_files(os.path.join(insights_dir, 'rejected')) if insights_dir else 0
archived_count = count_json_files(os.path.join(insights_dir, 'archive')) if insights_dir else 0

stats = {
    'workspaceId': workspace_id,
    'exists': os.path.isdir(workspace_dir) if workspace_dir else False,
    'insights': {
        'pending': pending_count,
        'applied': applied_count,
        'rejected': rejected_count,
        'archived': archived_count,
        'total': pending_count + applied_count + rejected_count + archived_count
    },
    'storage': {
        'insightsSize': get_dir_size(insights_dir) if insights_dir else 0,
        'logFiles': 0,
        'totalSize': 0
    }
}

if workspace_dir and os.path.isdir(workspace_dir):
    # ストレージをカウント
    total_size = 0
    log_count = 0
    for root, dirs, files in os.walk(workspace_dir):
        for f in files:
            fpath = os.path.join(root, f)
            try:
                total_size += os.path.getsize(fpath)
                if f.endswith('.log') or f.endswith('.jsonl'):
                    log_count += 1
            except OSError:
                pass
    stats['storage']['totalSize'] = total_size
    stats['storage']['logFiles'] = log_count

print(json.dumps(stats, indent=2))
PYEOF
}

# ============================================================================
# ユーティリティ関数
# ============================================================================

# ユーザー表示用にワークスペース情報を整形出力
print_workspace_info() {
    local workspace_id="${1:-$(get_workspace_id)}"
    local workspace_dir="$(get_workspace_dir "$workspace_id")"

    echo "ワークスペース ID: $workspace_id"
    echo "ワークスペースディレクトリ: $workspace_dir"
    echo "ブランチ: $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo "作業ディレクトリ: $(pwd)"

    if workspace_has_progress "$workspace_id"; then
        echo "ステータス: 進捗ファイルあり"
    else
        echo "ステータス: 進捗ファイルなし"
    fi

    # インサイト統計を表示（利用可能な場合）
    if workspace_has_pending_insights "$workspace_id"; then
        local count
        count=$(count_pending_insights "$workspace_id")
        echo "保留中のインサイト: $count"
    fi
}
