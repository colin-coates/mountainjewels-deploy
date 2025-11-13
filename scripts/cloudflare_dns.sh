#!/usr/bin/env bash
# Small helper to manage Cloudflare DNS records via API.
# Usage:
#  ZONE=mountainjewels.com CF_API_TOKEN=... NAME=app CONTENT=TARGET ./scripts/cloudflare_dns.sh create-cname
set -euo pipefail

CF_API_TOKEN="${CF_API_TOKEN:-}"
ZONE="${ZONE:-}"
NAME="${NAME:-}"
CONTENT="${CONTENT:-}"
TYPE="${TYPE:-CNAME}"
TTL="${TTL:-120}"
PROXIED="${PROXIED:-false}"

CF_API="https://api.cloudflare.com/client/v4"

get_zone_id() {
  curl -s -X GET "$CF_API/zones?name=$ZONE" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id'
}

get_record() {
  local ZID
  ZID=$(get_zone_id)
  curl -s -X GET "$CF_API/zones/$ZID/dns_records?name=${NAME}.${ZONE}" \
    -H "Authorization: Bearer $CF_API_TOKEN" -H "Content-Type: application/json"
}

create_cname() {
  local ZID
  ZID=$(get_zone_id)
  curl -s -X POST "$CF_API/zones/$ZID/dns_records" \
    -H "Authorization: Bearer $CF_API_TOKEN" -H "Content-Type: application/json" \
    --data "$(jq -n --arg type "$TYPE" --arg name "$NAME" --arg content "$CONTENT" --argjson ttl "$TTL" --argjson proxied "$PROXIED" \
      '{type:$type, name:$name, content:$content, ttl:$ttl, proxied:$proxied}')" | jq
}

update_record() {
  local ZID RID
  ZID=$(get_zone_id)
  RID=$(get_record | jq -r '.result[0].id')
  if [[ "$RID" == "null" || -z "$RID" ]]; then
    echo "No existing record found for ${NAME}.${ZONE}" >&2
    exit 3
  fi
  curl -s -X PUT "$CF_API/zones/$ZID/dns_records/$RID" \
    -H "Authorization: Bearer $CF_API_TOKEN" -H "Content-Type: application/json" \
    --data "$(jq -n --arg type "$TYPE" --arg name "$NAME" --arg content "$CONTENT" --argjson ttl "$TTL" --argjson proxied "$PROXIED" \
      '{type:$type, name:$name, content:$content, ttl:$ttl, proxied:$proxied}')" | jq
}

delete_record() {
  local ZID RID
  ZID=$(get_zone_id)
  RID=$(get_record | jq -r '.result[0].id')
  if [[ "$RID" == "null" || -z "$RID" ]]; then
    echo "No record to delete for ${NAME}.${ZONE}"
    exit 0
  fi
  curl -s -X DELETE "$CF_API/zones/$ZID/dns_records/$RID" -H "Authorization: Bearer $CF_API_TOKEN" | jq
}

case "${1:-}" in
  get-zone-id) get_zone_id;;
  get-record) get_record;;
  create-cname) create_cname;;
  update-record) update_record;;
  delete-record) delete_record;;
  *) echo "Usage: $0 {get-zone-id|get-record|create-cname|update-record|delete-record}" >&2; exit 1;;
esac
