#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ -f .playitd.pid ]]; then
  pid="$(cat .playitd.pid)"
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    sleep 1
    kill -9 "$pid" 2>/dev/null || true
    echo "Stopped playitd (pid $pid)"
  fi
  rm -f .playitd.pid
fi
rm -f playit.sock
