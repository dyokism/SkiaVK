#!/system/bin/sh
# skia_vulkan - service.sh
# late boot: confirm successful boot, disarm guard, and apply airtight recovery

MODDIR=${0%/*}

# source shared utilities
. "$MODDIR/util.sh"

# exit early if module is disabled
if [ -f "$MODDIR/disable" ]; then
    echo "$(date): [INFO] late boot: module disabled, service.sh exiting." >> "$LOG_FILE"
    exit 0
fi

echo "$(date): [INFO] late boot: service.sh started, waiting for boot completion..." >> "$LOG_FILE"

# wait for boot completion
TIMEOUT=480
ELAPSED=0
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "$(date): [WARNING] boot completion timeout reached (${ELAPSED}s)." >> "$LOG_FILE"
        echo "<4>skia_vulkan: boot completion timeout reached." >> /dev/kmsg
        update_description "status: timeout waiting for boot completion"
        exit 0
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

# check resetprop availability
if ! command -v "$RESETPROP" >/dev/null 2>&1; then
    echo "$(date): [ERROR] resetprop binary not found. Skipping late boot recovery." >> "$LOG_FILE"
    echo "<3>skia_vulkan: resetprop not found." >> /dev/kmsg
    write_state 0 1
    exit 1
fi

# fallback: re-apply if property is overridden
echo "$(date): [INFO] late boot: boot completed, verifying renderer state..." >> "$LOG_FILE"
ACTIVE_RENDERER=$(getprop debug.hwui.renderer 2>/dev/null | tr -d '\r')
if [ "$ACTIVE_RENDERER" != "skiavk" ]; then
    echo "$(date): [WARNING] late boot: override detected ($ACTIVE_RENDERER), re-applying skiavk" >> "$LOG_FILE"
    "$RESETPROP" debug.hwui.renderer skiavk
    echo "<4>skia_vulkan: late-boot override detected, re-applied skiavk." >> /dev/kmsg
fi

# disarm bootloop guard atomically
write_state 0 1
echo "$(date): [INFO] late boot: bootloop guard disarmed." >> "$LOG_FILE"

# verify final state of renderer
FINAL_RENDERER=$(getprop debug.hwui.renderer 2>/dev/null | tr -d '\r')
if [ "$FINAL_RENDERER" = "skiavk" ]; then
    update_description "status: active (skiavk) | boot: ok"
    echo "<6>skia_vulkan: boot successful, bootloop guard disarmed." >> /dev/kmsg
    echo "$(date): [SUCCESS] successfully enforced skiavk renderer (late boot)" >> "$LOG_FILE"
else
    update_description "status: failed to apply skiavk | boot: ok"
    echo "<3>skia_vulkan: boot successful, but failed to enforce skiavk renderer." >> /dev/kmsg
    echo "$(date): [ERROR] failed to enforce skiavk renderer (late boot)" >> "$LOG_FILE"
fi
