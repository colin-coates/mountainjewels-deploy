#!/usr/bin/env bash
# Bind a hostname to an Azure Container App and wait for validation/certificate issuance.
# Usage:
#  SUBSCRIPTION_ID=... RG=... APP=... ENV_NAME=... DOMAIN=app.mountainjewels.com ./scripts/azure_bind.sh
set -euo pipefail

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"
RG="${RG:-}"
APP="${APP:-}"
ENV_NAME="${ENV_NAME:-}"
DOMAIN="${DOMAIN:-}"
VALIDATION_METHOD="${VALIDATION_METHOD:-CNAME}"

if [[ -z "$SUBSCRIPTION_ID" || -z "$RG" || -z "$APP" || -z "$ENV_NAME" || -z "$DOMAIN" ]]; then
  echo "Missing required env vars: SUBSCRIPTION_ID RG APP ENV_NAME DOMAIN" >&2
  exit 2
fi

az account set --subscription "$SUBSCRIPTION_ID"

echo "Adding hostname to container app..."
az containerapp hostname add -g "$RG" -n "$APP" --hostname "$DOMAIN" || true

echo "Binding hostname using validation method: $VALIDATION_METHOD ..."
az containerapp hostname bind -g "$RG" -n "$APP" --hostname "$DOMAIN" --environment "$ENV_NAME" --validation-method "$VALIDATION_METHOD" || true

echo "Waiting for certificate issuance (up to ~20 minutes)..."
timeout_seconds=$((25*60))
interval=15
elapsed=0

while (( elapsed < timeout_seconds )); do
  output=$(az containerapp hostname list -g "$RG" -n "$APP" -o json)
  echo "$output" | jq -r
  cert=$(echo "$output" | jq -r --arg host "$DOMAIN" '.[] | select(.name==$host) | .certificateId // empty' || true)
  bindtype=$(echo "$output" | jq -r --arg host "$DOMAIN" '.[] | select(.name==$host) | .bindingType // empty' || true)
  if [[ -n "$cert" && "$cert" != "null" ]]; then
    echo "Certificate assigned: $cert"
    exit 0
  fi
  if [[ "$bindtype" == "SniEnabled" ]]; then
    echo "Binding is SniEnabled."
    exit 0
  fi
  echo "Pending... sleeping $interval seconds (elapsed ${elapsed}s)"
  sleep $interval
  elapsed=$((elapsed + interval))
done

echo "Timed out waiting for binding/certificate. Re-check DNS and Cloudflare proxied status." >&2
exit 3
