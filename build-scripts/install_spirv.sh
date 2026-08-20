#!/bin/bash
apt-cache policy libllvmspirvlib-18-dev 2>/dev/null | awk '/Candidate:/{print $2}'
echo '123' | sudo -S apt-get install -y -qq libllvmspirvlib-18-dev 2>&1 | tail -2
pkg-config --modversion LLVMSPIRVLib
