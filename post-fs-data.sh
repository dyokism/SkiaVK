#!/system/bin/sh
# skia_vulkan - post-fs-data.sh
# early boot: safe property injection with bootloop guard

MODDIR=${0%/*}

# source shared utilities
. "$MODDIR/util.sh"

mkdir -p "$PERSISTENT" 2>/dev/null
chmod 700 "$PERSISTENT" 2>/dev/null

# initialize persistent log file (overwrite per boot)
echo "=== SkiaVK Boot Log ===" > "$LOG_FILE"
echo "$(date): [INFO] early boot: post-fs-data.sh started." >> "$LOG_FILE"

# check resetprop availability
if ! command -v "$RESETPROP" >/dev/null 2>&1; then
    echo "$(date): [ERROR] resetprop binary not found in PATH or standard directories." >> "$LOG_FILE"
    echo "<3>skia_vulkan: resetprop not found, aborting property injection." >> /dev/kmsg
    update_description "error: resetprop not found in PATH"
    exit 1
fi

# load state
BOOT_COUNTER=0
COMPLETED_FLAG=1 # default to 1 (completed) on fresh install or reset
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

# clear completed flag for current boot (will be set to 1 by service.sh on success)
COMPLETED_FLAG=0

# save current state atomically
write_state "$BOOT_COUNTER" "$COMPLETED_FLAG"
echo "$(date): [INFO] boot counter: ${BOOT_COUNTER}/3" >> "$LOG_FILE"

# safe bootloop check (limit 3 failed boots)
if [ "$BOOT_COUNTER" -ge 3 ]; then
    echo "<3>skia_vulkan: bootloop detected, disabling module." >> /dev/kmsg
    echo "$(date): [ERROR] Bootloop detected! Disabling module." >> "$LOG_FILE"
    
    # disable module
    touch "$MODDIR/disable"
    
    # update description on failure
    update_description "anti-bootloop triggered. module disabled. re-enable to activate."
    exit 0
fi

# apply early property injection
echo "$(date): [INFO] applying debug.hwui.renderer=skiavk via $RESETPROP" >> "$LOG_FILE"
"$RESETPROP" debug.hwui.renderer skiavk

# verify if resetprop succeeded
VERIFIED_RENDERER=$(getprop debug.hwui.renderer 2>/dev/null | tr -d '\r')
if [ "$VERIFIED_RENDERER" = "skiavk" ]; then
    echo "<6>skia_vulkan: successfully applied skiavk." >> /dev/kmsg
    echo "$(date): [SUCCESS] successfully applied skiavk (early boot)" >> "$LOG_FILE"
    update_description "status: active (skiavk) | bootloop guard: armed (${BOOT_COUNTER}/3)"
else
    echo "<3>skia_vulkan: failed to apply skiavk." >> /dev/kmsg
    echo "$(date): [ERROR] failed to apply skiavk (early boot)" >> "$LOG_FILE"
    update_description "failed to apply skiavk renderer."
fi
