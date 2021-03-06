#!/bin/bash
set -e -u
set -o pipefail
mkdir -p ${PACKAGES}
cd ${PACKAGES}

download harfbuzz-${HARFBUZZ_VERSION}.tar.bz2

# harfbuzz
echoerr 'building harfbuzz'
rm -rf harfbuzz-${HARFBUZZ_VERSION}
tar xf harfbuzz-${HARFBUZZ_VERSION}.tar.bz2
cd harfbuzz-${HARFBUZZ_VERSION}
CXXFLAGS="${CXXFLAGS} -DHB_NO_MT"
CFLAGS="${CFLAGS} -DHB_NO_MT"
LDFLAGS="${STDLIB_LDFLAGS} ${LDFLAGS}"
./configure --prefix=${BUILD} ${HOST_ARG} \
 --enable-static --disable-shared --disable-dependency-tracking \
 --with-icu \
 --with-cairo=no \
 --with-glib=no \
 --with-gobject=no \
 --with-graphite2=no \
 --with-freetype \
 --with-uniscribe=no \
 --with-coretext=no
make -j${JOBS}
make install
cd ${PACKAGES}
