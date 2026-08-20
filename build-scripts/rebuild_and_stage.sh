#!/bin/bash
set -e
export PATH="$HOME/mesa-compiler/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export PATH="/usr/lib/llvm-18/bin:$PATH"
source "$HOME/.cargo/env"
export LIBCLANG_PATH=/usr/lib/llvm-18/lib
export CLANG_PATH=/usr/lib/llvm-18/bin/clang
NDK="$HOME/panvk/android-ndk-r27c"
export BINDGEN_EXTRA_CLANG_ARGS="-target aarch64-linux-android --sysroot=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot"

cd "$HOME/mesa"
meson compile -C build-kbase-android

echo "=== stage ==="
SO="build-kbase-android/src/panfrost/vulkan/libvulkan_panfrost.so"
STAGE="$HOME/panvk/android-hal"
mkdir -p "$STAGE"
cp "$SO" "$STAGE/vulkan.mali.so"
"$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" --strip-unneeded "$STAGE/vulkan.mali.so"
patchelf --set-soname vulkan.mali.so "$STAGE/vulkan.mali.so"
cp "$STAGE/vulkan.mali.so" "/mnt/c/Users/Administrator/Desktop/vulkan.mali.so"
md5sum "$STAGE/vulkan.mali.so"
echo "REBUILD_STAGED"
