#!/usr/bin/env python3
"""
外部コンテンツバリデーターフック - WebFetch および WebSearch 用の PreToolUse
外部コンテンツリクエストを検証してセキュリティリスクを軽減する。

セキュリティ上の懸念に対処:
- 悪意のある Web コンテンツからのプロンプトインジェクション
- 内部 URL 経由の SSRF（サーバーサイドリクエストフォージェリ）
- URL パラメータ経由のデータ漏洩
- 過剰なコンテンツ取得（DoS 防止）

機能:
- URL 検証（内部/localhost URL のブロック）
- ドメイン許可リスト/ブロックリストのサポート（WebSearch ツール入力から allowed_domains/blocked_domains を読み取り）
- 機密データを含むクエリパラメータのサニタイズ
- IP 正規化による SSRF 防止（10進数、8進数、16進数 IP 形式に対応）

ブロックには JSON decision control（exit 0 + hookSpecificOutput）を使用。
"""

import sys
import re
import json
import socket
import ipaddress
from urllib.parse import urlparse, parse_qs

# stdin からツール入力を読み取り（Claude Code が JSON を渡す）
input_data = sys.stdin.read().strip()

# --- 設定 ---

# 最大 URL 長（バッファオーバーフロー攻撃の防止）
MAX_URL_LENGTH = 2048

# ブロックする内部/プライベートネットワークパターン（SSRF 防止）
BLOCKED_HOST_PATTERNS = [
    r"^localhost$",
    r"^127\.\d+\.\d+\.\d+$",       # IPv4 ループバック
    r"^10\.\d+\.\d+\.\d+$",        # プライベート クラス A
    r"^172\.(1[6-9]|2\d|3[01])\.\d+\.\d+$",  # プライベート クラス B
    r"^192\.168\.\d+\.\d+$",       # プライベート クラス C
    r"^169\.254\.\d+\.\d+$",       # リンクローカル
    r"^\[?::1\]?$",                # IPv6 ループバック
    r"^\[?fe80:",                  # IPv6 リンクローカル
    r"^\[?fc00:",                  # IPv6 ユニークローカル
    r"^\[?fd00:",                  # IPv6 ユニークローカル
    # IPv4 マッピング IPv6 アドレス（::ffff:x.x.x.x）
    r"^\[?::ffff:127\.",           # IPv4 マッピング ループバック
    r"^\[?::ffff:10\.",            # IPv4 マッピング プライベート クラス A
    r"^\[?::ffff:172\.(1[6-9]|2\d|3[01])\.",  # IPv4 マッピング プライベート クラス B
    r"^\[?::ffff:192\.168\.",      # IPv4 マッピング プライベート クラス C
    r"^\[?::ffff:169\.254\.",      # IPv4 マッピング リンクローカル
    r"^0\.0\.0\.0$",               # 全インターフェース
    r"^metadata\.google\.internal$",  # GCP メタデータ
    r"^169\.254\.169\.254$",       # クラウドメタデータ（AWS, Azure, GCP）
    r".*\.internal$",              # 汎用内部ドメイン
    r".*\.local$",                 # mDNS ローカルドメイン
    r".*\.localhost$",             # localhost サブドメイン
]

# シークレットを漏洩する可能性のある機密クエリパラメータ名
SENSITIVE_PARAM_PATTERNS = [
    r"(?i)^api[_-]?key$",
    r"(?i)^secret$",
    r"(?i)^token$",
    r"(?i)^password$",
    r"(?i)^auth$",
    r"(?i)^credential$",
    r"(?i)^private[_-]?key$",
    r"(?i)^access[_-]?key$",
    r"(?i)^session[_-]?id$",
]

# 悪意のある意図を示す可能性のある疑わしい URL パターン
SUSPICIOUS_URL_PATTERNS = [
    r"<script",           # URL に埋め込まれた script タグ
    r"javascript:",       # JavaScript プロトコル
    r"data:",             # Data URI（実行可能コンテンツを含む可能性）
    r"vbscript:",         # VBScript プロトコル
    r"file://",           # ローカルファイルアクセス
    r"%00",               # ヌルバイトインジェクション
    r"\.\.\/",            # パストラバーサル
    r"\.\.\\",            # パストラバーサル（Windows）
]


def extract_url_from_input(tool_name: str, tool_input: dict) -> str:
    """WebFetch または WebSearch ツール入力から URL を抽出。"""
    if tool_name == "WebFetch":
        return tool_input.get("url", "")
    elif tool_name == "WebSearch":
        # WebSearch は 'url' ではなく 'query' を使用するが、URL のようなクエリをチェック
        query = tool_input.get("query", "")
        # クエリが URL のように見える場合は検証
        if query.startswith(("http://", "https://")):
            return query
        return ""  # 通常の検索クエリは許可
    return ""


def extract_domain_lists(tool_input: dict) -> tuple[list[str], list[str]]:
    """
    ツール入力から allowed_domains と blocked_domains を抽出。
    WebSearch ツールのオプションパラメータ。

    戻り値: (allowed_domains, blocked_domains)
    """
    allowed = tool_input.get("allowed_domains", [])
    blocked = tool_input.get("blocked_domains", [])

    # リストであることを確認
    if not isinstance(allowed, list):
        allowed = []
    if not isinstance(blocked, list):
        blocked = []

    return allowed, blocked


def check_domain_lists(url: str, allowed_domains: list[str], blocked_domains: list[str]) -> tuple[bool, str]:
    """
    URL を許可/ブロックドメインリストに対してチェック。

    引数:
        url: チェック対象の URL
        allowed_domains: 空でない場合、これらのドメインのみ許可
        blocked_domains: これらのドメインは常にブロック

    戻り値: (is_valid, error_message)
    """
    if not url:
        return True, ""

    try:
        parsed = urlparse(url)
        host = (parsed.hostname or "").lower()
    except Exception:
        return True, ""  # 不正な URL は他の検証に任せる

    if not host:
        return True, ""

    # まずブロックドメインをチェック
    for blocked in blocked_domains:
        blocked_lower = blocked.lower()
        # 完全一致またはサブドメインに一致
        if host == blocked_lower or host.endswith("." + blocked_lower):
            return False, f"ドメインがブロックリストに含まれています: {blocked}"

    # 許可ドメインをチェック（指定されている場合、これらのみ許可）
    if allowed_domains:
        is_allowed = False
        for allowed in allowed_domains:
            allowed_lower = allowed.lower()
            # 完全一致またはサブドメインに一致
            if host == allowed_lower or host.endswith("." + allowed_lower):
                is_allowed = True
                break

        if not is_allowed:
            return False, f"ドメインが許可リストに含まれていません: {host}"

    return True, ""


def normalize_ip_address(host: str) -> str | None:
    """
    IP アドレスを標準的なドット付き10進数形式に正規化。
    10進数（2130706433）、8進数（0177.0.0.1）、16進数（0x7f.0.0.1）形式に対応。
    ホストが IP アドレスでない場合は None を返す。
    """
    try:
        # IP アドレスとして解決（10進数/8進数/16進数形式に対応し正規化）
        # socket.inet_aton は様々な IP 形式を処理して正規化
        packed = socket.inet_aton(host)
        return socket.inet_ntoa(packed)
    except (socket.error, OSError):
        pass

    # IPv6 を試行
    try:
        ip = ipaddress.ip_address(host.strip("[]"))
        # IPv4 マッピング IPv6 を IPv4 に変換して一貫したチェックを行う
        if isinstance(ip, ipaddress.IPv6Address) and ip.ipv4_mapped:
            return str(ip.ipv4_mapped)
        return str(ip)
    except ValueError:
        pass

    return None


def is_private_or_reserved_ip(ip_str: str) -> tuple[bool, str]:
    """
    IP アドレスがプライベート、予約済み、ループバック、またはリンクローカルかチェック。
    堅牢なチェックのため ipaddress モジュールを使用。
    """
    try:
        ip = ipaddress.ip_address(ip_str)

        if ip.is_loopback:
            return True, f"ループバックアドレスをブロック: {ip_str}"
        if ip.is_private:
            return True, f"プライベートネットワークアドレスをブロック: {ip_str}"
        if ip.is_reserved:
            return True, f"予約済みアドレスをブロック: {ip_str}"

        # リンクローカルチェックの前にクラウドメタデータエンドポイントをチェック
        # （169.254.169.254 はリンクローカルだが固有のメッセージが必要）
        if ip_str == "169.254.169.254":
            return True, f"クラウドメタデータエンドポイントをブロック: {ip_str}"

        if ip.is_link_local:
            return True, f"リンクローカルアドレスをブロック: {ip_str}"
        if ip.is_multicast:
            return True, f"マルチキャストアドレスをブロック: {ip_str}"

        # 未指定アドレスをチェック（0.0.0.0 または ::）
        if ip.is_unspecified:
            return True, f"未指定アドレスをブロック: {ip_str}"

    except ValueError:
        pass

    return False, ""


def is_blocked_host(host: str) -> tuple[bool, str]:
    """
    ホストがブロックパターンに一致するかチェック（SSRF 防止）。
    正規化により代替 IP 形式（10進数、8進数、16進数）に対応。
    """
    host_lower = host.lower()

    # まず IP アドレスとして正規化を試行（10進数/8進数/16進数バイパスの試みに対応）
    normalized_ip = normalize_ip_address(host)
    if normalized_ip:
        # 正規化された IP をプライベート/予約済み範囲に対してチェック
        is_private, reason = is_private_or_reserved_ip(normalized_ip)
        if is_private:
            if normalized_ip != host:
                return True, f"{reason}（正規化元: {host}）"
            return True, reason

    # ドメインベースのブロックには正規表現パターンでチェック
    for pattern in BLOCKED_HOST_PATTERNS:
        if re.match(pattern, host_lower):
            return True, f"内部/プライベートネットワークのホストをブロック: {host}"
        # 正規化された IP もパターンに対してチェック
        if normalized_ip and re.match(pattern, normalized_ip):
            return True, f"内部/プライベートネットワークのホストをブロック: {host}（解決先: {normalized_ip}）"

    return False, ""


def check_sensitive_params(url: str) -> tuple[bool, str]:
    """URL クエリパラメータに機密データが含まれていないかチェック。"""
    try:
        parsed = urlparse(url)
        params = parse_qs(parsed.query)

        for param_name in params.keys():
            for pattern in SENSITIVE_PARAM_PATTERNS:
                if re.match(pattern, param_name):
                    return True, f"URL に機密パラメータを検出: {param_name}"
    except Exception:
        pass
    return False, ""


def check_suspicious_patterns(url: str) -> tuple[bool, str]:
    """悪意のある意図を示す可能性のある疑わしいパターンをチェック。"""
    url_lower = url.lower()
    for pattern in SUSPICIOUS_URL_PATTERNS:
        if re.search(pattern, url_lower):
            return True, f"URL に疑わしいパターンを検出: {pattern}"
    return False, ""


def validate_url(url: str) -> tuple[bool, str]:
    """
    URL のセキュリティ上の懸念を検証。
    戻り値: (is_valid, error_message)
    """
    if not url:
        return True, ""  # 空の URL は URL ベースのリクエストではないことを意味

    # URL 長をチェック
    if len(url) > MAX_URL_LENGTH:
        return False, f"URL が最大長を超えています（{MAX_URL_LENGTH} 文字）"

    # まず疑わしいパターンをチェック
    has_suspicious, reason = check_suspicious_patterns(url)
    if has_suspicious:
        return False, reason

    # URL をパース
    try:
        parsed = urlparse(url)
    except Exception as e:
        return False, f"無効な URL 形式: {e}"

    # スキームが http または https であることを確認
    if parsed.scheme not in ("http", "https"):
        return False, f"サポートされていない URL スキーム: {parsed.scheme}"

    # ブロックされたホストをチェック（SSRF 防止）
    host = parsed.hostname or ""
    is_blocked, reason = is_blocked_host(host)
    if is_blocked:
        return False, reason

    # 機密パラメータをチェック
    has_sensitive, reason = check_sensitive_params(url)
    if has_sensitive:
        return False, reason

    return True, ""


# --- メインロジック ---

try:
    data = json.loads(input_data)
    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {})

    # WebFetch と WebSearch ツールのみ処理
    if tool_name not in ("WebFetch", "WebSearch"):
        # 他のツールはそのまま通過
        sys.exit(0)

    # 検証する URL を抽出
    url = extract_url_from_input(tool_name, tool_input)

    # ドメイン許可リスト/ブロックリストを抽出してチェック（WebSearch ツールパラメータ）
    allowed_domains, blocked_domains = extract_domain_lists(tool_input)
    if url and (allowed_domains or blocked_domains):
        is_valid, error_reason = check_domain_lists(url, allowed_domains, blocked_domains)
        if not is_valid:
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": f"外部コンテンツ検証に失敗: {error_reason}"
                }
            }
            print(json.dumps(output))
            sys.exit(0)

    # URL を検証（SSRF 防止、疑わしいパターン等）
    is_valid, error_reason = validate_url(url)

    if not is_valid:
        # 詳細な理由とともにリクエストをブロック
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"外部コンテンツ検証に失敗: {error_reason}"
            }
        }
        print(json.dumps(output))
        sys.exit(0)

    # URL は有効 - リクエストを許可
    # 許可の判定には出力不要
    sys.exit(0)

except json.JSONDecodeError:
    # フェイルセーフ: パースエラー時は拒否
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "外部コンテンツ検証に失敗: 無効な JSON 入力形式"
        }
    }
    print(json.dumps(output))
    sys.exit(0)
except Exception as e:
    # フェイルセーフ: 予期しないエラー時は拒否
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"外部コンテンツ検証に失敗: {str(e)}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)
