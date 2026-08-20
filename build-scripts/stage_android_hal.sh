#!/bin/bash
set -e
cd "$HOME/mesa/build-kbase-android"
SO="src/panfrost/vulkan/libvulkan_panfrost.so"

echo "=== file ==="
file "$SO"
ls -lh "$SO"

echo "=== NEEDED/SONAME ==="
readelf -d "$SO" | grep -E "SONAME|NEEDED"

echo "=== ICD entry points ==="
nm -D "$SO" | grep -E "vk_icdGetInstanceProcAddr|vk_icdNegotiateLoaderICDInterfaceVersion|vk_icdGetPhysicalDeviceProcAddr" || true

echo "=== stage as vulkan.mali.so ==="
STAGE="$HOME/panvk/android-hal"
rm -rf "$STAGE"
mkdir -p "$STAGE"

cp "$SO" "$STAGE/vulkan.mali.so"
"$HOME/panvk/android-ndk-r27c/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" --strip-unneeded "$STAGE/vulkan.mali.so"

echo "=== patchelf soname (need patchelf) ==="
if command -v patchelf >/dev/null 2>&1; then
  patchelf --set-soname vulkan.mali.so "$STAGE/vulkan.mali.so"
else
  echo "patchelf not installed - installing"
  echo '123' | sudo -S apt-get install -y -qq patchelf 2>&1 | tail -1
  patchelf --set-soname vulkan.mali.so "$STAGE/vulkan.mali.so"
fi
readelf -d "$STAGE/vulkan.mali.so" | grep -E "SONAME|NEEDED"
file "$STAGE/vulkan.mali.so"
ls -lh "$STAGE/vulkan.mali.so"
echo "STAGED"
