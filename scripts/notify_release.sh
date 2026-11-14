#!/usr/bin/env bash
set -euo pipefail

for attempt in 1 2 3; do
  status=$(curl -sS -w '%{http_code}' -X POST \
    "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" \
    -F "chat_id=$TELEGRAM_CHAT_ID" \
    -F 'document=@build/app/outputs/flutter-apk/app-arm64-v8a-release.apk' \
    -F "caption=$FULL_MESSAGE" -o response.json) || status=000

  if [ "$status" = 413 ]; then
    # Retrying an oversized file cannot help; the APK is already archived in Actions.
    status=$(curl -sS -w '%{http_code}' -X POST \
      "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
      --data-urlencode "chat_id=$TELEGRAM_CHAT_ID" \
      --data-urlencode "text=Tilomnov release APK: $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" \
      -o response.json) || status=000
  fi

  if [ "$status" = 200 ] && jq -e '.ok == true' response.json >/dev/null; then
    echo 'Release notification delivered.'
    exit 0
  fi
  echo "Release notification failed (HTTP $status), attempt $attempt/3."
  if [ "$attempt" -lt 3 ]; then sleep 10; fi
done
exit 1
