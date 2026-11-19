#!/bin/sh
# Build the TAK kernel engine (libtakengine + libtakenginejni) for ARM64 from the public atak-civ source,
# against the locally built/packaged Conan dependencies (no cesium-native: 3D Tiles excluded).
export JAVA_HOME=/opt/jdk17
export PATH=/home/kali/.cache/conan-venv/bin:/opt/jdk17/bin:$PATH
export CONAN_PATH=/home/kali/.cache/conan-venv/bin/conan
SRC=/home/kali/.cache/atak-civ-src/takkernel/engine
B=/home/kali/.cache/takx-native-build/engine
mkdir -p "$B"
echo "=== engine configure $(date) ==="
cmake -S "$SRC" -B "$B" -DCMAKE_BUILD_TYPE=Release -DBUILD_JNI=ON \
      -DCMAKE_INSTALL_PREFIX=/home/kali/.cache/takx-native-pkgs/engine \
      -DCMAKE_C_FLAGS="-Wno-error" -DCMAKE_CXX_FLAGS="-Wno-error" || { echo "=== engine configure FAILED $(date)"; exit 1; }
echo "=== engine build $(date) ==="
nice -n 10 cmake --build "$B" -j2 || { echo "=== engine build FAILED $(date)"; exit 1; }
echo "=== engine install $(date) ==="
cmake --install "$B" || true
echo "=== engine build finished OK $(date) ==="
find "$B" -name '*.so' | head
