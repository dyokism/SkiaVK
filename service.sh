#!/system/bin/sh
# skia_vulkan - service.sh
# late boot: confirm successful boot, disarm guard, and apply airtight recovery

MODDIR=${0%/*}
PERSISTENT="/data/adb/skia_vulkan"
STATE_FILE="$PERSISTENT/boot_state"
LOG_FILE="$PERSISTENT/skia_vulkan.log"

# update description helper
update_description() {
    local desc="$1"
    if [ -f "$MODDIR/module.prop" ]; then
        local temp_prop="$MODDIR/module.prop.tmp"
        (
            grep -v '^description=' "$MODDIR/module.prop"
            echo "description=$desc"
        ) > "$temp_prop" && mv "$temp_prop" "$MODDIR/module.prop"
    fi
}

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
        echo "$(date): [WARNING] boot completion timeout reached (${TIMEOUT}s)." >> "$LOG_FILE"
        echo "skia_vulkan: boot completion timeout reached." >> /dev/kmsg
        update_description "status: timeout waiting for boot completion"
        exit 0
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

# load boot counter
BOOT_COUNTER=0
if [ -f "$STATE_FILE" ]; then
    BOOT_COUNTER=$(grep '^BOOT_COUNTER=' "$STATE_FILE" | cut -d'=' -f2 | tr -d '\r')
    case "$BOOT_COUNTER" in
        ''|*[!0-9]*) BOOT_COUNTER=0 ;;
    esac
fi

# fallback: re-apply if property is overridden
# only re-apply if bootloop guard is not triggered
echo "$(date): [INFO] late boot: boot completed, verifying renderer state..." >> "$LOG_FILE"
ACTIVE_RENDERER=$(getprop debug.hwui.renderer 2>/dev/null | tr -d '\r')
if [ "$ACTIVE_RENDERER" != "skiavk" ] && [ "$BOOT_COUNTER" -lt 3 ]; then
    echo "$(date): [WARNING] late boot: override detected ($ACTIVE_RENDERER), re-applying skiavk" >> "$LOG_FILE"
    resetprop debug.hwui.renderer skiavk
    echo "skia_vulkan: late-boot override detected, re-applied skiavk." >> /dev/kmsg
fi

# disarm bootloop guard
if [ -d "$PERSISTENT" ]; then
    echo "BOOT_COUNTER=0" > "$STATE_FILE"
    echo "COMPLETED_FLAG=1" >> "$STATE_FILE"
    echo "$(date): [INFO] late boot: bootloop guard disarmed." >> "$LOG_FILE"
fi

# verify final state of renderer
FINAL_RENDERER=$(getprop debug.hwui.renderer 2>/dev/null | tr -d '\r')
if [ "$FINAL_RENDERER" = "skiavk" ]; then
    update_description "status: active (skiavk) | boot: ok"
    echo "skia_vulkan: boot successful, bootloop guard disarmed." >> /dev/kmsg
    echo "$(date): [SUCCESS] successfully enforced skiavk renderer (late boot)" >> "$LOG_FILE"
else
    update_description "status: failed to apply skiavk | boot: ok"
    echo "skia_vulkan: boot successful, but failed to enforce skiavk renderer." >> /dev/kmsg
    echo "$(date): [ERROR] failed to enforce skiavk renderer (late boot)" >> "$LOG_FILE"
fi
