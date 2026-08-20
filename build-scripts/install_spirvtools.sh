#!/bin/bash
for p in spirv-tools libspirv-tools-dev; do
  echo "$p -> $(apt-cache policy $p 2>/dev/null | awk '/Candidate:/{print $2}')"
done
echo '123' | sudo -S apt-get install -y -qq spirv-tools 2>&1 | tail -2
pkg-config --modversion SPIRV-Tools 2>/dev/null || echo "no SPIRV-Tools pc yet"
