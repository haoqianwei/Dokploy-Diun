#!/bin/bash

echo "=== Starting Manual Verification ==="

# 1. Setup temporary testing environment
TEST_DIR=$(mktemp -d)
echo "Using temporary directory: $TEST_DIR"

# 2. Mock sync.py behavior (Manually creating webhooks.json for notifier test)
cat <<EOF > "$TEST_DIR/webhooks.json"
{
  "docker.io/nginx:latest": ["http://localhost:9999/deploy-nginx"],
  "docker.io/redis:alpine": ["http://localhost:9999/deploy-redis"]
}
EOF

# 3. Start a dummy listener in background to catch the webhook
echo "Starting mock webhook listener on port 9999..."
(nc -lk 9999 > "$TEST_DIR/received_request.txt") &
NC_PID=$!
sleep 1

# 4. Test Notifier Script
echo "Testing notifier.sh with docker.io/nginx:latest..."
export DIUN_ENTRY_IMAGE="docker.io/nginx:latest"
export DIUN_ENTRY_STATUS="update"
export WEBHOOKS_FILE="$TEST_DIR/webhooks.json"
export DOKPLOY_TOKEN="test-auth-token"

../scripts/notifier.sh

# 5. Check results
sleep 1
kill $NC_PID 2>/dev/null

if grep -q "deploy-nginx" "$TEST_DIR/received_request.txt"; then
  echo "✅ SUCCESS: Notifier correctly triggered the nginx webhook."
  if grep -q "x-api-key: test-auth-token" "$TEST_DIR/received_request.txt"; then
    echo "✅ SUCCESS: Auth token was correctly sent."
  else
    echo "❌ FAILURE: Auth token was missing or incorrect."
  fi
else
  echo "❌ FAILURE: Webhook request was not received or incorrect."
  cat "$TEST_DIR/received_request.txt"
fi

rm -rf "$TEST_DIR"
echo "=== Verification Finished ==="
