#!/bin/sh
# Build draco, LASzip and libLAS for ARM64 (static, PIC) into ~/.cache/takx-native-pkgs/<name>
SRC=/home/kali/.cache/atak-civ-src
PK=/home/kali/.cache/takx-native-pkgs
B=/home/kali/.cache/takx-native-build
mkdir -p "$PK" "$B"
echo "=== deps build start $(date) ==="

echo "--- draco"
[ -f "$PK/draco/lib/libdraco.a" ] && echo "draco already built" || cmake -S "$SRC/draco" -B "$B/draco" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DDRACO_JS_GLUE=OFF -DDRACO_TESTS=OFF \
  -DCMAKE_INSTALL_PREFIX="$PK/draco" > "$B/draco-configure.log" 2>&1 \
  && nice -n 10 cmake --build "$B/draco" -j1 > "$B/draco-build.log" 2>&1 \
  && cmake --install "$B/draco" > "$B/draco-install.log" 2>&1 \
  && echo "draco OK $(date)" || echo "draco FAILED (see $B/draco-*.log)"

echo "--- LASzip"
cmake -S "$SRC/deps-src/LASzip" -B "$B/LASzip" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_STANDARD=14 \
  -DCMAKE_INSTALL_PREFIX="$PK/LASzip" > "$B/LASzip-configure.log" 2>&1 \
  && nice -n 10 cmake --build "$B/LASzip" -j1 > "$B/LASzip-build.log" 2>&1 \
  && cmake --install "$B/LASzip" > "$B/LASzip-install.log" 2>&1 \
  && echo "LASzip OK $(date)" || echo "LASzip FAILED (see $B/LASzip-*.log)"

echo "--- libLAS"
mkdir -p "$B/cmake-modules"
cat > "$B/cmake-modules/FindLASzip.cmake" <<'EOF'
set(LASzip_FOUND TRUE)
set(LASzip_VERSION 3.4.3)
set(LASzip_INCLUDE_DIR "/home/kali/.cache/takx-native-pkgs/LASzip/include")
set(LASzip_INCLUDE_DIRS "${LASzip_INCLUDE_DIR}")
set(LASzip_LIB_DIRS "/home/kali/.cache/takx-native-pkgs/LASzip/lib")
EOF
cmake -S "$SRC/deps-src/libLAS" -B "$B/libLAS" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_STANDARD=14 -DCMAKE_MODULE_PATH="$B/cmake-modules" \
  -DWITH_LASZIP=TRUE -DWITH_STATIC_LASZIP=TRUE -DWITH_GDAL=FALSE -DWITH_GEOTIFF=FALSE -DWITH_UTILITIES=FALSE -DWITH_TESTS=FALSE \
  -DCMAKE_INSTALL_PREFIX="$PK/libLAS" > "$B/libLAS-configure.log" 2>&1 \
  && nice -n 10 cmake --build "$B/libLAS" -j1 > "$B/libLAS-build.log" 2>&1 \
  && cmake --install "$B/libLAS" > "$B/libLAS-install.log" 2>&1 \
  && echo "libLAS OK $(date)" || echo "libLAS FAILED (see $B/libLAS-*.log)"

echo "=== deps build finished $(date) ==="
