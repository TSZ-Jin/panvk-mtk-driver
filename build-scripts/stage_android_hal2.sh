#!/bin/bash
set -e
NDK="$HOME/panvk/android-ndk-r27c"
BIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
cd "$HOME/mesa/build-kbase-android"

SO="src/panfrost/vulkan/libvulkan_panfrost.so"
STAGE="$HOME/panvk/android-hal"
mkdir -p "$STAGE"
cp "$SO" "$STAGE/vulkan.mali.so"
"$BIN/llvm-strip" --strip-unneeded "$STAGE/vulkan.mali.so"
patchelf --set-soname vulkan.mali.so "$STAGE/vulkan.mali.so"

echo "=== verify exports & no missing drmCloseBufferHandle ==="
readelf -d "$STAGE/vulkan.mali.so" | grep -E "SONAME|NEEDED"
nm -D "$STAGE/vulkan.mali.so" | grep -i "CloseBufferHandle" || echo "no CloseBufferHandle symbol?!"
readelf --dyn-syms --wide "$STAGE/vulkan.mali.so" | grep "HMI"

# offline symbol check against device libs
DIR=/mnt/c/Users/Administrator/Desktop/systest
: > /tmp/defs.txt
for lib in "$DIR"/*.so; do
  nm -D "$lib" 2>/dev/null | awk '$2 != "U" && $2 != "" && $3 != "" {print $3}' | sed 's/@.*//' >> /tmp/defs.txt
done
sort -u /tmp/defs.txt -o /tmp/defs.txt
echo "=== missing check ==="
nm -D "$STAGE/vulkan.mali.so" | awk '$1 == "U" && $2 != "" {print $2}' | sed 's/@.*//' | sort -u | while read s; do
  grep -qxF "$s" /tmp/defs.txt || echo "MISSING: $s"
done
echo "=== copy to windows ==="
cp "$STAGE/vulkan.mali.so" "/mnt/c/Users/Administrator/Desktop/vulkan.mali.so"
ls -lh "$STAGE/vulkan.mali.so"
md5sum "$STAGE/vulkan.mali.so"
echo "STAGED_OK"
