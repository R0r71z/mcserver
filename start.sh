#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

export JAVA_HOME="${JAVA_HOME:-/Library/Java/JavaVirtualMachines/temurin-25.jdk/Contents/Home}"
export PATH="$JAVA_HOME/bin:$PATH"

# Optional: keep Cloudflare A record updated (not used for joins while on CGNAT + playit)
if [[ -f .env ]] && [[ "${SKIP_DNS_UPDATE:-0}" != "1" ]]; then
  ./update-dns.sh || echo "DNS update skipped/failed (OK if using playit only)."
fi

# Start playit tunnel agent if claimed
if [[ -f playit.toml ]]; then
  ./start-playit.sh
else
  echo "playit not claimed yet — friends cannot join from outside until you finish playit setup."
fi

# 6 GB heap suited for ~20 players with Fabric API + JourneyMap
exec java -Xms2G -Xmx6G \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -jar fabric-server-mc.26.3-loader.0.19.5-launcher.1.1.2.jar nogui
