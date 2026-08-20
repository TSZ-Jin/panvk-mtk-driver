#!/bin/bash
set -e
echo '123' | sudo -S apt-get install -y -qq glslang-tools 2>&1 | tail -2
glslangValidator --version | head -2
echo "GLSLANG_OK"
