#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a
  source .env
  set +a
fi

: "${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN in .env (see .env.example)}"
: "${CF_ZONE_NAME:=r0r71z.dev}"
: "${CF_HOSTNAME:=mc.r0r71z.dev}"

API="https://api.cloudflare.com/client/v4"
AUTH=("Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" "Content-Type: application/json")

cf_get() {
  curl -fsS -H "${AUTH[0]}" -H "${AUTH[1]}" "$1"
}

cf_json() {
  local method="$1" url="$2" body="${3:-}"
  if [[ -n "$body" ]]; then
    curl -fsS -X "$method" -H "${AUTH[0]}" -H "${AUTH[1]}" --data "$body" "$url"
  else
    curl -fsS -X "$method" -H "${AUTH[0]}" -H "${AUTH[1]}" "$url"
  fi
}

echo "Detecting public IP..."
PUBLIC_IP="$(curl -fsS https://api.ipify.org)"
if [[ ! "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Failed to detect a valid public IPv4 (got: ${PUBLIC_IP})" >&2
  exit 1
fi
echo "Public IP: ${PUBLIC_IP}"

echo "Resolving zone ${CF_ZONE_NAME}..."
ZONE_JSON="$(cf_get "${API}/zones?name=${CF_ZONE_NAME}&status=active")"
ZONE_ID="$(python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("result") or []; print(r[0]["id"] if r else "")' <<<"$ZONE_JSON")"
if [[ -z "$ZONE_ID" ]]; then
  echo "Zone not found or token lacks access: ${CF_ZONE_NAME}" >&2
  exit 1
fi

echo "Looking up A record for ${CF_HOSTNAME}..."
REC_JSON="$(cf_get "${API}/zones/${ZONE_ID}/dns_records?type=A&name=${CF_HOSTNAME}")"
REC_ID="$(python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("result") or []; print(r[0]["id"] if r else "")' <<<"$REC_JSON")"
CURRENT_IP="$(python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("result") or []; print(r[0]["content"] if r else "")' <<<"$REC_JSON")"

PAYLOAD="$(python3 -c 'import json,sys; print(json.dumps({"type":"A","name":sys.argv[1],"content":sys.argv[2],"ttl":120,"proxied":False}))' "$CF_HOSTNAME" "$PUBLIC_IP")"

if [[ -z "$REC_ID" ]]; then
  echo "Creating A record ${CF_HOSTNAME} -> ${PUBLIC_IP} (DNS only)..."
  RESULT="$(cf_json POST "${API}/zones/${ZONE_ID}/dns_records" "$PAYLOAD")"
  python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("success") else 1)' <<<"$RESULT"
  echo "Created ${CF_HOSTNAME} -> ${PUBLIC_IP}"
  exit 0
fi

if [[ "$CURRENT_IP" == "$PUBLIC_IP" ]]; then
  # Ensure proxy stays off even if IP unchanged
  PROXIED="$(python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("result") or []; print("true" if r and r[0].get("proxied") else "false")' <<<"$REC_JSON")"
  if [[ "$PROXIED" == "false" ]]; then
    echo "DNS already up to date: ${CF_HOSTNAME} -> ${PUBLIC_IP}"
    exit 0
  fi
fi

echo "Updating A record ${CF_HOSTNAME}: ${CURRENT_IP:-none} -> ${PUBLIC_IP} (DNS only)..."
RESULT="$(cf_json PUT "${API}/zones/${ZONE_ID}/dns_records/${REC_ID}" "$PAYLOAD")"
python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("success") else 1)' <<<"$RESULT"
echo "Updated ${CF_HOSTNAME} -> ${PUBLIC_IP}"
