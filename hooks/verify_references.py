#!/usr/bin/env python3
"""
参照検証フック - SubagentStop イベントハンドラ
サブエージェント出力の file:line 参照を検証し、ハルシネーションされたコード位置を検出する。

入力: stdin からの JSON メタデータ（agent_transcript_path（推奨）または transcript_path で JSONL ファイルを指定）
出力:
  - 30% 超の参照が無効な場合: exit 0 で JSON {"decision": "block", "reason": "..."}（SubagentStop 制御）
  - それ以外: exit 0 で JSON {"systemMessage": "..."}（検証サマリーを含む）

一致する参照パターン:
  - file.ts:123
  - path/to/file.py:45
  - src/components/Button.tsx:100
  - /absolute/path/file.js:200
"""

import sys
import re
import json
import os
from typing import List, Dict, Tuple, Optional

# =============================================================================
# 設定
# =============================================================================

# 無効な参照のしきい値（パーセンテージ）
INVALID_THRESHOLD = 30

# トランスクリプト処理の最大ファイルサイズ（100MB）
MAX_TRANSCRIPT_SIZE = 100 * 1024 * 1024

# チェックする参照の最大数（パフォーマンス制限）
MAX_REFERENCES_TO_CHECK = 500

# 参照パターン - file:line パターンに一致
# キャプチャ: ファイル名（オプションのパス付き）、行番号
REFERENCE_PATTERN = re.compile(
    r'(?:^|[\s\(\[\{`\'"])' +                    # 文字列の先頭またはデリミタ
    r'(' +                                        # キャプチャグループ開始
    r'(?:[a-zA-Z0-9_\-./]+/)?' +                 # オプションのパスプレフィックス
    r'[a-zA-Z0-9_\-]+' +                         # ファイル名のベース部分
    r'\.[a-zA-Z0-9]+' +                          # ファイル拡張子
    r')' +                                        # ファイル名キャプチャ終了
    r':(\d+)' +                                   # コロンと行番号
    r'(?:$|[\s\)\]\}`\'",:])',                   # 文字列の末尾またはデリミタ
    re.MULTILINE
)

# =============================================================================
# パス検証
# =============================================================================

def validate_transcript_path(path: str) -> Tuple[bool, str, str]:
    """
    transcript_path のセキュリティ検証。

    戻り値: (is_valid, error_message, resolved_path)
    """
    if not path:
        return False, "パスが空です", ""

    expanded = os.path.expanduser(path)

    try:
        resolved = os.path.realpath(expanded)
    except (OSError, ValueError) as e:
        return False, f"パスの解決に失敗: {e}", ""

    # パストラバーサルをチェック
    if '..' in path:
        return False, "パストラバーサルを検出", ""

    # 期待される Claude ディレクトリパターンをチェック
    valid_patterns = ['/.claude/', '/claude-code/', '/tmp/claude']
    path_lower = resolved.lower()

    if not any(pattern in path_lower for pattern in valid_patterns):
        return False, "期待される Claude ディレクトリに含まれていないパス", ""

    return True, "", resolved

# =============================================================================
# トランスクリプトパース
# =============================================================================

def extract_assistant_content(resolved_path: str, max_size: int) -> Tuple[str, bool]:
    """
    JSONL トランスクリプトからアシスタントメッセージの内容を抽出。

    戻り値: (content, was_skipped_due_to_size)
    """
    content_parts = []

    try:
        # ファイルサイズをチェック
        try:
            file_size = os.path.getsize(resolved_path)
            if file_size > max_size:
                return '', True
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
# 参照の抽出と検証
# =============================================================================

def extract_references(text: str) -> List[Dict[str, any]]:
    """
    テキストから file:line 参照を抽出。

    'file' と 'line' キーを持つ辞書のリストを返す。
    """
    references = []
    seen = set()

    matches = REFERENCE_PATTERN.findall(text)

    for filepath, line_str in matches:
        if len(references) >= MAX_REFERENCES_TO_CHECK:
            break

        # 明らかにファイルでないパターンをスキップ
        if filepath.startswith('http://') or filepath.startswith('https://'):
            continue
        if filepath.startswith('node_modules/'):
            continue
        if '::' in filepath:  # C++ のスコープ解決
            continue

        try:
            line_num = int(line_str)
        except ValueError:
            continue

        # 重複排除
        key = (filepath, line_num)
        if key in seen:
            continue
        seen.add(key)

        references.append({
            'file': filepath,
            'line': line_num
        })

    return references


def resolve_file_path(reference_path: str) -> Optional[str]:
    """
    参照パスをディスク上の実際のファイルに解決。
    複数の戦略でファイルを検索。

    戻り値: 解決された絶対パス、見つからない場合は None
    """
    # 戦略1: 絶対パス
    if os.path.isabs(reference_path):
        if os.path.isfile(reference_path):
            return reference_path
        return None

    # 戦略2: カレントワーキングディレクトリからの相対パス
    cwd = os.getcwd()
    cwd_path = os.path.join(cwd, reference_path)
    if os.path.isfile(cwd_path):
        return os.path.abspath(cwd_path)

    # 戦略3: 一般的なプロジェクトルートを検索
    project_roots = [
        cwd,
        os.path.join(cwd, 'src'),
        os.path.join(cwd, 'lib'),
        os.path.join(cwd, 'app'),
    ]

    for root in project_roots:
        candidate = os.path.join(root, reference_path)
        if os.path.isfile(candidate):
            return os.path.abspath(candidate)

    return None


def get_file_line_count(filepath: str) -> int:
    """
    ファイルの行数を取得。

    戻り値: 行数、エラー時は -1
    """
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            return sum(1 for _ in f)
    except (IOError, OSError):
        return -1


def validate_reference(ref: Dict[str, any]) -> Dict[str, any]:
    """
    単一の file:line 参照を検証。

    検証結果の辞書を返す。
    """
    filepath = ref['file']
    line_num = ref['line']

    result = {
        'file': filepath,
        'line': line_num,
        'valid': False,
        'reason': None
    }

    # ファイルパスを解決
    resolved = resolve_file_path(filepath)

    if resolved is None:
        result['reason'] = 'file_not_found'
        return result

    # 行数をチェック
    total_lines = get_file_line_count(resolved)

    if total_lines < 0:
        result['reason'] = 'file_read_error'
        return result

    if line_num > total_lines:
        result['reason'] = f'line_exceeds_file_length（ファイルは {total_lines} 行）'
        return result

    if line_num < 1:
        result['reason'] = 'invalid_line_number'
        return result

    result['valid'] = True
    result['resolved_path'] = resolved
    return result

# =============================================================================
# メイン
# =============================================================================

def main():
    # stdin からフック入力を読み取り
    try:
        input_data = sys.stdin.read().strip()
    except Exception as e:
        sys.stderr.write(f"verify_references: stdin の読み取りに失敗: {e}\n")
        sys.exit(0)  # デフォルトで許可

    if not input_data:
        sys.exit(0)  # デフォルトで許可

    # フックメタデータをパース
    try:
        metadata = json.loads(input_data)
    except json.JSONDecodeError:
        sys.stderr.write("verify_references: 無効な JSON 入力\n")
        sys.exit(0)  # デフォルトで許可

    # 無限ループを防ぐため stop_hook_active をチェック
    if metadata.get('stop_hook_active', False):
        sys.exit(0)  # デフォルトで許可

    # トランスクリプトパスを取得
    # agent_transcript_path（サブエージェント自身のトランスクリプト）を transcript_path（メインセッション）より優先
    transcript_path = metadata.get('agent_transcript_path', '') or metadata.get('transcript_path', '')
    if not transcript_path:
        sys.exit(0)  # デフォルトで許可

    # トランスクリプトパスを検証
    is_valid, error_msg, resolved_path = validate_transcript_path(transcript_path)
    if not is_valid:
        sys.stderr.write(f"verify_references: 無効なパス - {error_msg}\n")
        sys.exit(0)  # デフォルトで許可

    # トランスクリプトからコンテンツを抽出
    content, was_size_skipped = extract_assistant_content(resolved_path, MAX_TRANSCRIPT_SIZE)
    if was_size_skipped:
        print(json.dumps({
            "systemMessage": "verify_references: トランスクリプトが大きすぎるため、検証をスキップします"
        }))
        sys.exit(0)

    if not content:
        sys.exit(0)  # デフォルトで許可

    # コンテンツから参照を抽出
    references = extract_references(content)

    if not references:
        # 参照が見つからない、検証するものなし
        sys.exit(0)  # デフォルトで許可

    # 各参照を検証
    results = []
    for ref in references:
        result = validate_reference(ref)
        results.append(result)

    # 統計を計算
    total = len(results)
    valid_count = sum(1 for r in results if r['valid'])
    invalid_count = total - valid_count
    invalid_percentage = (invalid_count / total * 100) if total > 0 else 0

    # 無効な参照のサマリーを構築
    invalid_refs = [r for r in results if not r['valid']]

    # しきい値をチェック
    if invalid_percentage > INVALID_THRESHOLD:
        # 詳細なエラーメッセージを構築
        error_details = []
        for ref in invalid_refs[:10]:  # 最初の10件の無効な参照を表示
            error_details.append(f"  - {ref['file']}:{ref['line']} ({ref['reason']})")

        remaining = len(invalid_refs) - 10
        if remaining > 0:
            error_details.append(f"  ... 他 {remaining} 件")

        error_message = (
            f"参照検証に失敗: file:line 参照の {invalid_percentage:.1f}% が無効です "
            f"({invalid_count}/{total})。\n"
            f"無効な参照:\n" + "\n".join(error_details) + "\n"
            f"コード位置を参照する前に検証してください。"
        )

        sys.stderr.write(f"verify_references: {error_message}\n")

        # SubagentStop は exit 0 で decision control を使用（exit 2 は PreToolUse 用）
        print(json.dumps({
            "decision": "block",
            "reason": error_message
        }))
        sys.exit(0)

    # 成功 - systemMessage 経由でサマリーを出力
    if invalid_count > 0:
        summary = (
            f"参照検証: {valid_count}/{total} 件の参照が有効 "
            f"({invalid_count} 件が無効、{invalid_percentage:.1f}% - {INVALID_THRESHOLD}% しきい値未満)"
        )
    else:
        summary = f"参照検証: 全 {total} 件の file:line 参照の検証に成功しました"

    print(json.dumps({
        "systemMessage": summary
    }))
    sys.exit(0)


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        # 重要: 例外時はフェイルクローズド - ハルシネーションの可能性がある
        # 参照を検証なしで通過させない
        sys.stderr.write(f"verify_references 致命的エラー: {e}\n")
        print(json.dumps({
            "decision": "block",
            "reason": f"エラーにより参照検証に失敗: {e}。サブエージェント出力にハルシネーションされた参照が含まれている可能性があります。"
        }))
        sys.exit(0)
