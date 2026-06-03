#!/system/bin/sh
# shellcheck disable=SC3043,SC2034
# skia_vulkan - util.sh
# shared variables and utility functions for skiavk module

# ensure moddir is set correctly
if [ -z "$MODDIR" ]; then
    MODDIR=${0%/*}
fi

PERSISTENT="/data/adb/skia_vulkan"
STATE_FILE="$PERSISTENT/boot_state"
LOG_FILE="$PERSISTENT/skia_vulkan.log"

# resolve resetprop path for kernelsu/apatch early boot
RESETPROP="resetprop"
if ! command -v resetprop >/dev/null 2>&1; then
    for path in \
        /data/adb/ksu/bin/resetprop \
        /data/adb/apatch/bin/resetprop \
        /data/adb/magisk/resetprop \
        /data/adb/ap/bin/resetprop; do
        if [ -x "$path" ]; then
            RESETPROP="$path"
            break
        fi
    done
fi

# update module description in module.prop
update_description() {
    local desc="$1"
    if [ -f "$MODDIR/module.prop" ]; then
        local temp_prop="$MODDIR/module.prop.tmp"
        (
            grep -v '^description=' "$MODDIR/module.prop"
            echo "description=$desc"
        ) > "$temp_prop" && mv "$temp_prop" "$MODDIR/module.prop" || echo "$(date): [WARN] prop update failed" >> "$LOG_FILE"
    fi
}

# atomic write to the state file
write_state() {
    local boot_counter="$1"
    local completed_flag="$2"
    mkdir -p "$PERSISTENT" 2>/dev/null
    chmod 700 "$PERSISTENT" 2>/dev/null
    printf "BOOT_COUNTER=%s\nCOMPLETED_FLAG=%s\n" "$boot_counter" "$completed_flag" \
        > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}
