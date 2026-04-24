#!/usr/bin/env bash
# 07-user-apps.sh -- install the extra user-facing tools present on the
# reference claw VM. App binaries belong in the install layer; only their
# config/state lives on the persistent data disk.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

install -d -m 0755 /usr/share/keyrings
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor --yes -o /usr/share/keyrings/microsoft.gpg

cat > /etc/apt/sources.list.d/vscode.sources <<'EOF'
### THIS FILE IS AUTOMATICALLY CONFIGURED ###
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

apt-get update
apt-get install -y \
  build-essential \
  python3-pip \
  unzip \
  code

wget -O /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
apt-get install -y /tmp/discord.deb
rm -f /tmp/discord.deb
