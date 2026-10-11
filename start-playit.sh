#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

PLAYITD_BIN="${PLAYITD_BIN:-./bin/playitd}"
SOCKET_PATH="${PLAYIT_SOCKET:-./playit.sock}"
SECRET_PATH="${PLAYIT_SECRET:-./playit.toml}"
LOG_PATH="${PLAYIT_LOG:-./logs/playitd.log}"

mkdir -p logs

if [[ ! -x "$PLAYITD_BIN" ]]; then
  echo "Missing $PLAYITD_BIN — build playit first (see README)." >&2
  exit 1
fi

if [[ ! -f "$SECRET_PATH" ]]; then
  echo "No playit secret at $SECRET_PATH." >&2
  echo "Claim the agent first:" >&2
  echo "  1) ./bin/playitd --socket-path=$SOCKET_PATH --secret-path=$SECRET_PATH -l $LOG_PATH &" >&2
  echo "  2) CODE=\$(./bin/playit claim generate)" >&2
  echo "  3) open \"\$(./bin/playit claim url --name mcserver --type self-managed \"\$CODE\")\"" >&2
  echo "  4) ./bin/playit --socket-path=$SOCKET_PATH claim exchange \"\$CODE\"" >&2
  echo "     (or: ./bin/playit --socket-path=$SOCKET_PATH setup)" >&2
  exit 1
fi

if [[ -S "$SOCKET_PATH" ]]; then
  if [[ -f .playitd.pid ]] && kill -0 "$(cat .playitd.pid)" 2>/dev/null; then
    echo "playitd already running (pid $(cat .playitd.pid))"
    exit 0
  fi
  rm -f "$SOCKET_PATH"
fi

nohup "$PLAYITD_BIN" \
  --socket-path="$SOCKET_PATH" \
  --secret-path="$SECRET_PATH" \
  -l "$LOG_PATH" \
  >/dev/null 2>&1 &
echo $! > .playitd.pid
echo "playitd started (pid $(cat .playitd.pid))"
echo "Logs: $LOG_PATH"
echo "Create a Minecraft Java tunnel at https://playit.gg/account/tunnels if you have not already."
