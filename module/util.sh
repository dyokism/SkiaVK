#!/system/bin/sh
# shellcheck disable=SC3043,SC2034
# skia_vulkan - util.sh
# shared variables and utility functions for skiavk module

# ensure moddir is set correctly
if [ -z "$MODDIR" ]; then
    MODDIR=${0%/*}
fi

PERSISTENT="/data/adb/skia_vulkan"
[ -d "$PERSISTENT" ] || { mkdir -p "$PERSISTENT" && chmod 700 "$PERSISTENT"; } 2>/dev/null
STATE_FILE="$PERSISTENT/boot_state"
LOG_FILE="$PERSISTENT/skia_vulkan.log"

# helper to retrieve monotonic boot uptime or date fallback
get_timestamp() {
    if [ -f /proc/uptime ]; then
        local uptime
        read -r uptime _ < /proc/uptime
        echo "${uptime}s"
    else
        date "+%Y-%m-%d %H:%M:%S"
    fi
}

# resolve resetprop path for kernelsu/apatch early boot
RESETPROP="resetprop"
if ! command -v resetprop >/dev/null 2>&1; then
    for path in \
        /data/adb/ksu/bin/resetprop \
        /data/adb/magisk/resetprop \
        /data/adb/ap/bin/resetprop \
        /sbin/resetprop \
        /debug_ramdisk/resetprop; do
        if [ -x "$path" ]; then
            RESETPROP="$path"
            break
        fi
    done
fi

# update module description in module.prop
update_description() {
    local desc="$1"
    [ -f "$MODDIR/module.prop" ] || return 1
    local temp_prop="$MODDIR/module.prop.tmp"
    
    if grep -v '^description=' "$MODDIR/module.prop" > "$temp_prop" && echo "description=$desc" >> "$temp_prop"; then
        if mv -f "$temp_prop" "$MODDIR/module.prop" 2>/dev/null || { cp -f "$temp_prop" "$MODDIR/module.prop" && rm -f "$temp_prop"; }; then
            return 0
        fi
    fi
    
    echo "[$(get_timestamp)]: [WARN] prop update failed" >> "$LOG_FILE"
    echo "<4>skia_vulkan: prop update failed" >> /dev/kmsg 2>/dev/null
    rm -f "$temp_prop" 2>/dev/null
    return 1
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
