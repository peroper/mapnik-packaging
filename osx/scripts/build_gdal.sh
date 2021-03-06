#!/bin/bash
set -e -u
set -o pipefail
mkdir -p ${PACKAGES}
cd ${PACKAGES}

# gdal
echoerr 'building gdal'

GDAL_LATEST=true

if [[ $GDAL_LATEST == true ]]; then
    #rm -rf gdal
    if [ ! -d gdal ]; then
        git clone --quiet --depth=1 https://github.com/OSGeo/gdal.git
        cd gdal/gdal
    else
        cd gdal/gdal
        CUR_NOW=$(date +"%s")
        git diff > latest-${CUR_NOW}
        git checkout .
        git pull || true
        if [[ -f GDALmake.opt ]]; then
            make clean
            make distclean
        fi
    fi
else
    download gdal-${GDAL_VERSION}.tar.gz
    rm -rf gdal-${GDAL_VERSION}
    tar xf gdal-${GDAL_VERSION}.tar.gz
    cd gdal-${GDAL_VERSION}
fi

# purge previous install
rm -f ${BUILD}/include/cpl_*
rm -f ${BUILD}/include/gdal*
rm -f ${BUILD}/lib/libgdal*
rm -rf ./.libs
rm -rf ./libgdal.la

# note: we put ${STDLIB_CXXFLAGS} into CXX instead of CXXFLAGS due to libtool oddity:
# http://stackoverflow.com/questions/16248360/autotools-libtool-link-library-with-libstdc-despite-stdlib-libc-option-pass
CXX="${CXX} ${STDLIB_CXXFLAGS} -Wno-pragmas"
# http://trac.osgeo.org/gdal/wiki/BuildingOnUnixWithMinimizedDrivers
# not bigtiff check will fail…
# fix bigtiff check
#patch -N configure ${PATCHES}/bigtiff_check.diff || true
# add ability to link to static geos
patch -N configure ${PATCHES}/gdal-geos-check.diff || true
FGDB_ARGS="--with-fgdb=no"
if [ $UNAME = 'Darwin' ]; then
    # trick the gdal configure into working on os x
    if [ -d "${PACKAGES}/FileGDB_API/" ]; then
        if [ ! -f "${PACKAGES}/FileGDB_API/lib/libFileGDBAPI.so" ]; then
           touch "${PACKAGES}/FileGDB_API/lib/libFileGDBAPI.so"
        fi
        if [ "${CXX11}" = false ]; then
          FGDB_ARGS="--with-fgdb=${PACKAGES}/FileGDB_API/"
        fi
    fi
fi

# warning: unknown warning option '-Wno-pragmas' [-Wunknown-warning-option]
if [[ $UNAME == 'Darwin' ]]; then
    CXXFLAGS=" -Wno-unknown-warning-option $CXXFLAGS"
fi

LDFLAGS="${STDLIB_LDFLAGS} ${LDFLAGS}"
# --with-geotiff=${BUILD} \

BUILD_WITH_SPATIALITE="no"
BUILD_WITH_GEOS="no"
CUSTOM_LIBS=""

if [ -f $BUILD/lib/libspatialite.a ]; then
    CUSTOM_LIBS="${CUSTOM_LIBS} -lgeos_c -lgeos -lsqlite3"
    BUILD_WITH_SPATIALITE="${BUILD}"
fi

if [ -f $BUILD/lib/libgeos.a ]; then
    CUSTOM_LIBS="${CUSTOM_LIBS} -lgeos_c -lgeos"
    BUILD_WITH_GEOS="${BUILD}/bin/geos-config"
fi

if [ -f $BUILD/lib/libtiff.a ]; then
    CUSTOM_LIBS="${CUSTOM_LIBS} -ltiff -ljpeg"
fi

if [ -f $BUILD/lib/libproj.a ]; then
    CUSTOM_LIBS="${CUSTOM_LIBS} -lproj"
fi

if [[ $BUILD_WITH_SPATIALITE != "no" ]] || [[ $BUILD_WITH_GEOS != "no" ]]; then
    if [[ $CXX11 == true ]]; then
        if [[ $STDLIB == "libcpp" ]]; then
            CUSTOM_LIBS="$CUSTOM_LIBS -lc++ -lm"
        else
            CUSTOM_LIBS="$CUSTOM_LIBS -lstdc++ -lm"
        fi
    else
        CUSTOM_LIBS="$CUSTOM_LIBS -lstdc++ -lm"
    fi
fi


LIBS=$CUSTOM_LIBS ./configure ${HOST_ARG} \
--prefix=${BUILD} \
--enable-static \
--disable-shared \
${FGDB_ARGS} \
--with-libtiff=${BUILD} \
--with-jpeg=${BUILD} \
--with-png=${BUILD} \
--with-static-proj4=${BUILD} \
--with-sqlite3=${BUILD} \
--with-spatialite=${BUILD_WITH_SPATIALITE} \
--with-geos=${BUILD_WITH_GEOS} \
--with-hide-internal-symbols=no \
--with-curl=no \
--with-pcraster=no \
--with-cfitsio=no \
--with-odbc=no \
--with-libkml=no \
--with-pcidsk=no \
--with-jasper=no \
--with-gif=no \
--with-pg=no \
--with-grib=no \
--with-freexl=no

make -j${JOBS}
make install
cd ${PACKAGES}

check_and_clear_libs

# build mdb plugin
# http://gis.stackexchange.com/a/76792
# http://www.gdal.org/ogr/drv_mdb.html
# https://trac.osgeo.org/gdal/wiki/ConfigOptions#GDAL_DRIVER_PATH
# http://www.gdal.org/ogr/ogr_drivertut.html
#clang++ -Wall -g ogr/ogrsf_frmts/mdb/ogr*.c* -shared -o ogr_plugins/ogr_MDB.dylib   -Iport -Igcore -Iogr -Iogr/ogrsf_frmts -Iogr/ogrsf_frmts/mdb   -I/System/Library/Frameworks/JavaVM.framework/Headers  -framework JavaVM .libs/libgdal.a -stdlib=libstdc++
#export GDAL_DRIVER_PATH=$(pwd)/ogr_plugins/
#install_name_tool -id ogr_MDB.dylib ogr_plugins/ogr_MDB.dylib
#cp mdb-sqlite-1.0.2/lib/* /Library/Java/Extensions/
