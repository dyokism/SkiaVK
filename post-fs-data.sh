#!/system/bin/sh
# skia_vulkan - post-fs-data.sh
# early boot: safe property injection with bootloop guard

MODDIR=${0%/*}
PERSISTENT="/data/adb/skia_vulkan"
STATE_FILE="$PERSISTENT/boot_state"

# define helper function
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

mkdir -p "$PERSISTENT" 2>/dev/null
chmod 700 "$PERSISTENT" 2>/dev/null

# load state
BOOT_COUNTER=0
COMPLETED_FLAG=0
if [ -f "$STATE_FILE" ]; then
    BOOT_COUNTER=$(grep '^BOOT_COUNTER=' "$STATE_FILE" | cut -d'=' -f2 | tr -d '\r')
    COMPLETED_FLAG=$(grep '^COMPLETED_FLAG=' "$STATE_FILE" | cut -d'=' -f2 | tr -d '\r')
    
    # defensive numerical validation using case/regex
    case "$BOOT_COUNTER" in
        ''|*[!0-9]*) BOOT_COUNTER=0 ;;
    esac
    case "$COMPLETED_FLAG" in
        ''|*[!0-9]*) COMPLETED_FLAG=0 ;;
    esac
fi

# increment boot counter if previous boot failed
if [ "$COMPLETED_FLAG" -ne 1 ]; then
    BOOT_COUNTER=$((BOOT_COUNTER + 1))
else
    BOOT_COUNTER=0
fi

# clear completed flag for current boot
COMPLETED_FLAG=0

# save current state
echo "BOOT_COUNTER=$BOOT_COUNTER" > "$STATE_FILE"
echo "COMPLETED_FLAG=$COMPLETED_FLAG" >> "$STATE_FILE"

# safe bootloop check (limit 3 failed boots)
if [ "$BOOT_COUNTER" -ge 3 ]; then
    echo "skia_vulkan: bootloop detected, disabling module." >> /dev/kmsg
    
    # disable module
    touch "$MODDIR/disable"
    
    # update description on failure
    update_description "anti-bootloop triggered. module disabled. re-enable to activate."
    exit 0
fi

# apply early property injection
resetprop debug.hwui.renderer skiavk

# verify if resetprop succeeded
VERIFIED_RENDERER=$(getprop debug.hwui.renderer 2>/dev/null | tr -d '\r')
if [ "$VERIFIED_RENDERER" = "skiavk" ]; then
    echo "skia_vulkan: successfully applied skiavk." >> /dev/kmsg
    update_description "status: active (skiavk) | bootloop guard: armed (${BOOT_COUNTER}/3)"
else
    echo "skia_vulkan: failed to apply skiavk." >> /dev/kmsg
    update_description "failed to apply skiavk renderer."
fi
