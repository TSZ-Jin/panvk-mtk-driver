#!/bin/bash
set -e
cd "$HOME/panvk/mesa"

export PATH="/usr/lib/llvm-18/bin:$PATH"

if [ -d build-compiler ]; then
  echo "build-compiler exists, skipping setup"
else
  echo "=== meson setup build-compiler ==="
  meson setup build-compiler \
    -Dprefix=/tmp/mesa-compiler \
    -Dbuildtype=release \
    -Dstrip=true \
    -Dplatforms= \
    -Dgallium-drivers= \
    -Dvulkan-drivers= \
    -Dmesa-clc=enabled \
    -Dinstall-mesa-clc=true \
    -Dtools=panfrost \
    -Dprecomp-compiler=enabled \
    -Dinstall-precomp-compiler=true
fi

echo "=== meson compile ==="
meson compile -C build-compiler

echo "=== meson install ==="
meson install -C build-compiler

echo "=== installed tools ==="
ls -la /tmp/mesa-compiler/bin/
echo "OFFLINE_BUILD_DONE"
