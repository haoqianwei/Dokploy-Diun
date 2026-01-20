# Dokploy-Diun Auto Updater

Automate Docker image updates on Dokploy using [Diun](https://github.com/crazy-max/diun). This service synchronizes your Dokploy applications with Diun and triggers deployments via webhooks when updates are detected.

## Features

- **Auto-Sync**: Automatically fetches Docker-based applications from Dokploy API.
- **Image De-duplication**: Monitors each unique image once, even if used by multiple applications.
- **Bulk Updates**: Triggers all relevant Dokploy applications when a shared image is updated.
- **Secure**: Uses `x-api-key` authentication for both API access and webhook triggers.

## How It Works

1. **Sync Loop**: Periodically fetches Docker-based applications from Dokploy API
2. **Config Generation**: Creates Diun configuration with unique images and webhook mappings
3. **Image Monitoring**: Diun watches for updates based on the configured schedule
4. **Auto-Deploy**: When an update is detected, triggers deployment for all affected applications

## Project Structure

```text
.
├── Dockerfile           # Builds the all-in-one image
├── scripts/
│   ├── entrypoint.sh    # Container entrypoint
│   ├── sync.sh          # Core sync logic (fetches apps from Dokploy)
│   └── notifier.sh      # Webhook trigger script (called by Diun)
└── tests/
    └── verify.sh        # Integration test
```

## Setup

### 1. Generate Dokploy API Token
In your Dokploy Dashboard, go to **Profile -> API/CLI Section** and generate a token.

### 2. Deploy to Dokploy
Create a new Application in Dokploy from your repository. Set the following environment variables:

| Variable | Description |
|----------|-------------|
| `DOKPLOY_URL` | Your Dokploy URL (e.g., `https://dokploy.example.com`) |
| `DOKPLOY_TOKEN` | The API token generated in Step 1. |
| `SYNC_INTERVAL` | (Optional) Seconds between syncs with Dokploy. Default: `300`. |
| `DIUN_SCHEDULE` | (Optional) Cron schedule for Diun image checks. Default: `0 */6 * * *`. |

## Development & Testing

### Prerequisites
- Docker
- `jq`, `curl`, and `bash` (included in the Docker image)

### Building the Image
```bash
docker build -t dokploy-diun .
```

### Running Tests
```bash
cd tests && ./verify.sh
```

This integration test simulates Diun notifications and verifies that the notifier script correctly triggers Dokploy deployments.

## License
MIT
