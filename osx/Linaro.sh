#!/bin/bash

set -u

# http://packages.ubuntu.com/precise/gcc-arm-linux-gnueabihf

export PLATFORM="Linaro"
export HOST_PLATFORM="Linux" # assumed to be Ubuntu
export BOOST_ARCH="arm"
export ARCH_NAME="gcc-arm-linux-gnueabihf"
export HOST_ARG="--host=arm-linux-gnueabihf"
source $(dirname "$BASH_SOURCE")/settings.sh

# default to C++11 for this platform
if [[ "${CXX11:-false}" == false ]]; then
  export CXX11=true
fi