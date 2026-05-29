#!/system/bin/sh
# skia_vulkan - uninstall.sh
# clean up persistent data

PERSISTENT="/data/adb/skia_vulkan"

if [ -d "$PERSISTENT" ]; then
    rm -rf "$PERSISTENT"
fi
