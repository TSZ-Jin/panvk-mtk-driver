#!/bin/bash
# =============================================================================
# panvk-mtk-driver 一键构建脚本 (已修复 panvk_drm_stub.c 缺失问题)
#
# 功能: 克隆基础 Mesa 源码 -> 应用补丁 -> 构建离线编译器 -> 构建 Android
#       Vulkan HAL (libvulkan_panfrost.so) -> 产出 vulkan.mali.so
#
# 环境: Ubuntu 22.04/24.04 (WSL2 或原生), 需要 sudo
# 用法: bash build.sh [release|debug]
# =============================================================================
set -euo pipefail

MODE="${1:-release}"

# --- 可配置路径 ------------------------------------------------------------
WORKDIR="${WORKDIR:-$HOME/panvk-mtk}"
MESA_FORK_URL="${MESA_FORK_URL:-https://github.com/funnymdzz/mesa.git}"
MESA_COMMIT="${MESA_COMMIT:-6598829019c}"   # 补丁基于此提交
NDK_VERSION="${NDK_VERSION:-r27c}"
NDK_URL="https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip"
COMPILER_PREFIX="${COMPILER_PREFIX:-$WORKDIR/mesa-compiler}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH="$SCRIPT_DIR/patches/panvk_mtk.patch"
OUT_DIR="$SCRIPT_DIR/driver"

mkdir -p "$WORKDIR"

# --- 1. 系统依赖 -----------------------------------------------------------
echo "==> [1/6] 安装系统依赖"
sudo apt-get update -y || true
sudo apt-get install -y \
  python3 python3-pip python3-setuptools python3-wheel ninja-build meson \
  pkg-config git wget unzip curl \
  clang llvm-18-dev libclang-18-dev libclang-cpp18-dev \
  spirv-tools glslang-tools libx11-dev libxext-dev libxdamage-dev \
  libxfixes-dev libxrandr-dev libdrm-dev libexpat1-dev zlib1g-dev \
  bison flex gettext xsltproc libwayland-dev \
  rustc cargo libclang-rt-18-dev || true

# rust android target
rustup target add aarch64-linux-android 2>/dev/null || \
  rustup target add aarch64-linux-android --toolchain stable 2>/dev/null || true

export PATH="/usr/lib/llvm-18/bin:$PATH:$HOME/.cargo/bin"
export LIBCLANG_PATH=/usr/lib/llvm-18/lib
export CLANG_PATH=/usr/lib/llvm-18/bin/clang
export BINDGEN_EXTRA_CLANG_ARGS="-target aarch64-linux-android --sysroot=$WORKDIR/android-ndk-${NDK_VERSION}/toolchains/llvm/prebuilt/linux-x86_64/sysroot"

# --- 2. NDK -----------------------------------------------------------------
echo "==> [2/6] 下载/解压 NDK ${NDK_VERSION}"
NDK="$WORKDIR/android-ndk-${NDK_VERSION}"
if [ ! -d "$NDK" ]; then
  wget -q "$NDK_URL" -O "$WORKDIR/ndk.zip"
  unzip -q -o "$WORKDIR/ndk.zip" -d "$WORKDIR"
  rm -f "$WORKDIR/ndk.zip"
fi
NDK_BIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"

# --- 3. Mesa 源码 + 补丁 ----------------------------------------------------
echo "==> [3/6] 克隆 Mesa 源码并应用补丁"
if [ ! -d "$WORKDIR/mesa/.git" ]; then
  git clone "$MESA_FORK_URL" "$WORKDIR/mesa"
fi
cd "$WORKDIR/mesa"
git checkout "$MESA_COMMIT" 2>/dev/null || git fetch origin && git checkout "$MESA_COMMIT"

if ! git apply --check "$PATCH" 2>/dev/null; then
  if git apply --reverse --check "$PATCH" 2>/dev/null; then
    echo "    补丁已应用, 跳过"
  else
    echo "ERROR: 补丁无法应用 (请确认 MESA_COMMIT=$MESA_COMMIT)"
    exit 1
  fi
else
  git apply "$PATCH"
  echo "    补丁已应用"
fi

# --- 🌟 自动修复 Mesa 源码兼容性问题 (针对 panvk_drm_stub.c 缺失) 🌟 ---
echo "==> [3.5/6] 检查并修复 panvk_drm_stub.c 兼容性问题"
VULKAN_DIR="src/panfrost/vulkan"
MESON_BUILD="$VULKAN_DIR/meson.build"

if [ ! -f "$VULKAN_DIR/panvk_drm_stub.c" ]; then
  echo "    警告: panvk_drm_stub.c 不存在，尝试自动修复 meson.build..."
  if [ -f "$VULKAN_DIR/panvk_stub.c" ]; then
    echo "    -> 发现 panvk_stub.c，将引用替换为 panvk_stub.c"
    sed -i 's/panvk_drm_stub\.c/panvk_stub.c/g' "$MESON_BUILD"
  else
    echo "    -> 未发现替代文件，直接从 meson.build 中移除对该文件的引用"
    sed -i '/panvk_drm_stub\.c/d' "$MESON_BUILD"
  fi
  echo "    修复完成！"
else
  echo "    panvk_drm_stub.c 存在，无需修复。"
fi
# --------------------------------------------------------------------------

# --- 4. 离线编译器 (mesa_clc / panfrost_compile) ----------------------------
echo "==> [4/6] 构建离线编译器"
if [ ! -d "$WORKDIR/mesa/build-compiler" ]; then
  meson setup build-compiler \
    -Dprefix="$COMPILER_PREFIX" \
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
meson compile -C build-compiler
meson install -C build-compiler
export PATH="$COMPILER_PREFIX/bin:$PATH"

# --- 5. 交叉编译 Android Vulkan HAL -----------------------------------------
echo "==> [5/6] 配置并构建 Android Vulkan HAL ($MODE)"
cat > "$WORKDIR/android-kbase.ini" <<EOF
[constants]
ndk_path = '$NDK'
prebuilt = ndk_path + '/toolchains/llvm/prebuilt/linux-x86_64/bin'

[binaries]
ar      = prebuilt + '/llvm-ar'
c       = prebuilt + '/aarch64-linux-android34-clang'
cpp     = [prebuilt + '/aarch64-linux-android34-clang++',
           '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables',
           '--start-no-unused-arguments', '-static-libstdc++', '--end-no-unused-arguments']
strip   = prebuilt + '/llvm-strip'
rust    = ['rustc', '--target', 'aarch64-linux-android']
rust_ld = prebuilt + '/aarch64-linux-android34-clang'
c_ld    = 'lld'
cpp_ld  = 'lld'

[host_machine]
system     = 'android'
cpu_family = 'aarch64'
cpu        = 'armv8'
endian     = 'little'

[properties]
rust_std   = '2021'
EOF

BUILD_DIR="build-kbase-android"
if [ "$MODE" = "debug" ]; then
  BUILD_DIR="build-kbase-android-debug"
fi

if [ ! -d "$BUILD_DIR/meson-private" ]; then
  BTYPE=release
  BNDEBUG=true
  [ "$MODE" = "debug" ] && BTYPE=debug && BNDEBUG=false
  meson setup "$BUILD_DIR" \
    --cross-file "$WORKDIR/android-kbase.ini" \
    --buildtype="$BTYPE" \
    -Db_ndebug="$BNDEBUG" \
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
meson compile -C "$BUILD_DIR"

# --- 6. 产出 ----------------------------------------------------------------
echo "==> [6/6] 产出 vulkan.mali.so"
SO="$WORKDIR/mesa/$BUILD_DIR/src/panfrost/vulkan/libvulkan_panfrost.so"
mkdir -p "$OUT_DIR"

if [ -f "$SO" ]; then
  cp "$SO" "$OUT_DIR/vulkan.mali.so"
  # 尝试使用 patchelf 修改 soname (如果系统没有 patchelf 则忽略此步，不影响核心功能)
  if command -v patchelf &> /dev/null; then
    patchelf --set-soname vulkan.mali.so "$OUT_DIR/vulkan.mali.so" || true
  fi
  ls -la "$OUT_DIR/vulkan.mali.so"
  md5sum "$OUT_DIR/vulkan.mali.so"
  echo
  echo "🎉 构建成功完成: $OUT_DIR/vulkan.mali.so"
else
  echo "❌ 错误: 未找到编译产物 $SO"
  exit 1
fi
