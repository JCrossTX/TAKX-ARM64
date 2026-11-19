#!/bin/sh
# After the TAK third-party build: package it as the Conan 'ttp-dist/4.2.4' the engine recipe expects, then build the engine.
export PATH=/home/kali/.cache/conan-venv/bin:/opt/jdk17/bin:$PATH
export JAVA_HOME=/opt/jdk17
TTP=/home/kali/.cache/atak-civ-src/takthirdparty
echo "=== post-TTP start $(date) ==="
ls "$TTP/builds/linux-arm64v8-release/lib" | grep -E '\.(a|so)' | tr '\n' ' '; echo
ln -sfn builds/linux-arm64v8-release "$TTP/linux-arm64v8-release"
cd "$TTP/ci-support" || exit 1
conan export-pkg . -f 2>&1 | grep -E 'ERROR|Packaged|created' | tail -6
conan search ttp-dist 2>&1 | tail -2
echo "=== engine build $(date) ==="
sh /home/kali/.cache/engine-build.sh
rc=$?
echo "=== post-TTP finished rc=$rc $(date) ==="
exit $rc
