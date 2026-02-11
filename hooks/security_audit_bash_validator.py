#!/usr/bin/env python3
"""
security-auditor エージェント用の PreToolUse フック。
Bash コマンドが読み取り専用の監査コマンドのみであることを検証する。

適切なブロックのために JSON decision control（exit 0 + hookSpecificOutput）を使用。
このツールキットの他のフックと一貫した動作を保証。
"""

import json
import sys
import re


# 許可された読み取り専用の監査コマンド
ALLOWED_PATTERNS = [
    # 依存関係の監査
    r'^npm\s+audit',
    r'^yarn\s+audit',
    r'^pip-audit',
    r'^safety\s+check',
    r'^govulncheck',
    r'^cargo\s+audit',
    r'^bundle\s+audit',
    r'^mvn\s+dependency-check',

    # パッケージ一覧（読み取り専用）
    r'^npm\s+list',
    r'^pip\s+list',
    r'^pip\s+show',
    r'^go\s+list',
    r'^cargo\s+tree',
    r'^bundle\s+list',

    # Git 履歴（読み取り専用）
    r'^git\s+log',
    r'^git\s+blame',
    r'^git\s+show',
    r'^git\s+diff',
    r'^git\s+status',
    r'^git\s+branch',
    r'^git\s+tag',

    # ファイル検査（読み取り専用）
    r'^file\s+',
    r'^cat\s+',
    r'^head\s+',
    r'^tail\s+',
    r'^less\s+',
    r'^wc\s+',
    r'^ls\s+',
    r'^find\s+',
    r'^grep\s+',
    r'^rg\s+',  # ripgrep

    # 環境検査
    r'^env$',
    r'^printenv',
    r'^echo\s+\$',  # 環境変数の echo のみ
]

# 明示的にブロックされた危険なパターン
BLOCKED_PATTERNS = [
    # ファイル変更
    r'\brm\s+',
    r'\bmv\s+',
    r'\bcp\s+',
    r'\bchmod\s+',
    r'\bchown\s+',
    r'\bmkdir\s+',
    r'\brmdir\s+',
    r'\btouch\s+',

    # パッケージ変更
    r'\bnpm\s+install',
    r'\bnpm\s+uninstall',
    r'\bnpm\s+update',
    r'\bpip\s+install',
    r'\bpip\s+uninstall',
    r'\bgo\s+get',
    r'\bgo\s+install',
    r'\bcargo\s+install',
    r'\bbundle\s+install',

    # ネットワークリクエスト
    r'\bcurl\s+',
    r'\bwget\s+',
    r'\bfetch\s+',

    # システムコマンド
    r'\bsudo\s+',
    r'\bsu\s+',
    r'\bsystemctl\s+',
    r'\bservice\s+',

    # 危険なリダイレクト
    r'>\s*[^&]',  # 出力リダイレクト（ただし 2>&1 は除外）
    r'>>\s*',     # 追記リダイレクト

    # プロセス操作
    r'\bkill\s+',
    r'\bpkill\s+',
]


def validate_command(command: str) -> tuple[bool, str]:
    """
    コマンドがセキュリティ監査で許可されるかを検証。

    戻り値:
        (allowed, reason)
    """
    command = command.strip()

    # まずブロックパターンをチェック
    for pattern in BLOCKED_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return False, f"ブロックパターンを検出: {pattern}"

    # コマンドが許可パターンに一致するかチェック
    for pattern in ALLOWED_PATTERNS:
        if re.match(pattern, command, re.IGNORECASE):
            return True, f"許可: パターン {pattern} に一致"

    # デフォルト: 不明なコマンドをブロック
    return False, "セキュリティ監査モードの許可リストにないコマンド"


def main():
    try:
        # stdin から入力を読み取り（JSON 形式）
        input_data = sys.stdin.read()
        data = json.loads(input_data)

        # tool_input からコマンドを抽出
        tool_input = data.get('tool_input', {})
        command = tool_input.get('command', '')

        if not command:
            # 検証するコマンドなし
            sys.exit(0)

        allowed, reason = validate_command(command)

        if allowed:
            # コマンドは許可
            sys.exit(0)
        else:
            # JSON decision control でコマンドを適切にブロック
            allowed_cmds = (
                "セキュリティ監査で許可されるコマンド: "
                "依存関係の監査 (npm audit, pip-audit, cargo audit)、"
                "Git 履歴 (git log, git blame, git show)、"
                "ファイル検査 (cat, head, tail, ls, find, grep)、"
                "パッケージ一覧 (npm list, pip list, go list)"
            )
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": f"セキュリティ監査モード: {reason}。{allowed_cmds}"
                }
            }
            print(json.dumps(output))
            sys.exit(0)  # JSON decision control で exit 0

    except json.JSONDecodeError as e:
        # パースエラー時はフェイルセーフで拒否
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"セキュリティ監査モード: 無効な JSON 入力 - {e}"
            }
        }
        print(json.dumps(output))
        sys.exit(0)
    except Exception as e:
        # エラー時はフェイルセーフで拒否
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"セキュリティ監査モード: 検証エラー - {e}"
            }
        }
        print(json.dumps(output))
        sys.exit(0)


if __name__ == '__main__':
    main()
