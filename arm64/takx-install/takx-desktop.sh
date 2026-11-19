#!/bin/sh
# Desktop-icon wrapper for TAKX on this ARM64 Pi.
# Runs the normal install4j launcher; if TAKX aborts during startup because the
# TAK kernel native libraries could not be loaded (the known blocker on aarch64),
# show the reason instead of failing silently.
cd /opt/TAKX || exit 1
start=$(date +%s)
./TAKX "$@"
rc=$?
if [ -f error.log ] && [ "$(stat -c %Y error.log)" -ge "$start" ] \
   && grep -qE 'Failed to load native libraries|UnsatisfiedLinkError' error.log; then
    notify-send -u critical "TAKX failed to start" "TAK kernel native libraries for ARM64 are missing. Details: /opt/TAKX/error.log" 2>/dev/null || true
    {
        echo "TAKX could not start on this machine."
        echo
        echo "The TAK kernel engine shipped in this installer only has x86_64 Linux"
        echo "native libraries (takkernel-engine-rt-linux64), and TAKX needs them at"
        echo "startup. The 'linuxarm64' variant is required for this Raspberry Pi."
        echo
        echo "Details: /opt/TAKX/error.log"
        echo "------------------------------------------------------------"
        head -c 1500 error.log
    } | xmessage -center -file - 2>/dev/null || true
fi
exit $rc
