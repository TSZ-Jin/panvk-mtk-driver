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

if [ ! -d build-kbase-android-debug/meson-private ]; then
  rm -rf build-kbase-android-debug
  echo "=== meson setup (debug) ==="
  meson setup build-kbase-android-debug \
    --cross-file "$HOME/panvk/android-kbase.ini" \
    --buildtype=debug \
    -Db_ndebug=false \
    -Dbuild-tests=false \
    -Dplatforms=android \
    -Dplatform-sdk-version=34 \
    -Dandroid-stub=true \
    -Dandroid-libbacktrace=disabled \
    -Degl=disabled \
    -Dgallium-drivers= \
    -Dgbm=disabled \
    -Dgles1=disabled \
    -Dgles2=disabled \
    -Dglx=disabled \
    -Dinstall-mesa-clc=false \
    -Dinstall-precomp-compiler=false \
    -Dlibunwind=disabled \
    -Dlmsensors=disabled \
    -Dllvm=disabled \
    -Dmesa-clc=system \
    -Dopengl=false \
    -Dpanfrost-kmds=kbase,panthor \
    -Dpanfrost-rust=true \
    -Dprecomp-compiler=system \
    -Dshared-glapi=disabled \
    -Dtools= \
    -Dvalgrind=disabled \
    -Dvideo-codecs= \
    -Dvulkan-drivers=panfrost \
    -Dvulkan-layers= \
    -Dxmlconfig=disabled \
    -Dzstd=disabled \
    -Dallow-fallback-for=libdrm
fi

echo "=== meson compile (debug) ==="
meson compile -C build-kbase-android-debug

echo "=== stage debug ==="
SO="build-kbase-android-debug/src/panfrost/vulkan/libvulkan_panfrost.so"
STAGE="$HOME/panvk/android-hal-debug"
mkdir -p "$STAGE"
cp "$SO" "$STAGE/vulkan.mali.so"
patchelf --set-soname vulkan.mali.so "$STAGE/vulkan.mali.so"
cp "$STAGE/vulkan.mali.so" "/mnt/c/Users/Administrator/Desktop/vulkan.mali.so"
cp "$STAGE/vulkan.mali.so" "/mnt/c/Users/Administrator/Desktop/panvk-final/vulkan.mali.so"
md5sum "$STAGE/vulkan.mali.so"
ls -lh "$STAGE/vulkan.mali.so"
echo "DEBUG_STAGED"
