#!/usr/bin/env bash
# Quick helper to create an app registration + service principal.
# Usage: ./scripts/azure_ad_register.sh "mj-deploy-app"
set -euo pipefail

APP_NAME="${1:-mj-deploy-app}"

echo "Creating app registration: $APP_NAME"
app=$(az ad app create --display-name "$APP_NAME" --query "{appId:appId, id:id}" -o json)
appId=$(echo "$app" | jq -r .appId)
appObjectId=$(echo "$app" | jq -r .id)

echo "Creating service principal for the app..."
az ad sp create --id "$appId" -o json

echo "Creating a client secret (valid 2 years)..."
secret=$(az ad app credential reset --id "$appId" --years 2 -o json)

echo "AppId: $appId"
echo "App Object Id: $appObjectId"
echo "Secret JSON (one-time):"
echo "$secret"

cat <<EOF2
Next:
  - Assign RBAC to the SP: az role assignment create --assignee $appId --role Contributor --scope /subscriptions/<SUB>/resourceGroups/<RG>
  - If Graph application permissions are needed, an admin must grant consent.
EOF2
