#!/usr/bin/env bash
# 012-chrome-disable-keyring.sh -- stop Chrome from blocking on the
# gnome-keyring / kwallet unlock prompt at startup.
#
# Chrome on Linux tries to unlock gnome-keyring / kwallet to decrypt its
# saved-password store. On a LightDM-autologin XFCE session with no
# interactive keyring daemon init, that dialog is unanswerable and freezes
# the browser before it ever renders a page. --password-store=basic makes
# Chrome use plaintext storage and skip the keyring entirely. Safe here:
# single-user VM, no sensitive creds in Chrome's own password manager.
#
# Strategy: install a PATH-first wrapper that prepends the flag on every
# launch, and patch the desktop-entry Exec lines so XFCE panel clicks pick
# up the same path. Agent launches use an absolute path from openclaw.json,
# which a separate edit (and the shipped defaults) points at the wrapper.
# Idempotent.
set -euo pipefail

WRAPPER=/usr/local/bin/google-chrome-stable
APT_BIN=/usr/bin/google-chrome-stable

# 1. Install the wrapper.
read -r -d '' WANT <<'WRAP' || true
#!/bin/bash
exec /usr/bin/google-chrome-stable --password-store=basic "$@"
WRAP

if [[ ! -x "$WRAPPER" ]] || ! diff -q <(printf '%s' "$WANT") "$WRAPPER" >/dev/null 2>&1; then
    printf '%s' "$WANT" > "$WRAPPER"
    chmod 0755 "$WRAPPER"
    echo "[update-012] installed wrapper at $WRAPPER"
else
    echo "[update-012] wrapper already current"
fi

# 2. Patch /usr/share/applications/google-chrome.desktop so any XFCE panel
#    / menu launcher also picks up the flag (they use absolute paths).
DESKTOP=/usr/share/applications/google-chrome.desktop
if [[ -f "$DESKTOP" ]]; then
    if grep -q "$APT_BIN" "$DESKTOP"; then
        sed -i.bak "s|$APT_BIN|$WRAPPER|g" "$DESKTOP"
        echo "[update-012] rewrote Exec= paths in $DESKTOP"
    else
        echo "[update-012] $DESKTOP already using $WRAPPER (or absent)"
    fi
fi

# 3. Point the live agent config at the wrapper too. Fresh VMs will already
#    have this from vm-runtime/defaults; existing data disks need a patch.
LIVE_CONFIG="/mnt/claw-data/$(basename /mnt/claw-data/openclaw 2>/dev/null || echo openclaw)"
LIVE_CONFIG="${LIVE_CONFIG%/}/openclaw.json"
if [[ -f "$LIVE_CONFIG" ]]; then
    if grep -q "\"$WRAPPER\"" "$LIVE_CONFIG"; then
        echo "[update-012] live config already points at wrapper"
    else
        sed -i.bak "s|\"$APT_BIN\"|\"$WRAPPER\"|g" "$LIVE_CONFIG"
        chown azureuser:azureuser "$LIVE_CONFIG"
        echo "[update-012] patched browser.executablePath in live config"
        if systemctl is-active --quiet openclaw-gateway 2>/dev/null; then
            systemctl restart openclaw-gateway
            echo "[update-012] restarted openclaw-gateway to reload config"
        fi
    fi
fi

# 4. If Chrome is currently running under the old path, kill it so the next
#    launch goes through the wrapper. The agent will respawn Chrome on demand.
if pgrep -f "$APT_BIN" >/dev/null 2>&1; then
    pkill -f "$APT_BIN" || true
    echo "[update-012] killed stale Chrome processes (will relaunch via wrapper)"
fi
