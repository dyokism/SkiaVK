#!/system/bin/sh

MODDIR=${0%/*}
if [ -f "$MODDIR/util.sh" ]; then
    . "$MODDIR/util.sh"
else
    PERSISTENT="/data/adb/skia_vulkan"
fi

if [ -d "$PERSISTENT" ]; then
    rm -rf "$PERSISTENT"
fi
