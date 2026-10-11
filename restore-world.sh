#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

ICLOUD_ROOT="${ICLOUD_ROOT:-$HOME/Library/Mobile Documents/com~apple~CloudDocs}"
BACKUP_ROOT="${BACKUP_ROOT:-$ICLOUD_ROOT/MinecraftBackups/mcserver}"

if [[ ! -d "$BACKUP_ROOT" ]]; then
  echo "No backups found at: $BACKUP_ROOT" >&2
  exit 1
fi

if lsof -nP -iTCP:25565 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Stop the Minecraft server before restoring (port 25565 is in use)." >&2
  echo "In the server console type: stop" >&2
  exit 1
fi

# Pick backup: argument or interactive list
SELECTED="${1:-}"
if [[ -z "$SELECTED" ]]; then
  echo "Available backups in iCloud:"
  i=1
  BACKUPS=()
  while IFS= read -r d; do
    [[ -n "$d" ]] || continue
    name="$(basename "$d")"
    size="$(du -sh "$d" 2>/dev/null | awk '{print $1}')"
    printf "  %2d) %s  (%s)\n" "$i" "$name" "$size"
    BACKUPS+=("$name")
    i=$((i + 1))
  done < <(ls -1dt "$BACKUP_ROOT"/*/ 2>/dev/null)

  if [[ ${#BACKUPS[@]} -eq 0 ]]; then
    echo "No backup folders found." >&2
    exit 1
  fi

  printf "Choose number (or q to cancel): "
  read -r choice
  [[ "$choice" == "q" || "$choice" == "Q" ]] && exit 0
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 || "$choice" -gt ${#BACKUPS[@]} ]]; then
    echo "Invalid choice." >&2
    exit 1
  fi
  SELECTED="${BACKUPS[$((choice - 1))]}"
fi

# Allow full path or just the stamp folder name
if [[ -d "$SELECTED/world" ]]; then
  SRC="$SELECTED"
elif [[ -d "$BACKUP_ROOT/$SELECTED/world" ]]; then
  SRC="$BACKUP_ROOT/$SELECTED"
else
  echo "Backup not found: $SELECTED" >&2
  echo "Usage: ./restore-world.sh [AAAA-MM-DD_HH-MM-SS]" >&2
  exit 1
fi

echo "Restoring from: $SRC"

# Safety snapshot of current world
if [[ -d world ]]; then
  SAFETY="world.pre-restore.$(date +%Y-%m-%d_%H-%M-%S)"
  echo "Saving current world to ./$SAFETY first..."
  mv world "$SAFETY"
fi

mkdir -p world
rsync -a "$SRC/world/" world/

# Optional: restore configs if present in backup
if [[ -d "$SRC/meta" ]]; then
  echo "Restore server.properties / ops / whitelist from backup too? [y/N]"
  read -r ans
  if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
    cp -f "$SRC/meta/"* . 2>/dev/null || true
    echo "Config files restored."
  fi
fi

echo "Restore complete."
echo "Start the server with: ./start.sh"
