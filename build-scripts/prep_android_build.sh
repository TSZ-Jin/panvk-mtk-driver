#!/bin/bash
BIN="$HOME/panvk/android-ndk-r27c/toolchains/llvm/prebuilt/linux-x86_64/bin"
ls "$BIN" | grep -E "^(lld|ld.lld)$"
ls "$BIN" | grep -E "aarch64-linux-android34-clang"
# rust android link test with persistent file
source "$HOME/.cargo/env"
mkdir -p "$HOME/panvk/tmp"
cat > "$HOME/panvk/tmp/test_android.rs" <<'EOF'
fn main() { println!("hello android"); }
EOF
"$BIN/aarch64-linux-android34-clang" --version | head -1
rustc --target aarch64-linux-android -C linker="$BIN/aarch64-linux-android34-clang" "$HOME/panvk/tmp/test_android.rs" -o "$HOME/panvk/tmp/test_android"
file "$HOME/panvk/tmp/test_android"
echo "RUST_ANDROID_OK"
