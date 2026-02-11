#!/usr/bin/env python3
"""
シークレット漏洩防止フック - Write/Edit 用の PreToolUse
ファイルに書き込まれる前にシークレットや機密データを検出する。
スタック非依存: あらゆるプロジェクトタイプで動作。

適切なブロックのために JSON decision control（exit 0 + hookSpecificOutput）を使用。
"""

import sys
import os
import re
import json
import base64

# stdin からツール入力を読み取り（Claude Code が JSON を渡す）
input_data = sys.stdin.read().strip()

try:
    data = json.loads(input_data)
    tool_input = data.get("tool_input", {})
    # Write（content）と Edit（new_string）の両ツールに対応
    content = tool_input.get("content", "") or tool_input.get("new_string", "")
    file_path = tool_input.get("file_path", "")
except json.JSONDecodeError:
    # フェイルセーフ: パースエラー時は拒否（生の入力を処理しない）
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "シークレット漏洩チェックに失敗: 無効な JSON 入力形式"
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# シークレットパターン（スタック非依存）
SECRET_PATTERNS = [
    # AWS
    (r"AKIA[0-9A-Z]{16}", "AWS Access Key ID"),
    (r"ASIA[0-9A-Z]{16}", "AWS Session Token ID"),

    # Anthropic
    (r"sk-ant-[a-zA-Z0-9_-]{48,}", "Anthropic API Key"),

    # OpenAI（sk- の後に英数字、ただし Stripe パターンは除外）
    (r"sk-[a-zA-Z0-9]{32,}(?<!live_)(?<!test_)", "OpenAI API Key"),

    # HuggingFace
    (r"hf_[a-zA-Z0-9]{34,}", "HuggingFace Token"),

    # GitHub
    (r"ghp_[0-9a-zA-Z]{36}", "GitHub Personal Access Token"),
    (r"gho_[0-9a-zA-Z]{36}", "GitHub OAuth Token"),
    (r"ghs_[0-9a-zA-Z]{36}", "GitHub Server Token"),
    (r"ghu_[0-9a-zA-Z]{36}", "GitHub User Token"),
    (r"github_pat_[0-9a-zA-Z_]{22,}", "GitHub Fine-grained PAT"),

    # GitLab
    (r"glpat-[0-9a-zA-Z_-]{20,}", "GitLab Personal Access Token"),

    # 汎用 API キー（より正確 - 代入コンテキストが必要）
    (r"(?:api[_-]?key|apikey)[_-]?[=:]\s*['\"]?[a-zA-Z0-9_-]{20,}['\"]?", "汎用 API Key"),
    (r"(?:api[_-]?secret|apisecret)[_-]?[=:]\s*['\"]?[a-zA-Z0-9_-]{20,}['\"]?", "汎用 API Secret"),

    # 秘密鍵
    (r"-----BEGIN\s+(RSA|DSA|EC|OPENSSH|PGP)\s+PRIVATE\s+KEY-----", "秘密鍵"),

    # 認証情報付きデータベース URL
    (r"(postgres|mysql|mongodb|redis)://[^:]+:[^@]+@", "認証情報付きデータベース URL"),

    # JWT（疑わしく長い場合）
    (r"eyJ[a-zA-Z0-9_-]{50,}\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+", "JWT トークンの可能性"),

    # Slack
    (r"xox[baprs]-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*", "Slack Token"),

    # Stripe
    (r"sk_live_[0-9a-zA-Z]{24,}", "Stripe Live Secret Key"),
    (r"sk_test_[0-9a-zA-Z]{24,}", "Stripe Test Secret Key"),
    (r"rk_live_[0-9a-zA-Z]{24,}", "Stripe Live Restricted Key"),

    # Google
    (r"AIza[0-9A-Za-z_-]{35}", "Google API Key"),

    # Twilio
    (r"SK[0-9a-fA-F]{32}", "Twilio API Key"),

    # SendGrid
    (r"SG\.[a-zA-Z0-9_-]{22,}\.[a-zA-Z0-9_-]{22,}", "SendGrid API Key"),

    # Mailchimp
    (r"[0-9a-f]{32}-us[0-9]+", "Mailchimp API Key"),

    # Square
    (r"sq0[a-z]{3}-[0-9A-Za-z_-]{22,}", "Square Token"),

    # npm
    (r"npm_[a-zA-Z0-9]{36}", "npm Token"),

    # PyPI
    (r"pypi-[a-zA-Z0-9_-]{50,}", "PyPI Token"),

    # Supabase
    (r"sbp_[a-f0-9]{40,}", "Supabase Service Key"),
    (r"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+", "Supabase JWT (anon/service key)"),

    # DigitalOcean
    (r"dop_v1_[a-f0-9]{64}", "DigitalOcean Personal Access Token"),
    (r"doo_v1_[a-f0-9]{64}", "DigitalOcean OAuth Token"),

    # Datadog
    (r"DD[A-Z0-9]{32}", "Datadog API Key"),
    (r"[a-f0-9]{40}", "Datadog App Key (40 char hex)"),

    # Azure
    (r"[a-zA-Z0-9+/]{86}==", "Azure Storage Account Key"),

    # Vercel
    (r"vercel_[a-zA-Z0-9_-]{24,}", "Vercel Token"),

    # Netlify
    (r"[a-f0-9]{64}", "Netlify Personal Access Token (64 char hex)"),

    # HashiCorp Vault
    (r"hvs\.[a-zA-Z0-9_-]{24,}", "HashiCorp Vault Token"),
    (r"hvb\.[a-zA-Z0-9_-]{24,}", "HashiCorp Vault Batch Token"),

    # Linear
    (r"lin_api_[a-zA-Z0-9]{40,}", "Linear API Key"),

    # Figma
    (r"figd_[a-zA-Z0-9_-]{40,}", "Figma Personal Access Token"),

    # ハードコードされたパスワード（一般的な形式）
    (r"password\s*[=:]\s*['\"][^'\"]{8,}['\"]", "ハードコードされたパスワード"),
    (r"passwd\s*[=:]\s*['\"][^'\"]{8,}['\"]", "ハードコードされたパスワード"),
    (r"pwd\s*[=:]\s*['\"][^'\"]{8,}['\"]", "ハードコードされたパスワード"),
]

# シークレットを含んでも問題ないファイル（テンプレート、サンプル、ドキュメント）
ALLOWED_FILES = [
    ".env.example",
    ".env.template",
    ".env.sample",
    ".env.local.example",
    "example.env",
    "example.yaml",
    "example.yml",
    "SETUP.md",
    "INSTALL.md",
    "CONFIG.md",
]

# 許可されるファイルパスのパターン（正規表現）
ALLOWED_PATH_PATTERNS = [
    r"\.example$",
    r"\.sample$",
    r"\.template$",
    r"/examples?/",
    r"/docs?/",
    r"test_fixtures",
    r"test_data",
]

# ファイルをスキップすべきかチェック
def should_skip_file(path: str) -> bool:
    if not path:
        return False
    filename = os.path.basename(path)
    # ファイル名の完全一致をチェック
    if filename in ALLOWED_FILES:
        return True
    # パスパターンをチェック
    for pattern in ALLOWED_PATH_PATTERNS:
        if re.search(pattern, path, re.IGNORECASE):
            return True
    return False

# コンテンツのシークレットをチェック
def find_secrets(text: str) -> list[tuple[str, str]]:
    found = []
    for pattern, description in SECRET_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            found.append((pattern, description))
    return found

# Base64 エンコードされたシークレットの検出
def find_base64_secrets(text: str) -> list[tuple[str, str]]:
    """
    Base64 文字列を見つけてデコードした内容を既知のシークレットパターンと照合し、
    Base64 エンコードされたシークレットを検出する。

    戻り値: 見つかったシークレットの (pattern, description) タプルのリスト

    設計上の判断:
    - 最小24文字: Base64 は3バイトを4文字にエンコードするため、24文字 = 最小18バイト。
      これはデコード後のほとんどの API キープレフィックス（sk-ant-, ghp_, AKIA）に十分。
    - 代入コンテキスト（[=:]）が必要: 画像データやランダム文字列との誤検知を回避。
    - パディング ={0,3}: Base64 は 0-2 のパディング文字を持ちうるが、不正な入力のため 3 を許容。
    - 高価値パターンのみ: デコード後に特定の既知シークレット形式をチェックし、
      誤検知を最小化（ランダムな Base64 がでたらめにデコードされるケース等）。
    """
    found = []

    # 代入コンテキスト内の潜在的な Base64 文字列を検出するパターン
    # 誤検知を減らすため最小24文字（18バイトをエンコード）
    base64_context_pattern = r'[=:]\s*["\']?([A-Za-z0-9+/]{24,}={0,3})["\']?'

    candidates = re.findall(base64_context_pattern, text)

    for candidate in candidates:
        try:
            # Base64 としてデコードを試行
            decoded = base64.b64decode(candidate, validate=True).decode('utf-8', errors='ignore')

            # デコードされた内容をシークレットパターンに対してチェック
            # 誤検知を減らすため特定の高価値パターンのみチェック
            high_value_patterns = [
                (r"sk-ant-[a-zA-Z0-9_-]{20,}", "Anthropic API Key (Base64 エンコード)"),
                (r"sk-[a-zA-Z0-9]{20,}", "OpenAI API Key (Base64 エンコード)"),
                (r"AKIA[0-9A-Z]{16}", "AWS Access Key ID (Base64 エンコード)"),
                (r"ghp_[0-9a-zA-Z]{36}", "GitHub Personal Access Token (Base64 エンコード)"),
                (r"glpat-[0-9a-zA-Z_-]{20,}", "GitLab Personal Access Token (Base64 エンコード)"),
                (r"-----BEGIN\s+(RSA|DSA|EC|OPENSSH|PGP)\s+PRIVATE\s+KEY-----", "秘密鍵 (Base64 エンコード)"),
                (r"(postgres|mysql|mongodb)://[^:]+:[^@]+@", "データベース URL (Base64 エンコード)"),
            ]

            for pattern, description in high_value_patterns:
                if re.search(pattern, decoded, re.IGNORECASE):
                    found.append((pattern, description))
                    break  # 候補あたり1つの一致で十分
        except Exception:
            # 有効な Base64 でないかデコードエラー - スキップ
            pass

    return found

# メインチェック - フェイルクローズド動作のため try/except でラップ
try:
    if should_skip_file(file_path):
        # テンプレート/サンプルファイルはチェックせず許可
        sys.exit(0)

    # まず平文のシークレットをチェック
    secrets_found = find_secrets(content)

    # Base64 エンコードされたシークレットもチェック
    base64_secrets = find_base64_secrets(content)
    secrets_found.extend(base64_secrets)

    if secrets_found:
        descriptions = [s[1] for s in secrets_found]
        # JSON decision control で操作を適切にブロック
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"シークレットの可能性を検出: {', '.join(descriptions)}。環境変数またはシークレットマネージャーを使用してください。"
            }
        }
        print(json.dumps(output))
        sys.exit(0)  # JSON decision control で exit 0
    else:
        # 操作の続行を許可
        sys.exit(0)

except Exception as e:
    # フェイルセーフ: シークレット漏洩を防ぐため予期しないエラー時は拒否
    # external_content_validator.py と一貫したフェイルクローズド動作を保証
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"シークレット漏洩チェックに失敗: {str(e)}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)
