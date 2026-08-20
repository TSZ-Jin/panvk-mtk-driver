#!/bin/bash
set -e
cd "$HOME/mesa/build-kbase-aarch64"
SO="src/panfrost/vulkan/libvulkan_panfrost.so"
JSON="src/panfrost/vulkan/panfrost_icd.armv8.json"

STAGE="$HOME/panvk/mesa-kbase-panvk"
rm -rf "$STAGE"
mkdir -p "$STAGE/lib" "$STAGE/share/vulkan/icd.d"

cp "$SO" "$STAGE/lib/libvulkan_panfrost_kbase.so"
aarch64-linux-gnu-strip --strip-unneeded "$STAGE/lib/libvulkan_panfrost_kbase.so"

python3 - "$JSON" "$STAGE/share/vulkan/icd.d/panfrost_kbase_icd.aarch64.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    m = json.load(f)
m["ICD"]["library_path"] = "libvulkan_panfrost_kbase.so"
with open(sys.argv[2], "w") as f:
    json.dump(m, f, indent=4)
    f.write("\n")
PY

cp "$HOME/mesa/docs/panvk-kbase.md" "$STAGE/README.md" 2>/dev/null || true

echo "=== staged files ==="
find "$STAGE" -type f -exec ls -lh {} \;
echo "=== icd json ==="
cat "$STAGE/share/vulkan/icd.d/panfrost_kbase_icd.aarch64.json"
echo "=== stripped so ==="
file "$STAGE/lib/libvulkan_panfrost_kbase.so"
ls -lh "$STAGE/lib/libvulkan_panfrost_kbase.so"
echo "STAGED"
