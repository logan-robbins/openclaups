#!/usr/bin/env bash
# 018-sync-openclaw-support-files.sh -- sync vendored OpenClaw support files
# (for example ACP helper wrappers) onto existing persistent data disks.
set -euo pipefail

DEFAULTS="/opt/claw/defaults/openclaw"
OPENCLAW_DIR="/mnt/claw-data/openclaw"

if [[ -d "${DEFAULTS}/acpx" ]]; then
    install -d -o azureuser -g azureuser -m 0755 "${OPENCLAW_DIR}/acpx"
    cp -a "${DEFAULTS}/acpx/." "${OPENCLAW_DIR}/acpx/"
    chown -R azureuser:azureuser "${OPENCLAW_DIR}/acpx"
    echo "[update-018] Synced vendored OpenClaw support files"
else
    echo "[update-018] No vendored OpenClaw support files to sync"
fi
