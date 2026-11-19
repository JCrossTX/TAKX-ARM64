#!/bin/sh
# TAK Third Party build for linux-arm64v8 on the CM4: native build, 2 jobs, GCC 16 compatibility flags.
export JAVA_HOME=/opt/jdk17
export PATH=/opt/jdk17/bin:$PATH
SRC=/home/kali/.cache/atak-civ-src
cd "$SRC" || exit 1
[ -d gdal ]   || tar xzf depends/gdal-2.4.4-mod.tar.gz
[ -d assimp ] || tar xzf depends/assimp-4.0.1-mod.tar.gz
cd "$SRC/takthirdparty" || exit 1
echo "=== TTP build start $(date) ==="
nice -n 10 make TARGET=linux-arm64v8 GDAL_USE_KDU=no CONFIGURE_TARGET= gdal_BUILD_MAKEOVERRIDES=-j3 \
  CFLAGS_COMMON='-std=gnu17 -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=implicit-int -Wno-error=int-conversion -Wno-error=return-mismatch' \
  CXXFLAGS_COMMON='-std=gnu++14' \
  build_spatialite build_gdal build_assimp
rc=$?
echo "=== TTP build finished rc=$rc $(date) ==="
exit $rc
