# Dokploy-Diun Auto Updater

Automate Docker image updates on Dokploy using [Diun](https://github.com/crazy-max/diun). This service synchronizes your Dokploy applications with Diun and triggers deployments via webhooks when updates are detected.

## Features

- **Auto-Sync**: Automatically fetches Docker-based applications from Dokploy API.
- **Image De-duplication**: Monitors each unique image once, even if used by multiple applications.
- **Bulk Updates**: Triggers all relevant Dokploy applications when a shared image is updated.
- **Secure**: Uses `x-api-key` authentication for both API access and webhook triggers.

## Project Structure

```text
.
├── Dockerfile           # Builds the all-in-one image
├── requirements.txt     # Python dependencies
├── scripts/
│   ├── entrypoint.sh    # Container entrypoint
│   └── notifier.sh      # Webhook trigger script
├── src/
│   └── sync.py          # Core sync logic
└── tests/
    ├── test_sync.py     # Unit tests
    └── verify.sh        # Integration simulation
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

### Local Setup
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Running Tests
- **Unit Tests**: `python3 tests/test_sync.py`
- **Manual Verification**: `cd tests && ./verify.sh`

## License
MIT
