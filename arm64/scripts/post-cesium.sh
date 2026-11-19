#!/bin/sh
# After cesium-native builds: assemble the layout TAK's cesium-native Conan recipe packages and export 'cesium-native/0.40.1'.
export PATH=/home/kali/.cache/conan-venv/bin:$PATH
export CESIUM_NATIVE_REF=0.40.1
PK=/home/kali/.cache/takx-native-pkgs/cesium-native           # cmake --install prefix (Cesium*.a + headers)
VC=/home/kali/.cache/ezvcpkg/2024.07.12/installed/arm64-linux  # vcpkg-built dependencies (s2, abseil, ...)
CN=/home/kali/.cache/atak-civ-src/cesium-native
DST="$CN/build/linux-arm64"
echo "=== post-cesium start $(date) ==="
rm -rf "$DST"; mkdir -p "$DST/include" "$DST/lib"
cp -r "$PK/include/." "$DST/include/"
cp -r "$VC/include/." "$DST/include/"
cp "$PK/lib"/*.a "$DST/lib/" 2>/dev/null
cp "$VC/lib"/*.a "$DST/lib/" 2>/dev/null
echo "libs: $(ls "$DST/lib" | wc -l)  (Cesium: $(ls "$DST/lib" | grep -c '^libCesium'), absl: $(ls "$DST/lib" | grep -c '^libabsl'))"
ls "$DST/lib" | grep -E 'libs2|libCesium3DTilesSelection|libabsl_base' | tr '\n' ' '; echo
# TAK's recipe names the Linux layout 'linux-x86_64'; use 'linux-arm64' for armv8
python3 -I - "$CN/conanfile.py" <<'EOF'
import sys
p=sys.argv[1]; s=open(p).read()
old='        elif self.settings.os == "Linux":\n            source = "linux-x86_64"'
new='        elif self.settings.os == "Linux":\n            source = "linux-arm64" if str(self.settings.arch) == "armv8" else "linux-x86_64"'
if old in s:
    s=s.replace(old,new); open(p,'w').write(s); print("cesium conanfile: Linux armv8 -> linux-arm64")
else:
    print("cesium conanfile already patched or layout differs")
EOF
cd "$CN" && conan export-pkg . -f 2>&1 | grep -E 'ERROR|Packaged|created' | tail -6
conan search cesium-native 2>&1 | tail -2
echo "=== post-cesium finished $(date) ==="
