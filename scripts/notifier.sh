#!/bin/bash

# Environment variables from Diun:
# DIUN_ENTRY_IMAGE
# DIUN_ENTRY_STATUS

# ENV VARS override for testing
WEBHOOKS_FILE=${WEBHOOKS_FILE:-/app/webhooks.json}

echo "Received update notification for $DIUN_ENTRY_IMAGE (Status: $DIUN_ENTRY_STATUS)"

if [ "$DIUN_ENTRY_STATUS" != "update" ] && [ "$DIUN_ENTRY_STATUS" != "new" ]; then
  echo "Ignoring status: $DIUN_ENTRY_STATUS"
  exit 0
fi

WEBHOOKS_DATA=$(jq -c --arg img "$DIUN_ENTRY_IMAGE" '.[$img] | .[]' "$WEBHOOKS_FILE")

if [ -z "$WEBHOOKS_DATA" ]; then
  echo "No webhooks found for image: $DIUN_ENTRY_IMAGE"
  exit 1
fi

echo "$WEBHOOKS_DATA" | while read -r DATA; do
  APP_ID=$(echo "$DATA" | jq -r '.id')
  APP_NAME=$(echo "$DATA" | jq -r '.name')
  
  TITLE="Diun Update: $DIUN_ENTRY_IMAGE"
  DESC="Automatically triggered by Diun for application '$APP_NAME'. Status: $DIUN_ENTRY_STATUS"
  
  echo "Triggering Dokploy deployment for: $APP_NAME (ID: $APP_ID)"
  curl -s -X POST "$DOKPLOY_URL/api/application.deploy" \
       -H "x-api-key: $DOKPLOY_TOKEN" \
       -H "accept: application/json" \
       -H "Content-Type: application/json" \
       -d "{\"applicationId\": \"$APP_ID\", \"title\": \"$TITLE\", \"description\": \"$DESC\"}"
done
