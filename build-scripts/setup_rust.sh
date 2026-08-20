#!/bin/bash
set -e
export LIBCLANG_PATH=/usr/lib/llvm-18/lib

if ! command -v rustup >/dev/null 2>&1; then
  echo "=== install rustup ==="
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh
  chmod +x /tmp/rustup-init.sh
  /tmp/rustup-init.sh -y --profile minimal --default-toolchain stable
fi

source "$HOME/.cargo/env"
echo "=== rustc version ==="
rustc --version
cargo --version

echo "=== add aarch64 target ==="
rustup target add aarch64-unknown-linux-gnu
rustup target list --installed | grep aarch64 || true

echo "=== install bindgen-cli 0.72.1 ==="
if ! command -v bindgen >/dev/null 2>&1 || [ "$(bindgen --version 2>/dev/null | awk '{print $2}')" != "0.72.1" ]; then
  cargo install --locked --version 0.72.1 bindgen-cli
fi
export PATH="$HOME/.cargo/bin:$PATH"
bindgen --version

echo "=== verify cross rust build ==="
cat > /tmp/test_rust.rs <<'EOF'
fn main() { println!("hello aarch64"); }
EOF
rustc --target aarch64-unknown-linux-gnu /tmp/test_rust.rs -o /tmp/test_rust_aarch64
file /tmp/test_rust_aarch64
echo "RUST_OK"
