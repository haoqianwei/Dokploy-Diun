# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Dokploy-Diun Auto Updater is a Docker-based service that automates image updates for Dokploy applications using [Diun](https://github.com/crazy-max/diun). The system synchronizes Docker applications from Dokploy's API, monitors their images for updates, and triggers automatic deployments via webhooks.

## Core Architecture

The system runs as a single Docker container with two concurrent processes:

1. **Sync Loop** (`scripts/sync.sh`): Continuously polls Dokploy API to fetch Docker-based applications and generates configuration files
2. **Diun Service**: Monitors Docker images for updates and executes the notifier script when updates are detected

### Key Components

- **scripts/entrypoint.sh**: Container entrypoint that starts both the sync loop (background) and Diun service (foreground)
- **scripts/sync.sh**: Fetches applications from Dokploy API, normalizes image names, generates:
  - `diun.yml`: Diun configuration with cron schedule and notifier script (only if not already present - allows custom config mounting)
  - `diun_images.yml`: List of unique Docker images to monitor
  - `webhooks.json`: Mapping of images to their associated application IDs/names
- **scripts/notifier.sh**: Webhook handler invoked by Diun when image updates are detected; triggers Dokploy deployments via API
- **diun.yml.example**: Example configuration file showing how to configure custom notifiers (Telegram, Discord, Slack, etc.)

### Data Flow

```
Dokploy API → sync.sh → {diun.yml, diun_images.yml, webhooks.json}
                              ↓
                         Diun monitors images
                              ↓
                    Image update detected → notifier.sh → Dokploy deployment API
```

## Development Commands

### Testing
```bash
# Manual integration test (mocks curl to verify notifier behavior)
cd tests && ./verify.sh
```

### Building
```bash
# Build Docker image
docker build -t dokploy-diun .
```

### Running Locally
```bash
# Required environment variables:
# DOKPLOY_URL - Your Dokploy instance URL
# DOKPLOY_TOKEN - API token from Dokploy Dashboard (Profile → API/CLI Section)

docker run -e DOKPLOY_URL=https://dokploy.example.com \
           -e DOKPLOY_TOKEN=your-token \
           dokploy-diun
```

## Important Implementation Details

### Image Normalization
Both `sync.sh` and the previous Python implementation normalize Docker image names consistently:
- Adds `docker.io/` prefix if no registry is specified
- Appends `:latest` tag if no tag is specified
- This ensures images like `nginx` → `docker.io/nginx:latest` for consistent matching

### API Integration
- **Dokploy API Authentication**: Uses `x-api-key` header with `DOKPLOY_TOKEN`
- **Fetch Applications**: `GET /api/project.all` returns nested structure (projects → environments → applications)
- **Trigger Deployment**: `POST /api/application.deploy` with JSON body containing `applicationId`, `title`, and `description`

### Configuration Files
All generated files are written to `CONFIG_DIR` (default: `/app`):
- Shell scripts use `jq` for JSON processing
- Image de-duplication happens via `jq`'s `unique_by(.name)`
- Webhook mapping groups applications by their normalized image name

### Custom Configuration Support
The system supports two configuration modes:

1. **Default Mode (Environment Variables)**:
   - If no `diun.yml` file exists at startup, `sync.sh` generates a default configuration
   - Uses `DIUN_SCHEDULE` environment variable for cron schedule
   - Only includes the script notifier for Dokploy deployments

2. **Custom Mode (File Mounting)**:
   - Users can mount a custom `diun.yml` file to `/app/diun.yml`
   - When detected, `sync.sh` skips generation and uses the mounted file
   - Allows advanced features like Telegram, Discord, Slack notifications
   - `DIUN_SCHEDULE` environment variable is ignored (must be set in the config file)
   - **Important**: Custom configs must retain the `script` notifier to ensure deployments are triggered

See `diun.yml.example` for a complete configuration template with multiple notifier examples.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOKPLOY_URL` | `http://host.docker.internal:3000` | Dokploy instance URL |
| `DOKPLOY_TOKEN` | (empty) | API authentication token |
| `SYNC_INTERVAL` | `300` | Seconds between Dokploy API syncs |
| `DIUN_SCHEDULE` | `0 */6 * * *` | Cron schedule for image update checks |
| `CONFIG_DIR` | `/app` | Directory for generated configuration files |

## Migration Notes

The project was migrated from Python (`src/sync.py`) to shell scripts (`scripts/sync.sh`). The shell implementation:
- Uses `jq` for JSON manipulation instead of Python's `json` module
- Maintains identical normalization logic and output format
- Provides the same de-duplication and webhook mapping functionality
