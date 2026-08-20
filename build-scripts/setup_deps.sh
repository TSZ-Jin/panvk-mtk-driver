#!/bin/bash
set -e

echo "=== apt install build deps ==="
echo '123' | sudo -S apt-get update -qq 2>/dev/null
echo '123' | sudo -S apt-get install -y -qq meson ninja-build python3-mako python3-packaging gettext ccache 2>/dev/null | tail -2

echo "=== versions ==="
meson --version
ninja --version
python3 -c "import mako, packaging"
echo "IMPORTS_OK"
echo "DONE"
