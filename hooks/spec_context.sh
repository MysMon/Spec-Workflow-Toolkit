#!/bin/bash
# SessionStart フック: プラグインコンテキストの注入、進捗ファイルの検出、再開可能なワークフローのサポート
# セッション開始時に一度実行され、ユーザーのプロジェクトにプラグインコンテキストを提供する

# ワークスペースユーティリティを読み込み
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
fi

# --- ワークスペース検出 ---
WORKSPACE_ID=""
WORKSPACE_DIR=""
PROGRESS_FILE=""
FEATURE_FILE=""
RESUMPTION_INFO=""

# 現在のワークスペース ID とパスを取得
if command -v get_workspace_id &> /dev/null; then
    WORKSPACE_ID=$(get_workspace_id)
    WORKSPACE_DIR=$(get_workspace_dir "$WORKSPACE_ID")
    PROGRESS_FILE=$(get_progress_file "$WORKSPACE_ID")
    FEATURE_FILE=$(get_feature_file "$WORKSPACE_ID")
fi

# 進捗ファイルの存在を確認（存在しない場合はクリア）
if [ -n "$PROGRESS_FILE" ] && [ ! -f "$PROGRESS_FILE" ]; then
    PROGRESS_FILE=""
fi

# フィーチャーファイルの存在を確認（存在しない場合はクリア）
if [ -n "$FEATURE_FILE" ] && [ ! -f "$FEATURE_FILE" ]; then
    FEATURE_FILE=""
fi

# 進捗ファイルが存在する場合、再開コンテキストを抽出
if [ -n "$PROGRESS_FILE" ] && [ -f "$PROGRESS_FILE" ]; then
    # 基本ツールを使用して重要情報を抽出
    # 環境変数を使用してファイルパスを安全に Python に渡す
    if command -v python3 &> /dev/null; then
        RESUMPTION_INFO=$(PROGRESS_FILE_PATH="$PROGRESS_FILE" python3 -c "
import json
import os
import sys
try:
    progress_file = os.environ.get('PROGRESS_FILE_PATH', '')
    if not progress_file:
        sys.exit(0)
    with open(progress_file, 'r') as f:
        data = json.load(f)
    ctx = data.get('resumptionContext', {})
    status = data.get('status', 'unknown')
    current = data.get('currentTask', 'None')
    position = ctx.get('position', 'Not specified')
    next_action = ctx.get('nextAction', 'Not specified')
    blockers = ctx.get('blockers', [])
    workspace_id = data.get('workspaceId', 'Not set')

    print(f'ワークスペース: {workspace_id}')
    print(f'ステータス: {status}')
    print(f'現在のタスク: {current}')
    print(f'位置: {position}')
    print(f'次のアクション: {next_action}')
    if blockers:
        print(f\"ブロッカー: {', '.join(blockers)}\")
except Exception as e:
    print(f'進捗の読み取りエラー: {e}')
" 2>/dev/null)
    fi
fi

# フィーチャーファイルが存在する場合、フィーチャー進捗を抽出
# 環境変数を使用してファイルパスを安全に Python に渡す
FEATURE_PROGRESS=""
if [ -n "$FEATURE_FILE" ] && [ -f "$FEATURE_FILE" ]; then
    if command -v python3 &> /dev/null; then
        FEATURE_PROGRESS=$(FEATURE_FILE_PATH="$FEATURE_FILE" python3 -c "
import json
import os
try:
    feature_file = os.environ.get('FEATURE_FILE_PATH', '')
    if not feature_file:
        exit(0)
    with open(feature_file, 'r') as f:
        data = json.load(f)
    total = data.get('totalFeatures', len(data.get('features', [])))
    completed = data.get('completed', 0)
    features = data.get('features', [])

    # ステータスごとにカウント
    pending = sum(1 for f in features if f.get('status') == 'pending')
    in_progress = sum(1 for f in features if f.get('status') == 'in_progress')
    done = sum(1 for f in features if f.get('status') == 'completed')

    print(f'合計: {total} | 完了: {done} | 進行中: {in_progress} | 未着手: {pending}')

    # 現在進行中のフィーチャーを表示
    current = [f for f in features if f.get('status') == 'in_progress']
    if current:
        print(f\"現在: {current[0].get('name', 'Unknown')}\")
except Exception as e:
    print(f'エラー: {e}')
" 2>/dev/null)
    fi
fi

# 利用可能なワークスペースを一覧表示
AVAILABLE_WORKSPACES=""
if [ -d ".claude/workspaces" ]; then
    AVAILABLE_WORKSPACES=$(ls -1 ".claude/workspaces" 2>/dev/null | head -10)
fi

# --- ロールの決定（初期化 vs コーディング） ---
if [ -n "$PROGRESS_FILE" ] && [ -f "$PROGRESS_FILE" ]; then
    CURRENT_ROLE="CODING"
else
    CURRENT_ROLE="INITIALIZER"
fi

# --- コンテキスト出力（最小限） ---
echo "## Spec-Workflow Toolkit - セッション初期化完了"
echo ""

# --- ワークスペース情報 ---
if [ -n "$WORKSPACE_ID" ]; then
    echo "### 現在のワークスペース"
    echo ""
    echo "**ワークスペース ID**: \`$WORKSPACE_ID\`"
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$CURRENT_BRANCH" ]; then
        echo "**ブランチ**: \`$CURRENT_BRANCH\`"
    elif git rev-parse --git-dir > /dev/null 2>&1; then
        # Git リポジトリは存在するが HEAD がデタッチ状態
        echo "**ブランチ**: \`detached HEAD\`"
        echo ""
        echo "> **注意**: detached HEAD 状態です。適切なワークスペース分離のためにブランチをチェックアウトすることを検討してください。"
    else
        # Git リポジトリではない
        echo "**Git**: 未初期化"
        echo ""
        echo "> **注意**: これは Git リポジトリではありません。進捗追跡はディレクトリベースのワークスペース ID を使用します。完全な機能サポートのために \`git init\` の実行を検討してください。"
    fi
    echo "**作業ディレクトリ**: \`$(pwd)\`"
    echo ""
fi

# --- ロール別バナー（最小限） ---
if [ "$CURRENT_ROLE" = "CODING" ]; then
    echo "**ロール**: CODING（進捗ファイルを検出）"
else
    echo "**ロール**: INITIALIZER（進捗ファイルなし）"
fi
echo ""

# 注: オーケストレーターの詳細ルール、コンテキスト管理、コマンドリスト、スキルは
# CLAUDE.md で利用可能。利用可能なコマンドを確認するには `/help` を使用。

# --- 再開コンテキストの出力（利用可能な場合） ---
if [ -n "$PROGRESS_FILE" ] && [ -f "$PROGRESS_FILE" ]; then
    echo ""
    echo "### 再開可能な作業を検出"
    echo ""
    echo "**ワークスペース ID**: \`$WORKSPACE_ID\`"
    echo "**進捗ファイル**: \`$PROGRESS_FILE\`"
    if [ -n "$FEATURE_FILE" ] && [ -f "$FEATURE_FILE" ]; then
        echo "**フィーチャーファイル**: \`$FEATURE_FILE\`"
    fi
    echo ""
    if [ -n "$RESUMPTION_INFO" ]; then
        echo "**再開コンテキスト:**"
        echo "\`\`\`"
        echo "$RESUMPTION_INFO"
        echo "\`\`\`"
    fi
    if [ -n "$FEATURE_PROGRESS" ]; then
        echo ""
        echo "**フィーチャー進捗:**"
        echo "\`\`\`"
        echo "$FEATURE_PROGRESS"
        echo "\`\`\`"
    fi
    echo ""
    echo "再開するには: 進捗ファイルを読み取り、ドキュメントに記載された位置から続行してください。"
    echo ""
fi

# --- 複数ワークスペースがある場合の表示 ---
if [ -n "$AVAILABLE_WORKSPACES" ]; then
    WORKSPACE_COUNT=$(echo "$AVAILABLE_WORKSPACES" | wc -l)
    if [ "$WORKSPACE_COUNT" -gt 1 ]; then
        echo ""
        echo "### 利用可能なワークスペース"
        echo ""
        echo "複数のワークスペースが検出されました。詳細を確認するには \`/resume list\` を使用してください。"
        echo ""
        echo "\`\`\`"
        echo "$AVAILABLE_WORKSPACES"
        echo "\`\`\`"
        echo ""
    fi
fi

# --- 保留中のインサイトを確認 ---
if command -v count_pending_insights &> /dev/null && [ -n "$WORKSPACE_ID" ]; then
    PENDING_COUNT=$(count_pending_insights "$WORKSPACE_ID")
    if [ "$PENDING_COUNT" -gt 0 ]; then
        echo ""
        echo "### 保留中のインサイト"
        echo ""
        echo "前回のセッションでキャプチャされた **$PENDING_COUNT 件のインサイト** がレビュー待ちです。"
        echo ""
        echo "評価して適用するには \`/review-insights\` を実行してください。"
        echo ""
        # 最初の数件のインサイトのプレビューを表示（個別ファイルから読み取り）
        PENDING_DIR=$(get_pending_insights_dir "$WORKSPACE_ID")
        if [ -d "$PENDING_DIR" ] && command -v python3 &> /dev/null; then
            PREVIEW=$(PENDING_DIR_VAR="$PENDING_DIR" python3 << 'PYEOF'
import json
import os
import glob

pending_dir = os.environ.get('PENDING_DIR_VAR', '')
if not pending_dir or not os.path.isdir(pending_dir):
    exit(0)

try:
    # 最新の3件のインサイトファイルを取得（ファイル名にタイムスタンプを含むためソート）
    files = sorted(glob.glob(os.path.join(pending_dir, '*.json')), reverse=True)[:3]
    for i, filepath in enumerate(files, 1):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                ins = json.load(f)
            content = ins.get('content', '')[:60]
            if len(ins.get('content', '')) > 60:
                content += '...'
            category = ins.get('category', 'insight')
            print(f"  {i}. [{category}] {content}")
        except (json.JSONDecodeError, IOError):
            continue  # 破損ファイルをスキップ
except Exception:
    pass  # プレビュー表示でのサイレント失敗は許容される
PYEOF
)
            if [ -n "$PREVIEW" ]; then
                echo "**最近のインサイト:**"
                echo "$PREVIEW"
                echo ""
            fi
        fi
    fi
fi

# 明示的な終了
exit 0
