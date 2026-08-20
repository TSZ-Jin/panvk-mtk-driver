#!/bin/bash
set -e
echo "=== installing llvm/clang/libclc ==="
echo '123' | sudo -S apt-get install -y -qq llvm-18-dev libclang-18-dev libclang-cpp18-dev clang-18 libclc-18-dev lld-18 python3-zstandard 2>&1 | tail -3
echo "=== verify ==="
/usr/lib/llvm-18/bin/llvm-config --version
pkg-config --modversion libclc
clang-18 --version | head -1
echo "LLVM_OK"
