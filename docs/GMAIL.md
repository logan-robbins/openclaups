# Gmail / Google Workspace Setup (gog CLI)

Setting up Gmail access for a claw is a manual, multi-step OAuth flow that cannot be fully automated. This document exists because the process is fragile and easy to get wrong.

## Prerequisites

- A dedicated Gmail account for the claw (e.g. `chadclaugh@gmail.com`)
- A Google Cloud OAuth client secret JSON file (Desktop app type)
  - Create at https://console.cloud.google.com → APIs & Services → Credentials
  - Enable Gmail API, Calendar API, Drive API, Contacts API, Sheets API, Docs API
  - Download the client secret JSON
- `gogcli` installed on the VM (`pip install gogcli` or pre-baked in the image)
- `KEYRING_PASSWORD` set in the claw's `.env` file
- `GOG_KEYRING_PASSWORD` must match `KEYRING_PASSWORD` — gog uses file-based keyring since there's no desktop keyring on a headless VM

## Why this is painful

1. **OAuth requires a browser.** The VM is headless. You can't just run `gog auth add` and click through — there's no browser session connected to the OAuth redirect.
2. **gogcli has a remote auth mode** that splits the flow into two steps, but the state between steps expires quickly. You must complete both steps in one sitting.
3. **The file keyring needs a password** passed via `GOG_KEYRING_PASSWORD` env var. Without it, gog silently fails with "no TTY available for keyring file backend password prompt."
4. **sudo must preserve HOME and env vars.** Running as root with `sudo` points HOME to `/root`, which breaks gog's config lookup. Use `sudo -u azureuser bash -c '...'` with exports inside the subshell.
5. **The gog skill can trigger runaway loops** if auth isn't set up yet. The agent tries to use gog, gog fails, the agent retries, and the loop detection (if disabled) won't catch it. Make sure loop detection is enabled before deploying gog.

## Setup procedure

All commands run on the VM via SSH. Use the SCP-script approach to avoid CrowdStrike keyword blocking.

### 1. Store the client secret on the data disk

```bash
# From your local machine
scp client_secret_*.json azureuser@<IP>:/tmp/client_secret.json

# On the VM
sudo cp /tmp/client_secret.json /mnt/claw-data/openclaw/client_secret.json
sudo chmod 600 /mnt/claw-data/openclaw/client_secret.json
sudo chown azureuser:azureuser /mnt/claw-data/openclaw/client_secret.json
```

### 2. Configure gog

Create a script on the VM and run it:

```bash
sudo -u azureuser bash -c '
export GOG_KEYRING_PASSWORD="<your KEYRING_PASSWORD from .env>"
export HOME=/home/azureuser
gog auth credentials /mnt/claw-data/openclaw/client_secret.json
gog config set keyring_backend file
'
```

### 3. Remote OAuth — Step 1

```bash
sudo -u azureuser bash -c '
export GOG_KEYRING_PASSWORD="<your KEYRING_PASSWORD>"
export HOME=/home/azureuser
gog auth add <email> --services gmail,calendar,drive,contacts,sheets,docs --force-consent --remote --step 1
'
```

This prints an `auth_url`. Copy it.

### 4. Authorize in your browser

1. Open the auth URL in your **local** browser (not the VM)
2. Log in as the claw's Gmail account
3. Grant all permissions
4. The browser redirects to `http://127.0.0.1:<port>/oauth2/callback?...` — this page won't load (expected, it's the VM's localhost)
5. **Copy the full URL from the browser address bar immediately**

### 5. Remote OAuth — Step 2

Run this immediately after step 4 (the auth state expires quickly):

```bash
sudo -u azureuser bash -c '
export GOG_KEYRING_PASSWORD="<your KEYRING_PASSWORD>"
export HOME=/home/azureuser
gog auth add <email> \
  --services gmail,calendar,drive,contacts,sheets,docs \
  --force-consent \
  --remote --step 2 \
  --auth-url "<paste the full redirect URL here>"
'
```

If you see `manual auth state missing`, the state expired. Go back to step 3.

### 6. Verify

```bash
sudo -u azureuser bash -c '
export GOG_KEYRING_PASSWORD="<your KEYRING_PASSWORD>"
export HOME=/home/azureuser
gog auth list
'
```

Should show the email with services `calendar,contacts,docs,drive,gmail,sheets`.

### 7. Restart the gateway

```bash
sudo systemctl restart openclaw-gateway
```

## What persists across VM replacements

- **Client secret:** `/mnt/claw-data/openclaw/client_secret.json` — on data disk
- **gog config:** `~/.config/gogcli/` — this is in the home directory, NOT on the data disk. After a VM replacement, you need to re-run steps 2-6.
- **gog keyring (tokens):** `~/.config/gogcli/keyring/` — same problem, lives in home directory

## Known issue: gog config not on data disk

The gog config and token keyring live in `~/.config/gogcli/`, which is on the OS disk and does NOT survive VM replacements. This means **you must redo the OAuth flow after every image upgrade.**

A future fix would be to symlink or bind-mount `~/.config/gogcli/` to the data disk, similar to what we do for `~/.openclaw`. This is not yet implemented.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `no TTY available for keyring file backend password prompt` | `GOG_KEYRING_PASSWORD` not set | Export it before running gog |
| `read config: open /root/.config/gogcli/config.json: permission denied` | Running as root instead of azureuser | Use `sudo -u azureuser bash -c '...'` with `HOME=/home/azureuser` |
| `manual auth state missing` | Too slow between step 1 and step 2 | Redo from step 3, complete both steps quickly |
| Agent stuck in runaway loop trying to use gog | gog auth not set up, loop detection off | Stop the gateway, enable loop detection, set up auth |
| `store token: no TTY available` | Same as first row | Same fix |

## Checklist for new claw deploys

- [ ] Gmail account created for the claw
- [ ] Google Cloud project with OAuth client secret (Desktop app type)
- [ ] APIs enabled: Gmail, Calendar, Drive, Contacts, Sheets, Docs
- [ ] Client secret JSON stored at `/mnt/claw-data/openclaw/client_secret.json`
- [ ] `KEYRING_PASSWORD` set in `.env`
- [ ] `gog auth credentials` pointed at the client secret
- [ ] `gog config set keyring_backend file`
- [ ] Remote OAuth flow completed (steps 3-5)
- [ ] `gog auth list` shows the account with all services
- [ ] Gateway restarted
- [ ] Loop detection enabled in config (`tools.loopDetection.enabled: true`)
