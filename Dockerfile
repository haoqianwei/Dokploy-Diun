# Use the official Diun image as base
FROM crazymax/diun:latest

# Diun is based on Alpine, so we can use apk to install tools
# jq and curl are needed for the sync script
RUN apk add --no-cache \
    jq \
    curl \
    tzdata \
    bash

WORKDIR /app

# Copy scripts
COPY scripts/ ./scripts/
RUN chmod +x scripts/*.sh

# Default environment variables
ENV DOKPLOY_URL="http://host.docker.internal:3000"
ENV DOKPLOY_TOKEN=""
ENV SYNC_INTERVAL="300"
ENV DIUN_SCHEDULE="0 */6 * * *"
ENV CONFIG_DIR="/app"

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
