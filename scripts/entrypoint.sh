#!/bin/sh

# Start sync script in background
/app/scripts/sync.sh &

# Wait for initial config generation
echo "Waiting for initial config generation..."
while [ ! -f /app/diun.yml ] || [ ! -f /app/diun_images.yml ]; do
  sleep 1
done

echo "Configuration files ready. Starting Diun..."

# Start Diun
exec /usr/local/bin/diun serve --config /app/diun.yml

