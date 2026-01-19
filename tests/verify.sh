#!/bin/bash

echo "=== Starting Manual Verification ==="

# 1. Setup temporary testing environment
TEST_DIR=$(mktemp -d)
echo "Using temporary directory: $TEST_DIR"

# 2. Mock sync.py behavior (Manually creating webhooks.json for notifier test)
cat <<EOF > "$TEST_DIR/webhooks.json"
{
  "docker.io/nginx:latest": [{"id": "app-id-nginx", "name": "Nginx App"}],
  "docker.io/redis:alpine": [{"id": "app-id-redis", "name": "Redis App"}]
}
EOF

# 3. Create a mock curl to capture requests
mkdir -p "$TEST_DIR/bin"
cat <<EOF > "$TEST_DIR/bin/curl"
#!/bin/bash
echo "CURL ARGS: \$*" >> "$TEST_DIR/received_request.txt"
EOF
chmod +x "$TEST_DIR/bin/curl"
export PATH="$TEST_DIR/bin:$PATH"

# 4. Test Notifier Script
echo "Testing notifier.sh with docker.io/nginx:latest..."
export DIUN_ENTRY_IMAGE="docker.io/nginx:latest"
export DIUN_ENTRY_STATUS="update"
export WEBHOOKS_FILE="$TEST_DIR/webhooks.json"
export DOKPLOY_TOKEN="test-auth-token"
export DOKPLOY_URL="http://localhost:9999"

../scripts/notifier.sh

# 5. Check results
if grep -q "app-id-nginx" "$TEST_DIR/received_request.txt" && grep -q "Diun Update" "$TEST_DIR/received_request.txt"; then
  echo "✅ SUCCESS: Notifier correctly sent the JSON body with applicationId."
  if grep -q "x-api-key: test-auth-token" "$TEST_DIR/received_request.txt"; then
    echo "✅ SUCCESS: Auth token was correctly sent."
  else
    echo "❌ FAILURE: Auth token was missing or incorrect."
    echo "Captured request content:"
    cat "$TEST_DIR/received_request.txt"
  fi
else
  echo "❌ FAILURE: Webhook request was not received or incorrect."
  echo "Captured request content:"
  cat "$TEST_DIR/received_request.txt"
fi

rm -rf "$TEST_DIR"
echo "=== Verification Finished ==="
