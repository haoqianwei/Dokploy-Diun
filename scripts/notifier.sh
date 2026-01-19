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

WEBHOOKS=$(jq -r --arg img "$DIUN_ENTRY_IMAGE" '.[$img] | .[]' "$WEBHOOKS_FILE")

if [ -z "$WEBHOOKS" ]; then
  echo "No webhooks found for image: $DIUN_ENTRY_IMAGE"
  exit 1
fi

for WEBHOOK in $WEBHOOKS; do
  echo "Triggering Dokploy webhook: $WEBHOOK"
  curl -X POST "$WEBHOOK" \
       -H "x-api-key: $DOKPLOY_TOKEN" \
       -H "accept: application/json" \
       -H "Content-Type: application/json"
done
