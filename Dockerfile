# Get the Diun binary from the official image
FROM crazymax/diun:latest AS diun

# Use Alpine as the final base to ensure tools can be installed
FROM alpine:latest

# Install Diun binary
COPY --from=diun /usr/local/bin/diun /usr/local/bin/diun

# Install Python and dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    jq \
    curl \
    tzdata

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt --break-system-packages

COPY src/ ./src/
COPY scripts/ ./scripts/
RUN chmod +x scripts/notifier.sh scripts/entrypoint.sh

# Diun config will be generated here
ENV DOKPLOY_URL="http://host.docker.internal:3000"
ENV DOKPLOY_TOKEN=""
ENV SYNC_INTERVAL="300"

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
