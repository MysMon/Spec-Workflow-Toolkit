#!/bin/bash
# インサイトキャプチャフック: サブエージェント出力からインサイトを抽出・保存
# SubagentStop 時に実行され、マーク付きインサイトをキャプチャする
#
# フォルダベースアーキテクチャ（ファイルロック不要）
#
# SubagentStop フック入力形式（Claude Code から）:
#   {
#     "session_id": "...",
#     "transcript_path": "~/.claude/projects/.../xxx.jsonl",
#     "agent_transcript_path": "~/.claude/projects/.../subagents/agent-yyy.jsonl",
#     "agent_id": "yyy",
#     "agent_type": "Explore",
#     "permission_mode": "default",
#     "hook_event_name": "SubagentStop",
#     "stop_hook_active": true/false
#   }
#
# 注: agent_transcript_path はサブエージェント自身のトランスクリプト（インサイトキャプチャに推奨）。
#     transcript_path はメインセッションのトランスクリプト（フォールバック）。
#
# アーキテクチャ:
#   各インサイトは pending/ ディレクトリに個別ファイルとして保存される。
#   これによりファイルロックが不要になり、操作がアトミックになる。
#
#   .claude/workspaces/{id}/insights/
#   ├── pending/          # レビュー待ちの新規インサイト
#   │   ├── INS-xxx.json
#   │   └── INS-yyy.json
#   ├── applied/          # CLAUDE.md またはルールに適用済み
#   ├── rejected/         # ユーザーが却下
#   └── archive/          # 参照用の古いインサイト
#
# 利点:
#   - ファイルロック不要（各ファイルがユニーク）
#   - アトミックな書き込み（単一ファイル作成）
#   - 部分障害に対する耐性（一つの破損ファイルが他に影響しない）
#   - 簡単なクリーンアップ（ファイルを削除するだけ）
#   - キャプチャとレビューの並行実行が競合なし
#
# インサイトマーカー（大文字小文字不問）:
#   INSIGHT: <テキスト>      - 一般的な学習や発見
#   LEARNED: <テキスト>      - 経験から学んだこと
#   DECISION: <テキスト>     - 行われた重要な決定
#   PATTERN: <テキスト>      - 発見された再利用可能なパターン
#   ANTIPATTERN: <テキスト>  - 避けるべきパターン

set -euo pipefail

# 設定
readonly MAX_INSIGHT_LENGTH=10000
readonly MAX_TRANSCRIPT_SIZE=$((100 * 1024 * 1024))  # 100MB
readonly MAX_INSIGHTS_PER_CAPTURE=100  # レート制限: キャプチャあたりの最大インサイト数

# ワークスペースユーティリティを読み込み
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/workspace_utils.sh" ]; then
    source "$SCRIPT_DIR/workspace_utils.sh"
else
    echo "insight_capture: workspace_utils.sh が見つかりません、スキップします" >&2
    echo '{"continue": true}'
    exit 0
fi

# フック入力を読み取り（JSON メタデータ、サブエージェント出力ではない）
INPUT=$(cat)

# 入力が空の場合は早期終了
if [ -z "$INPUT" ]; then
    echo '{"continue": true}'
    exit 0
fi

# ワークスペース固有のパスを取得
WORKSPACE_ID=$(get_workspace_id)
INSIGHTS_BASE=".claude/workspaces/$WORKSPACE_ID/insights"
PENDING_DIR="$INSIGHTS_BASE/pending"

# ディレクトリの存在を確認
mkdir -p "$PENDING_DIR"
mkdir -p "$INSIGHTS_BASE/applied"
mkdir -p "$INSIGHTS_BASE/rejected"
mkdir -p "$INSIGHTS_BASE/archive"

# Python によるメイン処理
WORKSPACE_ID_VAR="$WORKSPACE_ID" \
PENDING_DIR_VAR="$PENDING_DIR" \
AGENT_NAME_VAR="${CLAUDE_AGENT_NAME:-unknown}" \
HOOK_INPUT_VAR="$INPUT" \
MAX_INSIGHT_LENGTH_VAR="$MAX_INSIGHT_LENGTH" \
MAX_TRANSCRIPT_SIZE_VAR="$MAX_TRANSCRIPT_SIZE" \
MAX_INSIGHTS_PER_CAPTURE_VAR="$MAX_INSIGHTS_PER_CAPTURE" \
python3 << 'PYEOF'
"""
インサイトキャプチャエンジン - フォルダベースアーキテクチャ

主要な設計原則:
- 各インサイトは個別ファイル（ロック不要）
- ファイル作成は本質的にアトミック
- キャプチャとレビューの並行実行が競合なし
- よりシンプルで堅牢な実装
"""

import json
import sys
import re
import os
import uuid
import hashlib
from datetime import datetime
from typing import List, Dict, Optional, Tuple, Any

# =============================================================================
# 設定
# =============================================================================

class Config:
    def __init__(self):
        self.workspace_id = os.environ.get('WORKSPACE_ID_VAR', '')
        self.pending_dir = os.environ.get('PENDING_DIR_VAR', '')
        self.agent_name = os.environ.get('AGENT_NAME_VAR', 'unknown')
        self.hook_input = os.environ.get('HOOK_INPUT_VAR', '')
        self.max_insight_length = int(os.environ.get('MAX_INSIGHT_LENGTH_VAR', '10000'))
        self.max_transcript_size = int(os.environ.get('MAX_TRANSCRIPT_SIZE_VAR', str(100 * 1024 * 1024)))
        self.max_insights_per_capture = int(os.environ.get('MAX_INSIGHTS_PER_CAPTURE_VAR', '100'))
        self.markers = ['INSIGHT', 'LEARNED', 'DECISION', 'PATTERN', 'ANTIPATTERN']
        self.min_content_length = 11

# =============================================================================
# パス検証
# =============================================================================

def validate_transcript_path(path: str) -> Tuple[bool, str, str]:
    """
    transcript_path のセキュリティ検証。

    戻り値: (is_valid, error_message, resolved_path)
    resolved_path は TOCTOU 攻撃を防ぐために読み取り時に使用する。
    """
    if not path:
        return False, "パスが空です", ""

    expanded = os.path.expanduser(path)

    try:
        resolved = os.path.realpath(expanded)
    except (OSError, ValueError) as e:
        return False, f"パスの解決に失敗: {e}", ""

    # 元の入力でパストラバーサルをチェック
    if '..' in path:
        return False, "パストラバーサルを検出", ""

    # 期待される Claude ディレクトリパターンをチェック
    # セキュリティ: 有効なパターンに一致しないパスは存在に関わらず常に拒否
    valid_patterns = ['/.claude/', '/claude-code/', '/tmp/claude']
    path_lower = resolved.lower()

    if not any(pattern in path_lower for pattern in valid_patterns):
        return False, "期待される Claude ディレクトリに含まれていないパス", ""

    # TOCTOU を防ぐために解決済みパスを返す
    return True, "", resolved

# =============================================================================
# JSONL パース
# =============================================================================

def extract_assistant_content(resolved_path: str, max_size: int) -> Tuple[str, bool]:
    """
    JSONL トランスクリプトからアシスタントメッセージの内容を抽出。

    引数:
        resolved_path: 検証済みの解決済み絶対パス（validate_transcript_path から）
        max_size: 処理する最大ファイルサイズ

    戻り値:
        (content, was_skipped_due_to_size) のタプル
    """
    content_parts = []

    try:
        # ファイルサイズをチェック - 解決済みパスを直接使用（検証済み）
        try:
            file_size = os.path.getsize(resolved_path)
            if file_size > max_size:
                size_mb = file_size / (1024 * 1024)
                max_mb = max_size / (1024 * 1024)
                sys.stderr.write(
                    f"insight_capture: トランスクリプトが大きすぎます ({size_mb:.1f}MB > {max_mb:.1f}MB 制限)、スキップします\n"
                )
                return '', True  # サイズスキップを示すフラグを返す
        except OSError:
            pass

        with open(resolved_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue

                try:
                    entry = json.loads(line)
                    if entry.get('role') != 'assistant':
                        continue

                    content = entry.get('content', '')
                    if isinstance(content, str):
                        if content:
                            content_parts.append(content)
                    elif isinstance(content, list):
                        for block in content:
                            if isinstance(block, dict) and block.get('type') == 'text':
                                text = block.get('text', '')
                                if text:
                                    content_parts.append(text)
                            elif isinstance(block, str):
                                content_parts.append(block)
                except json.JSONDecodeError:
                    continue

    except (FileNotFoundError, PermissionError, IOError):
        pass

    return '\n'.join(content_parts), False

# =============================================================================
# インサイト抽出（ステートマシン）
# =============================================================================

def extract_insights(text: str, agent_name: str, config: Config) -> List[Dict[str, Any]]:
    """ステートマシンアプローチとコードブロックフィルタリングでインサイトを抽出。"""
    if not text:
        return []

    # 前処理: コードブロックとインラインコードを除去
    text_filtered = re.sub(r'```[\s\S]*?```', '\n', text)
    text_filtered = re.sub(r'`[^`\n]+`', '', text_filtered)

    # マーカー正規表現を構築
    marker_re = re.compile(
        r'^[ \t]*(' + '|'.join(config.markers) + r'):[ \t]*(.*)$',
        re.IGNORECASE
    )

    insights = []
    seen_hashes = set()
    timestamp = datetime.now().isoformat()

    current_marker = None
    current_content_lines = []
    rate_limit_reached = False

    for line in text_filtered.split('\n'):
        # レート制限: 最大インサイト数に達した場合は処理を停止
        if len(insights) >= config.max_insights_per_capture:
            if not rate_limit_reached:
                sys.stderr.write(
                    f"insight_capture: レート制限に到達 ({config.max_insights_per_capture} インサイト)\n"
                )
                rate_limit_reached = True
            break

        match = marker_re.match(line)

        if match:
            # 前のインサイトを保存
            if current_marker and current_content_lines:
                insight = create_insight(
                    current_marker, current_content_lines, timestamp,
                    agent_name, config, seen_hashes
                )
                if insight:
                    insights.append(insight)

            # 新しいインサイトを開始
            current_marker = match.group(1).upper()
            initial = match.group(2).strip()
            current_content_lines = [initial] if initial else []

        elif current_marker:
            stripped = line.strip()
            if stripped:
                current_content_lines.append(stripped)

    # 最後のインサイトを忘れずに（レート制限内であれば）
    if current_marker and current_content_lines and len(insights) < config.max_insights_per_capture:
        insight = create_insight(
            current_marker, current_content_lines, timestamp,
            agent_name, config, seen_hashes
        )
        if insight:
            insights.append(insight)

    return insights


def create_insight(
    marker: str,
    content_lines: List[str],
    timestamp: str,
    agent_name: str,
    config: Config,
    seen_hashes: set
) -> Optional[Dict[str, Any]]:
    """検証と重複排除を行いインサイトオブジェクトを作成。"""
    content = ' '.join(content_lines)
    content = re.sub(r'\\\s*', ' ', content)
    content = re.sub(r'\s+', ' ', content).strip()

    if len(content) < config.min_content_length:
        return None

    if len(content) > config.max_insight_length:
        content = content[:config.max_insight_length] + '... [truncated]'

    # 重複排除
    content_hash = hashlib.sha256(content.lower().encode()).hexdigest()[:16]
    if content_hash in seen_hashes:
        return None
    seen_hashes.add(content_hash)

    # ユニーク ID を生成
    insight_id = f"INS-{datetime.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:8]}"

    return {
        "id": insight_id,
        "timestamp": timestamp,
        "category": marker.lower(),
        "content": content,
        "source": agent_name,
        "status": "pending",
        "contentHash": content_hash,
        "workspaceId": config.workspace_id
    }

# =============================================================================
# ファイル操作（ロック不要！）
# =============================================================================

def save_insights_to_files(insights: List[Dict], pending_dir: str) -> int:
    """
    各インサイトを個別ファイルとして保存。

    ロックが不要な理由:
    1. 各ファイルがユニークな名前を持つ（UUID ベース）
    2. O_EXCL によるファイル作成はアトミック
    3. 一時ファイルに書き込んでからリネーム（POSIX ではアトミック）
    """
    saved_count = 0

    for insight in insights:
        insight_id = insight['id']
        file_path = os.path.join(pending_dir, f"{insight_id}.json")

        try:
            # アトミック書き込み: 同じディレクトリ内の一時ファイル → リネーム
            temp_path = file_path + '.tmp'

            with open(temp_path, 'w', encoding='utf-8') as f:
                json.dump(insight, f, indent=2, ensure_ascii=False)
                f.flush()
                os.fsync(f.fileno())

            os.replace(temp_path, file_path)
            saved_count += 1

        except Exception as e:
            sys.stderr.write(f"insight_capture: {insight_id} の保存に失敗: {e}\n")
            # 一時ファイルが存在する場合はクリーンアップ
            try:
                if os.path.exists(temp_path):
                    os.unlink(temp_path)
            except Exception:
                pass

    return saved_count

# =============================================================================
# メイン
# =============================================================================

def main():
    config = Config()

    if not config.hook_input or not config.pending_dir:
        print(json.dumps({"continue": True}))
        return

    # フック入力をパース
    try:
        metadata = json.loads(config.hook_input)
    except json.JSONDecodeError:
        print(json.dumps({"continue": True}))
        return

    # 無限ループ防止
    if metadata.get('stop_hook_active', False):
        print(json.dumps({"continue": True}))
        return

    # トランスクリプトパスを取得・検証
    # agent_transcript_path（サブエージェント自身のトランスクリプト）を transcript_path（メインセッション）より優先
    transcript_path = metadata.get('agent_transcript_path', '') or metadata.get('transcript_path', '')
    if not transcript_path:
        print(json.dumps({"continue": True}))
        return

    is_valid, error_msg, resolved_path = validate_transcript_path(transcript_path)
    if not is_valid:
        sys.stderr.write(f"insight_capture: 無効なパス - {error_msg}\n")
        print(json.dumps({"continue": True}))
        return

    # 解決済みパスを使用してコンテンツを抽出（TOCTOU 攻撃を防止）
    content, was_size_skipped = extract_assistant_content(resolved_path, config.max_transcript_size)
    if was_size_skipped:
        # トランスクリプトが大きすぎることをユーザーに通知
        max_mb = config.max_transcript_size / (1024 * 1024)
        print(json.dumps({
            "continue": True,
            "systemMessage": f"トランスクリプトが大きすぎます (>{max_mb:.0f}MB) - インサイトはキャプチャされませんでした。より小さなセッションに分割することを検討してください。"
        }))
        return
    if not content:
        print(json.dumps({"continue": True}))
        return

    # インサイトを抽出
    insights = extract_insights(content, config.agent_name, config)

    # 各インサイトを個別ファイルとして保存（ロック不要！）
    count = save_insights_to_files(insights, config.pending_dir)

    # 結果を出力
    if count > 0:
        print(json.dumps({
            "continue": True,
            "systemMessage": f"{count} 件のインサイトをキャプチャしました。評価するには /spec-workflow-toolkit:review-insights を実行してください。"
        }))
    else:
        print(json.dumps({"continue": True}))


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        sys.stderr.write(f"insight_capture 致命的エラー: {e}\n")
        print(json.dumps({"continue": True}))
PYEOF

exit 0
