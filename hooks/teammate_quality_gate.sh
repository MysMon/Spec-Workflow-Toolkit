#!/bin/bash
# TeammateIdle フック: チームメイトの品質ゲートチェック
# チームメイトがアイドル状態になった時に実行される品質ゲート。
# exit 0 = チームメイトのアイドル遷移を許可（ブロッキングしない）
# exit 2 = フィードバックを送信してチームメイトに作業継続を指示
#
# Phase 1: フィールド検証とログのみ（ブロッキングなし）
# 注意: インサイトキャプチャには使用しない（Layer 1 プロンプト指示で対応）。
#       品質基準の検証専用。

set -euo pipefail

# stdin からチームメイト情報を読み取る
INPUT=$(cat)

# 入力が空の場合は正常終了
if [ -z "$INPUT" ]; then
    exit 0
fi

# Python で JSON パースとフィールド検証
if command -v python3 &> /dev/null; then
    HOOK_INPUT_VAR="$INPUT" python3 -c "
import json
import os
import sys
from datetime import datetime, timezone

try:
    input_data = os.environ.get('HOOK_INPUT_VAR', '')
    if not input_data:
        sys.exit(0)

    data = json.loads(input_data)

    # フィールド検証
    teammate_name = data.get('teammate_name', '')
    team_name = data.get('team_name', '')

    timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

    # 必須フィールドの欠落チェック
    missing = []
    if not teammate_name:
        missing.append('teammate_name')
    if not team_name:
        missing.append('team_name')

    if missing:
        fields = ', '.join(missing)
        print(
            '[TeammateIdle] 警告: 欠落フィールド: %s (時刻: %s)'
            % (fields, timestamp),
            file=sys.stderr,
        )
        sys.exit(0)

    # 監査ログ出力（stderr でフック表示に出力）
    print(
        '[TeammateIdle] %s (チーム: %s) がアイドル状態になりました (時刻: %s)'
        % (teammate_name, team_name, timestamp),
        file=sys.stderr,
    )

    # Phase 1: ブロッキングなし（Phase 2 で品質チェック追加予定）
    sys.exit(0)

except json.JSONDecodeError:
    print('[TeammateIdle] 警告: 無効な JSON 入力', file=sys.stderr)
    sys.exit(0)
except Exception:
    sys.exit(0)
"
else
    # Python が利用できない場合もログ出力して正常終了
    echo "[TeammateIdle] 警告: python3 が利用できません。検証をスキップします" >&2
fi

exit 0
