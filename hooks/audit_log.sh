#!/bin/bash
# PostToolUse フック: ツール使用状況の監査ログ
# デバッグ、コンプライアンス、セッション分析のためにツール呼び出しを記録する
#
# PostToolUse フックは stdin で以下の JSON を受け取る:
# - tool_name: 実行されたツールの名前
# - tool_input: ツールに渡されたパラメータ
# - tool_response: ツールからの結果（切り詰められる場合あり）
# - session_id: 現在のセッション識別子
#
# 出力: セッション状態を変更するオプションの JSON

set -euo pipefail

# ワークスペースユーティリティを読み込み（パス解決用）
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# ログディレクトリの決定
LOG_DIR=""
WORKSPACE_ID=""

if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id 2>/dev/null || echo "")
fi

if [ -n "$WORKSPACE_ID" ]; then
    LOG_DIR=".claude/workspaces/$WORKSPACE_ID/logs"
else
    LOG_DIR=".claude/logs"
fi

# ログディレクトリが存在しない場合は作成
mkdir -p "$LOG_DIR" 2>/dev/null || true

# 日付でローテーションするログファイル
LOG_FILE="$LOG_DIR/tool-audit-$(date +%Y-%m-%d).jsonl"

# ログローテーションの設定
MAX_LOG_SIZE_BYTES=$((10 * 1024 * 1024))  # ログファイルあたり最大 10MB
MAX_LOG_FILES=7  # 7日分のログを保持

# --- ログローテーション ---
# サイズ制限を超えた場合にログファイルをローテーション
rotate_log_if_needed() {
    local log_file="$1"
    local max_size="$2"

    if [ ! -f "$log_file" ]; then
        return 0
    fi

    # ファイルサイズを取得（クロスプラットフォーム、POSIX 互換）
    local current_size
    case "$OSTYPE" in
        darwin*)
            current_size=$(stat -f%z "$log_file" 2>/dev/null || echo 0)
            ;;
        *)
            current_size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
            ;;
    esac

    if [ "$current_size" -gt "$max_size" ]; then
        local timestamp
        timestamp=$(date '+%H%M%S')
        local rotated_file="${log_file}.${timestamp}"

        # 現在のログをローテーション
        mv "$log_file" "$rotated_file" 2>/dev/null || return 1

        # gzip が利用可能な場合はローテーションしたファイルを圧縮
        if command -v gzip &> /dev/null; then
            gzip "$rotated_file" 2>/dev/null &
        fi
    fi
}

# 古い監査ログのクリーンアップ（MAX_LOG_FILES 日より古いもの）
cleanup_old_logs() {
    local log_dir="$1"
    if [ -d "$log_dir" ]; then
        find "$log_dir" -name "tool-audit-*.jsonl*" -mtime +$MAX_LOG_FILES -delete 2>/dev/null || true
    fi
}

# 書き込み前に必要に応じてローテーション
rotate_log_if_needed "$LOG_FILE" "$MAX_LOG_SIZE_BYTES"

# 定期的なクリーンアップ（オーバーヘッドを避けるため時々のみ実行）
CLEANUP_MARKER="$LOG_DIR/.last_audit_cleanup"
if [ ! -f "$CLEANUP_MARKER" ] || [ "$(find "$CLEANUP_MARKER" -mtime +1 2>/dev/null)" ]; then
    cleanup_old_logs "$LOG_DIR"
    touch "$CLEANUP_MARKER" 2>/dev/null || true
fi

# stdin から入力を読み取り
INPUT=$(cat)

# 入力が空の場合はログをスキップ
if [ -z "$INPUT" ]; then
    exit 0
fi

# Python を使用して信頼性の高い JSON パースでツール情報を抽出
# 環境変数を使用して入力を安全に渡す
if command -v python3 &> /dev/null; then
    AUDIT_INPUT="$INPUT" python3 -c "
import json
import os
import sys
from datetime import datetime

import re

# コマンド引数に含まれる可能性のあるシークレットのパターン
SECRET_PATTERNS = [
    # プロバイダー API キー（プレフィックス付き）
    (r'sk-ant-[a-zA-Z0-9_-]{20,}', '[ANTHROPIC_KEY_REDACTED]'),
    (r'sk-[a-zA-Z0-9]{20,}', '[OPENAI_KEY_REDACTED]'),
    (r'AKIA[0-9A-Z]{16}', '[AWS_ACCESS_KEY_REDACTED]'),
    (r'ghp_[a-zA-Z0-9]{36,}', '[GITHUB_TOKEN_REDACTED]'),
    (r'gho_[a-zA-Z0-9]{36,}', '[GITHUB_OAUTH_REDACTED]'),
    (r'glpat-[a-zA-Z0-9_-]{20,}', '[GITLAB_TOKEN_REDACTED]'),
    (r'xox[baprs]-[a-zA-Z0-9-]{10,}', '[SLACK_TOKEN_REDACTED]'),
    # Bearer/Authorization トークン
    (r'Bearer\s+[a-zA-Z0-9._-]{20,}', 'Bearer [TOKEN_REDACTED]'),
    (r'Authorization:\s*[^\s]{20,}', 'Authorization: [REDACTED]'),
    # 引数内のパスワード/シークレットの汎用パターン
    (r'(-[pP]|--password[=\s])[^\s]{8,}', r'\g<1>[PASSWORD_REDACTED]'),
    (r'(ANTHROPIC_API_KEY|OPENAI_API_KEY|AWS_SECRET_ACCESS_KEY|GITHUB_TOKEN)=[^\s]{10,}', r'\g<1>=[REDACTED]'),
    # パスワード付きデータベース接続文字列
    (r'(postgres|mysql|mongodb)://[^:]+:[^@]{8,}@', r'\g<1>://[USER]:[PASSWORD_REDACTED]@'),
    # シークレットの可能性がある汎用の高エントロピー文字列（64文字以上の16進数）
    (r'[\"\'][a-fA-F0-9]{64,}[\"\']', '\"[POSSIBLE_SECRET_REDACTED]\"'),
]

def redact_secrets_in_string(text):
    '''文字列から既知のシークレットパターンをマスクする'''
    if not isinstance(text, str):
        return text
    result = text
    for pattern, replacement in SECRET_PATTERNS:
        result = re.sub(pattern, replacement, result)
    return result

def truncate_input(data, max_len=200):
    '''機密データを公開せずにログ用に入力を切り詰める'''
    if isinstance(data, dict):
        result = {}
        for k, v in data.items():
            # 名前から判断して機密性の高いフィールドをスキップ
            if k.lower() in ('password', 'secret', 'token', 'key', 'credential', 'api_key'):
                result[k] = '[REDACTED]'
            elif isinstance(v, str):
                # まず文字列内のシークレットをマスク
                redacted = redact_secrets_in_string(v)
                # 必要に応じて切り詰め
                if len(redacted) > max_len:
                    result[k] = redacted[:max_len] + '...[truncated]'
                else:
                    result[k] = redacted
            else:
                result[k] = v
        return result
    elif isinstance(data, str):
        return redact_secrets_in_string(data)
    return data

try:
    input_data = os.environ.get('AUDIT_INPUT', '')
    if not input_data:
        sys.exit(0)

    data = json.loads(input_data)

    tool_name = data.get('tool_name', 'unknown')
    tool_input = data.get('tool_input', {})
    session_id = data.get('session_id', 'unknown')

    # 監査エントリを作成（容量節約のため tool_response は除外）
    audit_entry = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'session_id': session_id,
        'tool_name': tool_name,
        'tool_input_summary': truncate_input(tool_input)
    }

    print(json.dumps(audit_entry))

except json.JSONDecodeError:
    # 不正な JSON 入力 - ログをスキップし、失敗させない
    sys.exit(0)
except Exception as e:
    # その他のエラー - ログをスキップし、失敗させない
    sys.exit(0)
" 2>/dev/null >> "$LOG_FILE" || true
fi

# 常に正常終了 - 監査ログがツール実行をブロックしてはならない
exit 0
