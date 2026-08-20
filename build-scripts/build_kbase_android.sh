#!/bin/bash
set -e
export PATH="$HOME/mesa-compiler/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export PATH="/usr/lib/llvm-18/bin:$PATH"
source "$HOME/.cargo/env"
export LIBCLANG_PATH=/usr/lib/llvm-18/lib
export CLANG_PATH=/usr/lib/llvm-18/bin/clang
NDK="$HOME/panvk/android-ndk-r27c"
SYSROOT="$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
export BINDGEN_EXTRA_CLANG_ARGS="-target aarch64-linux-android --sysroot=$SYSROOT"

cd "$HOME/mesa"

if [ -d build-kbase-android/meson-private ]; then
  echo "build dir exists, skipping setup"
else
  echo "=== meson setup (kbase android HAL) ==="
  meson setup build-kbase-android \
    --cross-file "$HOME/panvk/android-kbase.ini" \
    --buildtype=release \
    -Db_ndebug=true \
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

echo "=== meson compile ==="
meson compile -C build-kbase-android

echo "=== outputs ==="
find build-kbase-android/src -name "*.so" | head -20
echo "ANDROID_KBASE_DONE"
