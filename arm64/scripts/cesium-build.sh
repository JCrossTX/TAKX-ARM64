#!/bin/sh
# Build cesium-native 0.40.1 (+ its vcpkg dependencies) natively for arm64-linux, as the TAK engine's 3D Tiles support needs.
export VCPKG_FORCE_SYSTEM_BINARIES=1      # required for vcpkg on arm64 Linux
export VCPKG_MAX_CONCURRENCY=2
export CMAKE_BUILD_PARALLEL_LEVEL=2
export CMAKE_POLICY_VERSION_MINIMUM=3.5   # CMake 4 vs. old minimum-version declarations in vcpkg-tool deps/ports
export EZVCPKG_BASEDIR=/home/kali/.cache/ezvcpkg
SRC=/home/kali/.cache/cesium-native-src
OVL=/home/kali/.cache/atak-civ-src/cesium-native/overlay-ports
PK=/home/kali/.cache/takx-native-pkgs/cesium-native
mkdir -p "$EZVCPKG_BASEDIR"
echo "=== cesium-native build start $(date) ==="
# TAK's zlib-ng overlay port (fetch port files, disable ARMv6 code path)
( cd "$OVL" && [ -f zlib-ng/portfile.cmake ] || sh stage.sh ) 2>&1 | tail -2
# skip test-only packages
sed -i 's/^\(\s*\)list(APPEND PACKAGES_ALL ${PACKAGES_TEST})/\1# tests skipped for the TAK engine build/' "$SRC/CMakeLists.txt"
cd "$SRC" || exit 1
nice -n 10 cmake -S "$SRC" -B "$SRC/build/arm64-linux" \
  -DCMAKE_BUILD_TYPE=Release -DCESIUM_TESTS_ENABLED=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DVCPKG_TRIPLET=arm64-linux -DVCPKG_BUILD_TYPE=release -DVCPKG_OVERLAY_PORTS="$OVL" \
  -DCMAKE_INSTALL_PREFIX="$PK" || { echo "=== cesium configure (vcpkg deps) FAILED $(date)"; exit 1; }
echo "=== cesium deps done, building cesium-native $(date) ==="
nice -n 10 cmake --build "$SRC/build/arm64-linux" -j2 --target install || { echo "=== cesium build FAILED $(date)"; exit 1; }
echo "=== cesium-native build finished OK $(date) ==="
