#!/usr/bin/env python3
"""
安全性チェックフック - Bash および MCP コマンド実行ツール用の PreToolUse
危険なシェルコマンドをブロックするか、より安全な代替に変換する。
スタック非依存: あらゆるプロジェクトタイプで動作。

機能:
- ブロック用の JSON decision control（exit 0 + hookSpecificOutput）
- コマンドをより安全なバージョンに変換する入力変更（updatedInput）
- v2.0.10+ の入力変更機能をサポート
- MCP ツールサポート: MCP サーバーからのコマンドを検証（mcp__*__exec, mcp__*__shell 等）

2つの戦略を使用:
1. ブロック: 安全にできない完全に危険なコマンド
2. 変換: 修正によりより安全にできるコマンド
"""

import sys
import re
import json

# stdin からツール入力を読み取り（Claude Code が JSON を渡す）
input_data = sys.stdin.read().strip()

def extract_command_from_input(tool_name: str, tool_input: dict) -> str:
    """
    ツール入力からコマンド文字列を抽出。Bash と MCP ツールの両方に対応。
    MCP ツールはコマンドに異なるフィールド名を使用する場合がある。
    """
    # 標準の Bash ツール
    if tool_name == "Bash":
        return tool_input.get("command", "")

    # MCP ツール - コマンド実行の一般的なフィールド名を試行
    # MCP サーバーごとに異なるフィールド名を使用
    command_fields = [
        "command",      # 最も一般的
        "cmd",          # 短縮形
        "script",       # スクリプト実行用
        "shell_command",
        "bash_command",
        "exec",
        "run",
        "code",         # 一部のサーバーが使用
        "input",        # ターミナルツールが使用する場合あり
    ]

    for field in command_fields:
        if field in tool_input and isinstance(tool_input[field], str):
            return tool_input[field]

    # 一部の MCP ツールはコマンドを配列の最初の位置引数として渡す
    if "args" in tool_input and isinstance(tool_input["args"], list) and len(tool_input["args"]) > 0:
        return str(tool_input["args"][0])

    return ""

try:
    data = json.loads(input_data)
    tool_name = data.get("tool_name", "Bash")
    tool_input = data.get("tool_input", {})
    command = extract_command_from_input(tool_name, tool_input)
    is_mcp_tool = tool_name.startswith("mcp__")
except json.JSONDecodeError:
    # フェイルセーフ: パースエラー時は拒否（生の入力を処理しない）
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "安全性チェックに失敗: 無効な JSON 入力形式"
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# 環境変数のシークレットパターン - export によるシークレット漏洩を検出
# より具体的なエラーメッセージを提供するため、危険なパターンの前にチェック
#
# 設計上の判断:
# - リテラル値（$VAR 参照ではなく）が代入される場合のみブロック
# - テスト/ダミー値の誤検知を減らすため値に最小20文字を要求
# - 先頭の空白を許容するが行コンテキストにアンカー
# - プロバイダー固有パターンはより厳密（値の長さに関わらずブロック）
ENV_SECRET_PATTERNS = [
    # プロバイダー固有のシークレット - 値の長さに関わらずブロック（高信頼度）
    # これらのプロバイダーの API キーは常に機密
    (r"export\s+(?:ANTHROPIC|OPENAI)_(?:API_KEY|SECRET)[A-Z_]*\s*=\s*['\"]?(?!\$)[a-zA-Z0-9_-]{10,}", "プロバイダー API キー (Anthropic/OpenAI)"),
    (r"export\s+AWS_(?:SECRET_ACCESS_KEY|SESSION_TOKEN)\s*=\s*['\"]?(?!\$)[a-zA-Z0-9_/+-]{20,}", "AWS シークレット認証情報"),
    (r"export\s+(?:GITHUB|GITLAB)_(?:TOKEN|PAT|SECRET)[A-Z_]*\s*=\s*['\"]?(?!\$)[a-zA-Z0-9_-]{20,}", "GitHub/GitLab トークン"),

    # 汎用シークレットパターン - 誤検知を減らすためより長い値（20文字以上）を要求
    # (?!\$) の否定先読みで $OTHER_VAR のような変数参照を除外
    (r"export\s+[A-Z_]*(?:API_KEY|APIKEY|API_SECRET)[A-Z_]*\s*=\s*['\"]?(?!\$)[a-zA-Z0-9_-]{20,}['\"]?", "環境変数内の API キー"),
    (r"export\s+[A-Z_]*(?:SECRET_KEY|PRIVATE_KEY|ACCESS_KEY)[A-Z_]*\s*=\s*['\"]?(?!\$)[a-zA-Z0-9_/+-]{20,}['\"]?", "環境変数内のシークレット/秘密鍵"),
    (r"export\s+[A-Z_]*(?:PASSWORD|PASSWD)[A-Z_]*\s*=\s*['\"]?(?!\$)[^\s'\"]{12,}['\"]?", "環境変数内のパスワード"),
]

# 危険なコマンドパターン（スタック非依存）
DANGEROUS_PATTERNS = [
    # 破壊的なファイル操作
    r"rm\s+-rf\s+/",
    r"rm\s+-rf\s+\*",
    r"rm\s+-rf\s+~",
    r"rm\s+-rf\s+\$HOME",
    r"rmdir\s+/",

    # 権限昇格
    r"sudo\s+",
    r"su\s+-",
    r"chmod\s+777",
    r"chmod\s+-R\s+777",
    r"chown\s+-R\s+root",

    # 危険なダウンロードとリモート実行
    r"curl\s+.*\|\s*sh",
    r"curl\s+.*\|\s*bash",
    r"wget\s+.*\|\s*sh",
    r"wget\s+.*\|\s*bash",
    r"curl\s+.*>\s*/",
    r"wget\s+.*-O\s*/",

    # 任意コード実行
    r"\beval\s+",
    r"source\s+/dev/",
    r"source\s+<\(",
    r"\.\s+<\(",
    r"base64\s+.*-d.*\|\s*(sh|bash)",

    # システム変更
    r"mkfs\.",
    r"dd\s+if=.*of=/dev/",
    r">\s*/dev/(sd|hd|nvme|vd)[a-z0-9]*",
    r"echo\s+.*>\s*/etc/",

    # フォーク爆弾とリソース枯渇
    r":\(\)\s*\{\s*:\|:\s*&\s*\}",
    r"while\s+true.*fork",

    # 履歴操作（痕跡の隠蔽）
    r"history\s+-c",
    r"unset\s+HISTFILE",
    r"export\s+HISTSIZE=0",

    # ネットワーク攻撃とリバースシェル
    r"nc\s+-l.*\|.*sh",
    r"ncat.*-e\s+/bin",
    r"bash\s+-i\s+.*>/dev/tcp/",
    r"python.*socket.*connect.*exec",
    r"perl.*socket.*exec",
    r"php\s+-r.*fsockopen",

    # crontab 操作
    r"crontab\s+-r",
    r"echo\s+.*>>\s*/var/spool/cron",
    r"echo\s+.*>>\s*/etc/cron",

    # SSH 鍵操作
    r">\s*~/.ssh/authorized_keys",
    r">>\s*~/.ssh/authorized_keys",
    r"echo\s+.*>.*\.ssh/authorized_keys",

    # 危険な環境変更
    # PATH ハイジャックのブロック（非標準または tmp ディレクトリで始まる PATH の設定）
    r"export\s+PATH=['\"]?(/tmp|/var/tmp|\./|\.\./).*",
    r"export\s+PATH=['\"]?[^$/]",  # / または $ で始まらない PATH
    r"export\s+LD_PRELOAD",
    r"export\s+LD_LIBRARY_PATH=/",
    r"export\s+HISTCONTROL=ignorespace",  # 履歴からコマンドを隠す

    # スクリプトインジェクションパターン（書き込んでから実行）
    r"echo\s+.*>\s*\S+\.sh\s*&&\s*(bash|sh|source)",
    r"cat\s+.*>\s*\S+\.sh\s*&&\s*(bash|sh|source)",
    r"printf\s+.*>\s*\S+\.sh\s*&&\s*(bash|sh|source)",

    # プロセス置換の悪用
    r"bash\s+<\(",
    r"sh\s+<\(",

    # 16進数/8進数エンコードされたコマンド実行
    r"\$'\\x[0-9a-fA-F]",
    r"echo\s+-e\s+.*\\\\x.*\|\s*(sh|bash)",
    r"printf\s+.*\\\\x.*\|\s*(sh|bash)",

    # 8進数エンコードバイパス（例: $'\057bin\057rm' = /bin/rm）
    r"\$'\\[0-7]{3}",

    # Unicode エンコードバイパス（例: $'\u002f' または $'\U0000002f'）
    r"\$'\\u[0-9a-fA-F]+",
    r"\$'\\U[0-9a-fA-F]+",

    # Python/Perl/Ruby ワンライナーの危険なモジュールを使用した実行
    r"python[3]?\s+-c\s+.*__import__.*subprocess",
    r"perl\s+-e\s+.*system\s*\(",
    r"ruby\s+-e\s+.*system\s*\(",

    # 危険な xargs パターン
    r"xargs\s+.*rm\s",
    r"xargs\s+.*-I.*sh\s+-c",

    # ルートまたは機密ディレクトリへの tar 展開
    r"tar\s+.*-[xz].*-C\s+/[^a-zA-Z]",

    # ダウンロードして1行で実行（追加パターン）
    r"(wget|curl)\s+.*-O\s+-\s*\|\s*(sh|bash)",
    r"(wget|curl)\s+.*--output-document=-\s*\|\s*(sh|bash)",

    # 変数展開の難読化 - 疑わしい変数を使った rm（/ を含む可能性）
    # ブロック: rm -rf $P, rm -rf ${VAR} 等（変数が危険なパスを含む可能性）
    r"rm\s+-rf\s+\$[A-Z_]+\s*$",
    r"rm\s+-rf\s+\$\{[A-Z_]+\}",

    # 文字列内のコマンド置換 - 潜在的なコードインジェクション
    # ブロック: コマンドを実行する $(...) を含む文字列
    r'["\'][^"\']*\$\([^)]+\)[^"\']*["\']',
    # ブロック: クォート文字列内のバッククォート（レガシーコマンド置換）
    r'["\'][^"\']*`[^`]+`[^"\']*["\']',

    # 追加の危険なコマンド - システムパスでのインプレースファイル編集
    r"sed\s+-i[^\s]*\s+.*\s+/(etc|usr|bin|sbin|lib|boot|sys|proc)/",
    r"sed\s+--in-place[^\s]*\s+.*\s+/(etc|usr|bin|sbin|lib|boot|sys|proc)/",

    # tee によるシステムパスへの書き込み（シェルでブロックされたリダイレクトをバイパス可能）
    r"tee\s+/(etc|usr|bin|sbin|lib|boot|sys|proc|root)/",
    r"tee\s+-a\s+/(etc|usr|bin|sbin|lib|boot|sys|proc|root)/",

    # dd による任意のデバイスへの書き込み（of=/dev/ より広範）
    r"dd\s+.*\bof=/dev/",
    r"dd\s+.*\bof=/(etc|usr|bin|sbin|lib|boot)/",

    # systemctl サービス操作（権限昇格、永続化）
    r"systemctl\s+(enable|disable|start|stop|restart|mask)\s+",

    # chmod の危険なパターン - 再帰的または過度に許容的
    r"chmod\s+-R\s+",
    r"chmod\s+[0-7]*7[0-7]*\s+/(etc|usr|bin|sbin|lib|boot|sys|var)/",

    # システムディレクトリでの chown（権限昇格）
    r"chown\s+.*\s+/(etc|usr|bin|sbin|lib|boot|sys|proc)/",
    r"chown\s+-R\s+",

    # シンボリックリンク攻撃 - 機密な場所へのシンボリックリンク作成
    # ブロック: システムディレクトリや機密ファイルを対象とした ln -s
    r"ln\s+-[sf]+\s+.*/etc/",
    r"ln\s+-[sf]+\s+.*/root/",
    r"ln\s+-[sf]+\s+.*/.ssh/",
    r"ln\s+-[sf]+\s+/etc/",
    r"ln\s+-[sf]+\s+/root/",
    r"ln\s+-[sf]+\s+~/.ssh/",
    # ブロック: シンボリックリンクを作成してからそれを通じて読み書き（TOCTOU パターン）
    r"ln\s+-[sf]+\s+.*&&\s*(cat|head|tail|less|more|vim|nano|echo|tee)\s+",
    # ブロック: 既存ファイルへの強制シンボリックリンク上書き
    r"ln\s+-sf\s+.*\s+\./[^&|;]+$",
]

# 変換可能なパターン - 修正によりより安全にできるコマンド
# 形式: (pattern, transform_function_name, description)
TRANSFORMABLE_PATTERNS = [
    # ルートを対象としていない rm コマンド - -i（対話的）フラグを追加
    (r"^rm\s+(?!-rf\s+/)(?!-rf\s+\*)(?!-rf\s+~)(.+)$", "add_interactive_flag", "対話的確認を追加"),
    # タイムアウトなしの長時間実行コマンド - timeout ラッパーを追加
    (r"^(npm\s+install|yarn\s+install|pip\s+install)", "add_timeout", "5分のタイムアウトを追加"),
    # -v なしの git push - デバッグ改善のため verbose フラグを追加
    (r"^git\s+push\s+(?!.*-v)(.*)$", "add_verbose_git", "verbose フラグを追加"),
]

def add_interactive_flag(cmd: str) -> str:
    """rm コマンドに -i フラグを追加して対話的確認を有効化。"""
    # rm の後に -i を挿入
    return re.sub(r"^rm\s+", "rm -i ", cmd)

def add_timeout(cmd: str) -> str:
    """長時間実行操作にタイムアウトをラップ。"""
    return f"timeout 300 {cmd}"

def add_verbose_git(cmd: str) -> str:
    """デバッグ出力改善のため git push に verbose フラグを追加。"""
    return re.sub(r"^git\s+push\s+", "git push -v ", cmd)

# 環境変数のシークレットをチェック（より具体的、最初にチェック）
def check_env_secrets(cmd: str) -> tuple[bool, str]:
    """
    コマンドが環境変数経由でシークレットをエクスポートするかチェック。
    戻り値: (is_secret_export, description)
    """
    for pattern, description in ENV_SECRET_PATTERNS:
        if re.search(pattern, cmd, re.IGNORECASE | re.MULTILINE):
            return True, description
    return False, ""

# コマンドをパターンに対してチェック
def is_dangerous(cmd: str) -> tuple[bool, str]:
    cmd_lower = cmd.lower()
    for pattern in DANGEROUS_PATTERNS:
        if re.search(pattern, cmd_lower, re.IGNORECASE):
            return True, pattern
    return False, ""

def check_transformable(cmd: str) -> tuple[bool, str, str]:
    """
    コマンドをより安全なバージョンに変換できるかチェック。
    戻り値: (is_transformable, transformed_command, description)
    """
    for pattern, transform_name, description in TRANSFORMABLE_PATTERNS:
        if re.search(pattern, cmd, re.IGNORECASE):
            transform_func = globals().get(transform_name)
            if transform_func:
                transformed = transform_func(cmd)
                if transformed != cmd:  # 実際に変換された場合のみ返す
                    return True, transformed, description
    return False, cmd, ""

# メインチェック - フェイルクローズド動作のため try/except でラップ
# 予期しない例外（正規表現のバックトラッキング、メモリエラー等）が
# 拒否となることを保証し、潜在的に危険なコマンドの実行を防止
try:
    # まず環境変数シークレットのエクスポートをチェック（より具体的なメッセージ）
    is_env_secret, secret_desc = check_env_secrets(command)

    if is_env_secret:
        # 具体的なガイダンスとともにシークレットのエクスポートをブロック
        tool_type = f"MCP ツール ({tool_name})" if is_mcp_tool else "Bash"
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"{tool_type} コマンドをブロック: {secret_desc}。シェルコマンドでシークレットを直接エクスポートする代わりに .env ファイルまたはシークレットマネージャーを使用してください。"
            }
        }
        print(json.dumps(output))
        sys.exit(0)

    # 危険なパターンをチェック
    dangerous, matched_pattern = is_dangerous(command)

    if dangerous:
        # JSON decision control でコマンドを適切にブロック
        tool_type = f"MCP ツール ({tool_name})" if is_mcp_tool else "Bash"
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"危険な {tool_type} コマンドをブロック（一致パターン: {matched_pattern}）"
            }
        }
        print(json.dumps(output))
        sys.exit(0)  # JSON decision control で exit 0

    # コマンドをより安全なバージョンに変換できるかチェック
    # 注: 変換は Bash ツールにのみ適用（スキーマが既知）
    # MCP ツールはスキーマが様々なため、危険なコマンドのブロックのみ
    transformable, transformed_cmd, transform_desc = check_transformable(command)

    if transformable and not is_mcp_tool:
        # 入力変更でコマンドを変換（v2.0.10+ 機能）
        # 監査証跡と透明性のため permissionDecisionReason を含める
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": f"安全性のため変換: {transform_desc}。元のコマンド: {command[:50]}{'...' if len(command) > 50 else ''}",
                "updatedInput": {
                    "command": transformed_cmd
                }
            }
        }
        print(json.dumps(output))
        sys.exit(0)

    # コマンドの変更なし続行を許可 - 監査の一貫性のため明示的な許可
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow"
        }
    }
    print(json.dumps(output))
    sys.exit(0)

except Exception as e:
    # フェイルセーフ: 危険なコマンドの実行を防ぐため予期しないエラー時は拒否
    # prevent_secret_leak.py および external_content_validator.py と一貫した
    # フェイルクローズド動作を保証
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"安全性チェックに失敗: {str(e)}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)
