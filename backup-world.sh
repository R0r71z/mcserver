#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

ICLOUD_ROOT="${ICLOUD_ROOT:-$HOME/Library/Mobile Documents/com~apple~CloudDocs}"
BACKUP_ROOT="${BACKUP_ROOT:-$ICLOUD_ROOT/MinecraftBackups/mcserver}"
KEEP="${KEEP:-10}"
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"
DEST="$BACKUP_ROOT/$STAMP"

if [[ ! -d world ]]; then
  echo "No world/ folder found." >&2
  exit 1
fi

if [[ ! -d "$ICLOUD_ROOT" ]]; then
  echo "iCloud Drive not found at: $ICLOUD_ROOT" >&2
  echo "Enable iCloud Drive in System Settings → Apple ID → iCloud." >&2
  exit 1
fi

if lsof -nP -iTCP:25565 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "WARNING: Minecraft server is running."
  echo "For a safer backup, run /save-all in the server console, wait a few seconds,"
  echo "or stop the server first. Continuing with a best-effort copy..."
fi

mkdir -p "$DEST"

# Copy world + useful configs (not libraries/mods jars cache)
rsync -a --delete \
  --exclude 'session.lock' \
  world/ "$DEST/world/"

mkdir -p "$DEST/meta"
cp -f server.properties eula.txt ops.json whitelist.json banned-players.json banned-ips.json \
  "$DEST/meta/" 2>/dev/null || true
if [[ -d mods ]]; then
  rsync -a mods/ "$DEST/mods/"
fi
if [[ -d journeymap ]]; then
  rsync -a journeymap/ "$DEST/journeymap/"
fi

# Prune old backups, keep newest $KEEP
if [[ -d "$BACKUP_ROOT" ]]; then
  ls -1dt "$BACKUP_ROOT"/*/ 2>/dev/null | tail -n +"$((KEEP + 1))" | while IFS= read -r d; do
    [[ -n "$d" ]] || continue
    rm -rf "$d"
  done
fi

SIZE="$(du -sh "$DEST" | awk '{print $1}')"
echo "Backup saved to iCloud:"
echo "  $DEST"
echo "  size: $SIZE (keeping last $KEEP)"
