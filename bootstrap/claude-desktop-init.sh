#!/usr/bin/env bash
# ~/prog/distrobox/claude-desktop-init.sh
#
# Runs as root inside the claude-desktop container during distrobox init.
# Referenced by init_hooks in distrobox.ini.
#
# This can't live in additional_packages: claude-desktop comes from a
# third-party apt repo that has to be added first.
#
# Deliberately ONE hook script rather than several init_hooks lines —
# multiple init_hooks in one assemble file have a history of being fragile
# (89luca89/distrobox#844, #1673).

set -euo pipefail

KEYRING="/usr/share/keyrings/claude-desktop-archive-keyring.asc"
EXPECTED_FP="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"
REPO="https://downloads.claude.ai/claude-desktop/apt/stable"

curl -fsSLo "$KEYRING" https://downloads.claude.ai/claude-desktop/key.asc

# Gate on the fingerprint rather than trusting the download.
# This is the manual check from the runbook, made automatic.
if ! gpg --show-keys --with-colons "$KEYRING" | grep -q "$EXPECTED_FP"; then
    echo "FATAL: Claude Desktop signing key does not match expected fingerprint" >&2
    echo "  expected: $EXPECTED_FP" >&2
    gpg --show-keys "$KEYRING" >&2
    exit 1
fi

echo "deb [arch=amd64,arm64 signed-by=${KEYRING}] ${REPO} stable main" \
    > /etc/apt/sources.list.d/claude-desktop.list

apt-get update
apt-get install -y claude-desktop git

# qemu-system-x86, ovmf and virtiofsd arrive as recommends — Cowork's local
# KVM workspace VM needs them. Confirm after a rebuild:
#   dpkg -l qemu-system-x86 ovmf virtiofsd
