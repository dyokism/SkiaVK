#!/system/bin/sh
# skia_vulkan - action.sh
# kernelsu/apatch custom action to reset bootloop counter

MODDIR=${0%/*}

# source shared utilities
. "$MODDIR/util.sh"

# reset state atomically
write_state 0 1
echo "$(date): [INFO] action.sh: counter reset by user." >> "$LOG_FILE"

# remove disable flag to re-enable module
rm -f "$MODDIR/disable"

# reset description to armed status
update_description "status: active (skiavk) | bootloop guard: u reset it earlier bruh"

# note: reboot is required to restart systemui and apply renderer changes

# print status messages to ui
if command -v ui_print >/dev/null 2>&1; then
    ui_print "- Bootloop counter has been reset."
    ui_print "- Please reboot your device to apply changes."
else
    echo "- Bootloop counter has been reset."
    echo "- Please reboot your device to apply changes."
fi
