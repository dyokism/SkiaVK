#!/system/bin/sh
# skia_vulkan - action.sh
# kernelsu/apatch custom action to reset bootloop counter

MODDIR=${0%/*}
PERSISTENT="/data/adb/skia_vulkan"
STATE_FILE="$PERSISTENT/boot_state"

# reset state
mkdir -p "$PERSISTENT" 2>/dev/null
echo "BOOT_COUNTER=0" > "$STATE_FILE"
echo "COMPLETED_FLAG=1" >> "$STATE_FILE"

# remove disable flag to re-enable module
rm -f "$MODDIR/disable"

# reset description to armed status
if [ -f "$MODDIR/module.prop" ]; then
    temp_prop="$MODDIR/module.prop.tmp"
    (
        grep -v '^description=' "$MODDIR/module.prop"
        echo "description=status: active (skiavk) | bootloop guard: armed (0/3)"
    ) > "$temp_prop" && mv "$temp_prop" "$MODDIR/module.prop"
fi

# print status messages to ui
echo "- Bootloop counter has been reset."
echo "- Please reboot your device to apply changes."
