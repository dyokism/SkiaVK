#!/system/bin/sh
# skia_vulkan - uninstall.sh
# clean up persistent data

MODDIR=${0%/*}
# source util.sh for shared paths. fallback to default path if util.sh is already removed.
if [ -f "$MODDIR/util.sh" ]; then
    . "$MODDIR/util.sh"
else
    # fallback path must match persistent in util.sh
    PERSISTENT="/data/adb/skia_vulkan"
fi

if [ -d "$PERSISTENT" ]; then
    rm -rf "$PERSISTENT"
fi
