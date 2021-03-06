#!/bin/bash
set -e -u
set -o pipefail
mkdir -p ${PACKAGES}
cd ${PACKAGES}

download expat-${EXPAT_VERSION}.tar.gz

# expat for gdal to avoid linking against system expat in /usr/lib
echoerr 'building expat'
rm -rf expat-${EXPAT_VERSION}
tar xf expat-${EXPAT_VERSION}.tar.gz
cd expat-${EXPAT_VERSION}
./configure ${HOST_ARG} \
--prefix=${BUILD} \
--enable-static \
--disable-shared
make -j${JOBS}
make install
cd ${PACKAGES}
