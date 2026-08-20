#!/bin/bash
set -x
echo '123' | sudo -S dpkg --add-architecture arm64
echo '123' | sudo -S apt-get update -qq 2>/dev/null

echo "=== install cross toolchain ==="
echo '123' | sudo -S apt-get install -y -qq crossbuild-essential-arm64 2>&1 | tail -3

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
aarch64-linux-gnu-gcc --version | head -1
ls /usr/aarch64-linux-gnu/ | head
echo "DONE"
