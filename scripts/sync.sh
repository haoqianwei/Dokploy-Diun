#!/bin/sh

DOKPLOY_URL=${DOKPLOY_URL:-"http://localhost:3000"}
DOKPLOY_TOKEN=${DOKPLOY_TOKEN:-""}
SYNC_INTERVAL=${SYNC_INTERVAL:-300}
DIUN_SCHEDULE=${DIUN_SCHEDULE:-"0 */6 * * *"}
CONFIG_DIR=${CONFIG_DIR:-"/app"}

# Function to normalize image names
normalize_image() {
    local img="$1"
    if [ -z "$img" ]; then
        echo ""
        return
    fi
    
    # Add docker.io prefix if no registry is specified
    if ! echo "$img" | grep -q "/"; then
         img="docker.io/$img"
    elif ! echo "$img" | cut -d'/' -f1 | grep -q "\."; then
         img="docker.io/$img"
    fi
    
    # Add :latest if no tag is specified
    if ! echo "$img" | grep -q ":"; then
        img="$img:latest"
    fi
    echo "$img"
}

sync_apps() {
    echo "Syncing apps from Dokploy..."
    
    # Fetch all projects and their environments/applications
    # We use jq to traverse the nested structure and filter applications with dockerImage
    APPS_JSON=$(curl -s -X GET "$DOKPLOY_URL/api/project.all" \
        -H "x-api-key: $DOKPLOY_TOKEN" \
        -H "accept: application/json" | \
        jq -c '[.[] | .environments[] | .applications[] | select(.dockerImage != null or .sourceType == "docker") | {name: .name, image: .dockerImage, id: .applicationId}]')

    if [ -z "$APPS_JSON" ] || [ "$APPS_JSON" = "null" ]; then
        echo "No relevant applications found or error fetching data."
        return
    fi

    # Normalize images and build the structure
    # This part uses jq to:
    # 1. Map through the applications
    # 2. Normalize the image name (using a simplified logic within jq for performance if possible, 
    #    but here we'll do it post-fetch for consistency with sync.py)
    
    # First, let's normalize the images in the JSON
    NORMALIZED_APPS=$(echo "$APPS_JSON" | jq -c 'map(.image |= (
        if . == null then .
        elif (contains("/") | not) or (split("/")[0] | contains(".") | not) then "docker.io/" + .
        else .
        end |
        if contains(":") | not then . + ":latest"
        else .
        end
    ))')

    # Generate diun_images.yml (list of unique images)
    echo "$NORMALIZED_APPS" | jq -r 'map(select(.image != null) | {name: .image}) | unique_by(.name) | .[] | "- name: " + .name' > "$CONFIG_DIR/diun_images.yml"

    # Generate webhooks.json (image -> [{id, name}])
    echo "$NORMALIZED_APPS" | jq 'reduce .[] as $item ({}; .[$item.image] += [{id: $item.id, name: $item.name}])' > "$CONFIG_DIR/webhooks.json"

    # Generate diun.yml
    cat <<EOF > "$CONFIG_DIR/diun.yml"
watch:
  workers: 10
  schedule: "$DIUN_SCHEDULE"
  firstCheckNotif: false
notif:
  script:
    cmd: /app/scripts/notifier.sh
providers:
  file:
    filename: /app/diun_images.yml
EOF

    NUM_APPS=$(echo "$NORMALIZED_APPS" | jq 'length')
    echo "Synced $NUM_APPS apps."
}

# Main loop
while true; do
    sync_apps
    sleep "$SYNC_INTERVAL"
done
