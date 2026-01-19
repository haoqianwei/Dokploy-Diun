import os
import requests
import yaml
import json
import time

DOKPLOY_URL = os.getenv("DOKPLOY_URL", "http://localhost:3000")
DOKPLOY_TOKEN = os.getenv("DOKPLOY_TOKEN")
SYNC_INTERVAL = int(os.getenv("SYNC_INTERVAL", "300"))
CONFIG_DIR = os.getenv("CONFIG_DIR", "/app")

def normalize_image(image):
    if not image:
        return image
    # Add docker.io prefix if no registry is specified
    if "/" not in image or "." not in image.split("/")[0]:
        image = f"docker.io/{image}"
    # Add :latest if no tag is specified
    if ":" not in image:
        image = f"{image}:latest"
    return image

def fetch_dokploy_apps():
    headers = {
        "x-api-key": DOKPLOY_TOKEN,
        "accept": "application/json"
    }
    # Fetch all projects
    resp = requests.get(f"{DOKPLOY_URL}/api/project.all", headers=headers)
    resp.raise_for_status()
    projects = resp.json()
    
    apps = []
    for project in projects:
        environments = project.get("environments", [])
        for env in environments:
            project_apps = env.get("applications", [])
            for app in project_apps:
                # We only care about apps using docker images
                if app.get("sourceType") == "docker" or app.get("dockerImage"):
                    apps.append({
                        "name": app.get("name"),
                        "image": normalize_image(app.get("dockerImage")),
                        "webhook": f"{DOKPLOY_URL}/api/application.deploy?applicationId={app.get('applicationId')}"
                    })
    return apps

def generate_diun_config(apps):
    config = {
        "watch": {
            "workers": 10,
            "schedule": "0 */6 * * *",
            "firstCheckNotif": False
        },
        "notifiers": {
            "script": {
                "cmd": "/app/scripts/notifier.sh"
            }
        },
        "providers": {
            "file": {
                "filename": "/app/diun_images.yml"
            }
        }
    }
    
    images_config = {
        "images": []
    }
    
    webhook_map = {} # image -> list of webhooks
    
    for app in apps:
        img = app["image"]
        if not img:
            continue
            
        if img not in webhook_map:
            webhook_map[img] = []
            images_config["images"].append({
                "name": img
            })
        
        # Add webhook if not already in the list for this image
        if app["webhook"] not in webhook_map[img]:
            webhook_map[img].append(app["webhook"])
        
    with open(f"{CONFIG_DIR}/diun.yml", "w") as f:
        yaml.dump(config, f)
        
    with open(f"{CONFIG_DIR}/diun_images.yml", "w") as f:
        yaml.dump(images_config, f)
        
    with open(f"{CONFIG_DIR}/webhooks.json", "w") as f:
        json.dump(webhook_map, f)

if __name__ == "__main__":
    while True:
        try:
            print("Syncing apps from Dokploy...")
            apps = fetch_dokploy_apps()
            generate_diun_config(apps)
            print(f"Synced {len(apps)} apps.")
        except Exception as e:
            print(f"Error syncing: {e}")
        time.sleep(SYNC_INTERVAL)
