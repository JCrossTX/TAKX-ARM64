#!/bin/sh
# TAK Third Party build for linux-arm64v8 on the CM4: native build, GCC 16 compatibility flags.
# NOTE: the Makefile defines CFLAGS_COMMON = $(CFLAGS_generic) $(CFLAGS_release) = "-fPIC -O2"; overriding it on the
# command line must therefore repeat -fPIC -O2, or static archives come out non-PIC and cannot be linked into .so files.
export JAVA_HOME=/opt/jdk17
export PATH=/opt/jdk17/bin:$PATH
SRC=/home/kali/.cache/atak-civ-src
cd "$SRC" || exit 1
[ -d gdal ]   || tar xzf depends/gdal-2.4.4-mod.tar.gz
[ -d assimp ] || tar xzf depends/assimp-4.0.1-mod.tar.gz
cd "$SRC/takthirdparty" || exit 1
OUT=builds/linux-arm64v8-release
echo "=== TTP build start $(date) ==="

fix_config_scripts() {
    # Old autotools config.guess/config.sub in the 2013-2015 tarballs do not know aarch64; replace with current ones.
    n=0
    for f in $(find "$OUT" -maxdepth 4 -name config.guess 2>/dev/null); do
        d=$(dirname "$f")
        cp -f /usr/share/misc/config.guess "$d/config.guess"
        [ -f "$d/config.sub" ] && cp -f /usr/share/misc/config.sub "$d/config.sub"
        n=$((n+1))
    done
    echo "--- refreshed config.guess/config.sub in $n source dirs"
}

attempt=0
while [ $attempt -lt 8 ]; do
    attempt=$((attempt+1))
    echo "=== make attempt $attempt $(date) ==="
    nice -n 10 make TARGET=linux-arm64v8 GDAL_USE_KDU=no CONFIGURE_TARGET= gdal_BUILD_MAKEOVERRIDES=-j3 \
      CFLAGS_COMMON='-fPIC -O2 -std=gnu17 -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=implicit-int -Wno-error=int-conversion -Wno-error=return-mismatch' \
      CXXFLAGS_COMMON='-fPIC -O2 -std=gnu++14' \
      build_spatialite build_gdal build_assimp 2>&1 | tee /home/kali/.cache/ttp-make-last.log
    # tee masks make's status; inspect the log instead
    if grep -q 'Done! Debug' /home/kali/.cache/ttp-make-last.log && ! grep -qE '^make(\[[0-9]+\])?: \*\*\*' /home/kali/.cache/ttp-make-last.log; then
        echo "=== TTP build finished rc=0 $(date) ==="; exit 0
    fi
    if grep -q 'cannot guess build type' /home/kali/.cache/ttp-make-last.log; then
        fix_config_scripts; continue
    fi
    echo "=== TTP build finished rc=2 $(date) ==="; exit 2
done
echo "=== TTP build finished rc=3 (too many attempts) $(date) ==="; exit 3
