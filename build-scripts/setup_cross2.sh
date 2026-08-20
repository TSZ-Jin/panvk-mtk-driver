#!/bin/bash
set -e
echo '123' | sudo -S cp "$HOME/panvk/arm64.sources" /etc/apt/sources.list.d/arm64.sources
echo '123' | sudo -S apt-get update 2>&1 | tail -2

echo "=== install arm64 cross dev libs ==="
PACKS="libdrm-dev:arm64 libelf-dev:arm64 libexpat1-dev:arm64 zlib1g-dev:arm64"
for p in $PACKS; do
  echo "--- $p ---"
  echo '123' | sudo -S apt-get install -y -qq "$p" 2>&1 | tail -1
done

echo "=== x11 cross dev libs ==="
XPACKS="libx11-dev:arm64 libx11-xcb-dev:arm64 libxcb1-dev:arm64 libxcb-dri3-dev:arm64 libxcb-present-dev:arm64 libxcb-randr0-dev:arm64 libxcb-shm0-dev:arm64 libxcb-sync-dev:arm64 libxcb-xfixes0-dev:arm64 libxshmfence-dev:arm64 libxrandr-dev:arm64 libxxf86vm-dev:arm64"
for p in $XPACKS; do
  echo "--- $p ---"
  echo '123' | sudo -S apt-get install -y -qq "$p" 2>&1 | tail -1
done

echo "=== verify ==="
dpkg -l | grep -c ":arm64" || true
ls /usr/aarch64-linux-gnu/include/ | head -20
echo "DONE"
