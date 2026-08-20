#!/bin/bash
echo '123' | sudo -S apt-get install -y -qq libdrm-dev 2>&1 | tail -2
pkg-config --modversion libdrm
