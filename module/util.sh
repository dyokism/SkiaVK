#!/system/bin/sh
# shellcheck disable=SC3043,SC2034

MODDIR="${MODDIR:-${0%/*}}"
PERSISTENT="/data/adb/skia_vulkan"
STATE_FILE="$PERSISTENT/boot_state"
LOG_FILE="$PERSISTENT/skia_vulkan.log"

[ -d "$PERSISTENT" ] || { mkdir -p "$PERSISTENT" && chmod 700 "$PERSISTENT"; } 2>/dev/null

get_timestamp() {
    if [ -f /proc/uptime ]; then
        local uptime
        read -r uptime _ < /proc/uptime
        echo "${uptime}s"
    else
        date "+%Y-%m-%d %H:%M:%S"
    fi
}

log_info() { echo "[$(get_timestamp)]: [INFO] $1" >> "$LOG_FILE"; }
log_warn() { echo "[$(get_timestamp)]: [WARN] $1" >> "$LOG_FILE"; }
log_err() { 
    echo "[$(get_timestamp)]: [ERROR] $1" >> "$LOG_FILE"
    echo "<3>skia_vulkan: $1" >> /dev/kmsg 2>/dev/null
}

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

# Atomic write-then-rename to prevent partial module.prop on hard crashes.
update_description() {
    local desc="$1"
    [ -f "$MODDIR/module.prop" ] || return 1
    local tmp="$MODDIR/module.prop.tmp"
    
    if grep -v '^description=' "$MODDIR/module.prop" > "$tmp" && echo "description=$desc" >> "$tmp"; then
        if mv -f "$tmp" "$MODDIR/module.prop" 2>/dev/null || { cp -f "$tmp" "$MODDIR/module.prop" && rm -f "$tmp"; }; then
            return 0
        fi
    fi
    
    log_err "prop update failed"
    rm -f "$tmp" 2>/dev/null
    return 1
}

# POSIX rename guarantees bootloop state isn't partially written if the device hard-crashes.
write_state() {
    local boot_counter="$1"
    local completed_flag="$2"
    mkdir -p "$PERSISTENT" 2>/dev/null
    chmod 700 "$PERSISTENT" 2>/dev/null
    printf "BOOT_COUNTER=%s\nCOMPLETED_FLAG=%s\n" "$boot_counter" "$completed_flag" \
        > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}
