#!/bin/bash
set -e -u
set -o pipefail
mkdir -p ${PACKAGES}
cd ${PACKAGES}

download icu4c-${ICU_VERSION2}-src.tgz

echoerr 'building icu'
# cleanup installed version
rm -rf ${BUILD}/share/icu/
rm -rf ${BUILD}/include/unicode/
rm -rf ${BUILD}/lib/libicu*

# cleanup local package
rm -rf icu-${ARCH_NAME}
rm -rf icu
# *WARNING* do not set an $INSTALL variable
# it will screw up icu build scripts
LDFLAGS="${STDLIB_LDFLAGS} ${LDFLAGS}"
# http://source.icu-project.org/repos/icu/icu/trunk/readme.html#RecBuild
# http://userguide.icu-project.org/packaging
# http://thebugfreeblog.blogspot.de/2013/05/cross-building-icu-for-applications-on.html
# U_CHARSET_IS_UTF8 is added to try to reduce icu library size (18.3)
if [ ${BOOST_ARCH} = "x86" ]; then
    CPPFLAGS="${ICU_CORE_CPP_FLAGS}"
else
    CPPFLAGS="${ICU_EXTRA_CPP_FLAGS}"
fi

tar xf icu4c-${ICU_VERSION2}-src.tgz
mv icu icu-${ARCH_NAME}
cd icu-${ARCH_NAME}/source
if [ $BOOST_ARCH = "arm" ]; then
    if [ -d "$(pwd)/../../icu-i386/source" ]; then
        NATIVE_BUILD_DIR="$(pwd)/../../icu-i386/source"
    elif [ -d "$(pwd)/../../icu-x86_64/source" ]; then
        NATIVE_BUILD_DIR="$(pwd)/../../icu-x86_64/source"
    else
        NATIVE_BUILD_DIR="$(pwd)/../../icu-x86_64/source"
        echoerr 'native/host arch icu missing, building now in subshell'
        OLD_PLATFORM=${PLATFORM}
        source ${ROOTDIR}/${HOST_PLATFORM}.sh && ${ROOTDIR}/scripts/build_icu.sh
        source ${ROOTDIR}/${OLD_PLATFORM}.sh
    fi
    CROSS_FLAGS="--with-cross-build=${NATIVE_BUILD_DIR}"
    CPPFLAGS="${CPPFLAGS} -I$(pwd)/common -I$(pwd)/tools/tzcode/"
else
    CROSS_FLAGS=""
fi
cp ${PREMADE_ICU_DATA_LIBRARY} ./data/in/*dat
# note: enable-draft is needed for U_ICUDATA_ENTRY_POINT
./configure ${HOST_ARG} ${CROSS_FLAGS} --prefix=${BUILD} \
--enable-draft \
--enable-static \
--with-data-packaging=archive \
--disable-shared \
--disable-tests \
--disable-extras \
--disable-layout \
--disable-icuio \
--disable-samples \
--disable-dyload
make -j${JOBS} -i -k 
make install
cd ${PACKAGES}

# clear out shared libs
rm -f ${BUILD}/lib/{*.so,*.dylib}
