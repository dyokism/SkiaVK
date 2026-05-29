#!/system/bin/sh
# skia_vulkan - service.sh
# late boot: confirm successful boot, disarm guard, and apply airtight recovery

MODDIR=${0%/*}
PERSISTENT="/data/adb/skia_vulkan"
STATE_FILE="$PERSISTENT/boot_state"

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

# wait for boot completion
TIMEOUT=300
ELAPSED=0
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
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
ACTIVE_RENDERER=$(getprop debug.hwui.renderer 2>/dev/null | tr -d '\r')
if [ "$ACTIVE_RENDERER" != "skiavk" ] && [ "$BOOT_COUNTER" -lt 3 ]; then
    resetprop debug.hwui.renderer skiavk
    echo "skia_vulkan: late-boot override detected, re-applied skiavk." >> /dev/kmsg
fi

# disarm bootloop guard
if [ -d "$PERSISTENT" ]; then
    echo "BOOT_COUNTER=0" > "$STATE_FILE"
    echo "COMPLETED_FLAG=1" >> "$STATE_FILE"
fi

# update description to success
update_description "status: active (skiavk) | boot: ok"
echo "skia_vulkan: boot successful, bootloop guard disarmed." >> /dev/kmsg
