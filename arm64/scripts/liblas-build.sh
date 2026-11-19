#!/bin/sh
# Build libLAS 1.8.2 (TAK-modified) for ARM64 against the LASzip Conan package.
export PATH=/home/kali/.cache/conan-venv/bin:$PATH
export CONAN_PATH=/home/kali/.cache/conan-venv/bin/conan
SRC=/home/kali/.cache/atak-civ-src/deps-src/libLAS
PK=/home/kali/.cache/takx-native-pkgs/libLAS
B=/home/kali/.cache/takx-native-build/libLAS
rm -rf "$B"; mkdir -p "$B"
echo "=== libLAS build start $(date) ==="
cmake -S "$SRC" -B "$B" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_STANDARD=14 \
  -DWITH_LASZIP=TRUE -DWITH_STATIC_LASZIP=TRUE -DWITH_GDAL=FALSE -DWITH_GEOTIFF=FALSE -DWITH_UTILITIES=FALSE -DWITH_TESTS=FALSE \
  -DCMAKE_INSTALL_PREFIX="$PK" > "$B-configure.log" 2>&1 || { echo "libLAS configure FAILED $(date)"; exit 1; }
nice -n 10 cmake --build "$B" -j1 > "$B-build.log" 2>&1 || { echo "libLAS build FAILED $(date)"; exit 1; }
cmake --install "$B" > "$B-install.log" 2>&1 || { echo "libLAS install FAILED $(date)"; exit 1; }
echo "libLAS OK $(date)"
ls "$PK/lib"
