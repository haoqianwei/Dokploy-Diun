#!/bin/sh

# Start sync script in background
python3 /app/src/sync.py &

# Wait for initial config generation
echo "Waiting for initial config generation..."
while [ ! -f /app/diun.yml ]; do
  sleep 1
done

# Start Diun
# Diun flags:
# --config: path to config file
exec /usr/local/bin/diun serve --config /app/diun.yml
