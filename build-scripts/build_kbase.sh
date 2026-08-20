#!/bin/bash
set -e
export PATH="$HOME/mesa-compiler/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export PATH="/usr/lib/llvm-18/bin:$PATH"
source "$HOME/.cargo/env"
export LIBCLANG_PATH=/usr/lib/llvm-18/lib
export CLANG_PATH=/usr/lib/llvm-18/bin/clang
export BINDGEN_EXTRA_CLANG_ARGS="-target aarch64-linux-gnu --sysroot=/usr/aarch64-linux-gnu"

# ensure pkg-config wrapper exists
if ! command -v aarch64-linux-gnu-pkg-config >/dev/null 2>&1; then
  mkdir -p "$HOME/bin"
  cat > "$HOME/bin/aarch64-linux-gnu-pkg-config" <<'EOF'
#!/bin/bash
export PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=/usr/aarch64-linux-gnu
exec /usr/bin/pkg-config "$@"
EOF
  chmod +x "$HOME/bin/aarch64-linux-gnu-pkg-config"
  export PATH="$HOME/bin:$PATH"
fi

command -v bindgen && bindgen --version
command -v aarch64-linux-gnu-pkg-config && echo "pkg-config wrapper OK"

cd "$HOME/mesa"

if [ -d build-kbase-aarch64/meson-private ]; then
  echo "build dir exists, skipping setup"
else
  echo "=== meson setup (kbase cross) ==="
  meson setup build-kbase-aarch64 \
    --cross-file "$HOME/panvk/linux-aarch64.ini" \
    --buildtype=release \
    -Db_ndebug=true \
    -Dbuild-tests=false \
    -Ddisplay-info=disabled \
    -Degl=disabled \
    -Denable-glcpp-tests=false \
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
    -Dplatforms=x11 \
    -Dprecomp-compiler=system \
    -Dshared-glapi=disabled \
    -Dtools= \
    -Dvalgrind=disabled \
    -Dvideo-codecs= \
    -Dvulkan-drivers=panfrost \
    -Dvulkan-layers= \
    -Dxmlconfig=disabled \
    -Dzstd=disabled
fi

echo "=== meson compile (kbase cross) ==="
meson compile -C build-kbase-aarch64

echo "=== outputs ==="
find build-kbase-aarch64/src -name "*.so" | head -20
echo "KBASE_BUILD_DONE"
