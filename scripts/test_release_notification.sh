#!/usr/bin/env bash
set -euo pipefail
script="$(cd "$(dirname "$0")" && pwd)/notify_release.sh"
tmp=$(mktemp -d)
trap 'rm -f "$tmp/response.json" "$tmp/calls"; rmdir "$tmp"' EXIT
cd "$tmp"
export TELEGRAM_BOT_TOKEN=fixture TELEGRAM_CHAT_ID=fixture FULL_MESSAGE='Release _plain text_'
export GITHUB_SERVER_URL=https://github.com GITHUB_REPOSITORY=fixture/app GITHUB_RUN_ID=1

curl() {
  local method=sendDocument
  for arg in "$@"; do
    if [[ "$arg" == */sendMessage ]]; then method=sendMessage; fi
  done
  echo "$method" >> calls
  if [ "$SCENARIO" = transport ]; then return 7; fi
  if [ "$SCENARIO" = oversized ] && [ "$method" = sendDocument ]; then
    echo '{"ok":false}' > response.json
    printf 413
  elif [ "$SCENARIO" = rejected ]; then
    echo '{"ok":false}' > response.json
    printf 200
  else
    echo '{"ok":true}' > response.json
    printf 200
  fi
}
sleep() { :; }
export -f curl sleep

export SCENARIO=normal
bash "$script"
test "$(cat calls)" = sendDocument
> calls
export SCENARIO=oversized
bash "$script"
test "$(cat calls)" = $'sendDocument\nsendMessage'
> calls
export SCENARIO=rejected
if bash "$script"; then echo 'Provider refusal incorrectly passed'; exit 1; fi
test "$(wc -l < calls | tr -d ' ')" = 3
> calls
export SCENARIO=transport
if bash "$script"; then echo 'Transport failure incorrectly passed'; exit 1; fi
test "$(wc -l < calls | tr -d ' ')" = 3
echo 'Release notification: upload, oversized fallback, refusal and transport checks passed.'
