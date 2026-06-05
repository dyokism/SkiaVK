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
update_description "status: active (skiavk) | bootloop guard: armed (0/3)"

# print status messages to ui
echo "- Bootloop counter has been reset."
echo "- Please reboot your device to apply changes."
