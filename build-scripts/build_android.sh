#!/bin/bash
set -e
export PATH="$HOME/panvk/mesa-compiler/bin:$HOME/.local/bin:$PATH"
export PATH="/usr/lib/llvm-18/bin:$PATH"

cd "$HOME/panvk/mesa"

rm -rf build-android-aarch64

echo "=== meson setup (cross) ==="
meson setup build-android-aarch64 \
  --cross-file "$HOME/panvk/android-aarch64.ini" \
  -Dplatforms=android \
  -Dplatform-sdk-version=34 \
  -Dandroid-stub=true \
  -Dandroid-libbacktrace=disabled \
  -Degl=disabled \
  -Dgallium-drivers=panfrost \
  -Dvulkan-drivers=panfrost \
  -Dallow-fallback-for=libdrm \
  -Dmesa-clc=system \
  -Dprecomp-compiler=system

echo "=== meson compile (cross) ==="
meson compile -C build-android-aarch64

echo "=== outputs ==="
find build-android-aarch64/src -name "*.so" | head -30
echo "ANDROID_BUILD_DONE"
