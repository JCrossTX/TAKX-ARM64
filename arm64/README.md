# TAKX on Linux ARM64 (Raspberry Pi CM4) — engine port work

TAKX itself is pure Java and runs unchanged on ARM64. What TAK Product Center does not ship for
Linux ARM64 is the **TAK kernel native engine** (`takkernel-engine-rt-<platform>`, `takthirdparty-rt-<platform>`,
`libLAS-<platform>`), and TAKX refuses to start without it (`EngineLibrary.initialize()` is called from
`ApplicationLauncher`). This directory holds everything used to create that runtime for `linuxarm64` on a
Raspberry Pi CM4 (Kali Linux, aarch64, 1.8 GB RAM) from TPC's public sources.

Status (2026-11-19): TAKX 5.8.0 starts, shows its UI and runs TAK networking natively on the Pi with a
first-pass ARM64 kernel runtime; the real engine build from `atak-civ` is in progress. See "Facts" below for
what can and cannot be fully recovered from public source.

## Layout

| Path | Contents |
|---|---|
| `scripts/` | Build scripts, in order: `ttp-build.sh` (TAK third-party libs for `linux-arm64v8`), `deps-build.sh` (draco, LASzip), `liblas-build.sh` (libLAS), `cesium-build.sh` (cesium-native 0.40.1 via vcpkg, for 3D Tiles), `engine-build.sh` (libtakengine + libtakenginejni). |
| `conan/` | Conan 1.65 recipes for the packages the engine's CMake expects but TPC only publishes on its private Artifactory: `khronos/1.0`, `GLES-stub/2.0.0`, `LASzip/3.4.3c`, `libLAS/1.8.2f`, `draco/1.5.7`. `ttp-dist/4.2.4` comes from `takthirdparty/ci-support/conanfile.py` (patched for armv8). |
| `patches/atak-civ/` | Diff against `github.com/TAK-Product-Center/atak-civ` (`main`, Feb 2026): ARM64 `ttp-dist` package naming. The engine sources themselves are built unmodified, including the cesium-native based 3D Tiles code. |
| `patches/cesium-native-0.40.1-tests-skipped.patch` | Drops the test-only vcpkg package (Catch2) from cesium-native's dependency fetch and guards its lookup behind `CESIUM_TESTS_ENABLED`. |
| `takx-install/` | Changes applied to the installed `/opt/TAKX`: module.xml patches registering the ARM64 jars (JOGL/gluegen 2.5.0 `natives-linux-aarch64`, bytedeco ffmpeg `linux-arm64`, the ARM64 kernel runtime jar), JVM options for a 2 GB device, the install4j response file, and the desktop launcher. |
| `tools/` | Analysis helpers: `natives_dump.py`/`natives.py` (list JNI natives declared in jars by parsing class files), `compare_natives.py` (compare against public Java sources), `gen_filler.py` (measure which required JNI symbols a built library lacks), `i4jdump.py`/`i4jscripts.py` (inspect install4j installer configuration), `gen_stubs.py` + `stage1-startup-stub-example.c` (the stage-1 placeholder runtime used only to get TAKX to its window; not part of the real runtime). |

## Prerequisites on the Pi

* Java 17 exactly (Temurin 17 aarch64 at `/opt/jdk17`); the install4j installer and launcher reject 18+.
* `build-essential cmake ninja-build autoconf automake libtool pkg-config swig ant texinfo gettext`
  `python3-venv libboost-dev libboost-program-options-dev libboost-thread-dev libboost-iostreams-dev libboost-filesystem-dev`
  `libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev libx11-dev zip unzip curl git`
* Conan 1.65.0 in a Python 3.13 venv; add `"15", "15.1", "15.2", "16", "16.1", "16.2"` to the gcc versions in `~/.conan/settings.yml`; profile `compiler.libcxx=libstdc++11`.
* The `atak-civ` repo uses Git LFS for every tarball; without `git-lfs`, fetch the pointers' objects from
  `https://media.githubusercontent.com/media/TAK-Product-Center/atak-civ/main/<path>` and verify the sha256 in the pointer.

## Build order

1. Install TAKX 5.8.0 with the unix installer **as root** with the native Java 17 (run the extracted install4j Java
   installer directly: `INSTALL4J_DISABLE_BUNDLED_JRE` is not enough because the bundled JRE is x86_64).
2. `ttp-build.sh` — zlib, libiconv, libxml2, OpenSSL, nghttp2, curl, proj, sqlcipher, expat, libkml, OGDI, GEOS, mdbtools, spatialite, pdfium (prebuilt `linux-arm64v8`), GDAL 2.4.4 (+ Java bindings), assimp (+ jassimp).
   Notes that cost time: run the top-level make serially (a `-j` race in the GDAL copy step), pass `CONFIGURE_TARGET=`,
   and `CFLAGS_COMMON='-std=gnu17 -Wno-error=...'` for the old C code on GCC 16; MrSID/Kakadu are unavailable on ARM64.
3. `deps-build.sh`, `liblas-build.sh` (needs `CMAKE_POLICY_VERSION_MINIMUM=3.5`; libLAS consumes LASzip through Conan and
   needs LASzip's internal `*.hpp` in the package), then `conan export-pkg` each recipe in `conan/`.
4. `cesium-build.sh` (`VCPKG_FORCE_SYSTEM_BINARIES=1`, triplet `arm64-linux`; 26 vcpkg ports then cesium-native, ~1 h on a CM4), then `post-cesium.sh` packages `cesium-native/0.40.1` (Cesium, s2geometry, abseil and the other static libs plus headers).
5. `post-ttp.sh` packages `ttp-dist/4.2.4` and runs `engine-build.sh` → `libtakengine.so`, `libtakenginejni.so`; package into
   `takkernel-engine-rt-linuxarm64-9.11.5.jar` under `libs/linuxarm64/` together with `libgdal`, `libgdalalljni`,
   `libspatialite`, `libtbb`, `libogdi`, `liblas`, `liblas_c` (`libGLESv2` already ships ARM64 in `gles-jogl-c-1.0.3.jar`),
   and register it in `modules/gov/tak/kernel/main/module.xml`.

## Facts that bound the result

* TPC's own x86_64 `libtakenginejni` exports 1,375 of the 1,517 native methods declared by the 5.8.0 kernel jars;
  the other 142 (all 123 `GLES10` plus 19 others) are unimplemented on x86_64 too and never referenced by TAKX
  client code. Parity with the x86_64 export list is the measurable bar (`tools/gen_filler.py` against `nm -D`).
* The public engine source is kernel 8.30.5 (with 8.46 backports). TAKX branches pin: 5.7 → 8.57.11, 5.8 → 9.11.5,
  5.8.1 → 9.12.6. Entry points that exist only in the 9.x engine have no public implementation; those stay absent
  (loud `UnsatisfiedLinkError`) rather than being stubbed, and need TPC (takx@tak.gov) for a zero-gap runtime.
* Box64 cannot run the bundled x86_64 JVM (HotSpot crashes within ~30 s; box64 issue #3864), so emulation is not an option.
* `artifacts.tak.gov` sits behind Appgate SDP (browser SSO only); Gradle cannot reach it from an unenrolled machine.
