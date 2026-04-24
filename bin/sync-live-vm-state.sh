#!/usr/bin/env bash
# sync-live-vm-state.sh -- copy live, non-secret claw state from the mounted
# data disk back into vm-runtime/defaults so the repo matches the running VM.
#
# Intentionally excluded:
#   - /mnt/claw-data/openclaw/.env
#   - device identity / auth tokens
#   - runtime DBs, logs, media, tasks, browser cache
#   - gateway / exec socket tokens
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIVE_OPENCLAW="${LIVE_OPENCLAW:-/mnt/claw-data/openclaw}"
LIVE_WS="${LIVE_WS:-/mnt/claw-data/workspace}"
DEFAULTS_DIR="${ROOT}/vm-runtime/defaults"
OPENCLAW_DEFAULTS="${DEFAULTS_DIR}/openclaw"
WORKSPACE_DEFAULTS="${DEFAULTS_DIR}/workspace"

need_path() {
    local path="$1"
    if [[ ! -e "$path" ]]; then
        echo "missing required path: $path" >&2
        exit 1
    fi
}

need_path "${LIVE_OPENCLAW}/openclaw.json"
need_path "${LIVE_OPENCLAW}/exec-approvals.json"
need_path "${LIVE_WS}"

mkdir -p "${OPENCLAW_DEFAULTS}" "${WORKSPACE_DEFAULTS}"

tmp="$(mktemp)"
jq '
  del(.gateway.auth.token)
  | del(.plugins.installs)
  | del(.meta)
' "${LIVE_OPENCLAW}/openclaw.json" > "${tmp}"
mv "${tmp}" "${OPENCLAW_DEFAULTS}/openclaw.json"

tmp="$(mktemp)"
jq 'del(.socket.token)' "${LIVE_OPENCLAW}/exec-approvals.json" > "${tmp}"
mv "${tmp}" "${OPENCLAW_DEFAULTS}/exec-approvals.json"

if [[ -f "${LIVE_OPENCLAW}/acpx/codex-acp-wrapper.mjs" ]]; then
    install -D -m 0644 \
        "${LIVE_OPENCLAW}/acpx/codex-acp-wrapper.mjs" \
        "${OPENCLAW_DEFAULTS}/acpx/codex-acp-wrapper.mjs"
fi

# CLAUDE.md and TOOLS.md are hand-maintained system maps. The live copies may
# lag behind the actual config, so keep them curated in-repo instead of blindly
# copying them back from disk.
for file in AGENTS.md HEARTBEAT.md IDENTITY.md SOUL.md USER.md; do
    if [[ -f "${LIVE_WS}/${file}" ]]; then
        install -D -m 0644 "${LIVE_WS}/${file}" "${WORKSPACE_DEFAULTS}/${file}"
    fi
done

for rel in .claude/settings.local.json .clawhub/lock.json .openclaw/workspace-state.json; do
    if [[ -f "${LIVE_WS}/${rel}" ]]; then
        install -D -m 0644 "${LIVE_WS}/${rel}" "${WORKSPACE_DEFAULTS}/${rel}"
    fi
done

if [[ -d "${LIVE_WS}/skills" ]]; then
    mkdir -p "${WORKSPACE_DEFAULTS}/skills"
    rsync -a --delete "${LIVE_WS}/skills/" "${WORKSPACE_DEFAULTS}/skills/"
fi

if [[ -d "${LIVE_OPENCLAW}/skills" ]]; then
    mkdir -p "${OPENCLAW_DEFAULTS}/skills"
    rsync -a --delete "${LIVE_OPENCLAW}/skills/" "${OPENCLAW_DEFAULTS}/skills/"
fi

echo "Synced live VM state into ${DEFAULTS_DIR}"
