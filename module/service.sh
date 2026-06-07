#!/system/bin/sh
# skia_vulkan - service.sh
# late boot: confirm successful boot, disarm guard, and apply airtight recovery

set -e

MODDIR=${0%/*}

# source shared utilities
. "$MODDIR/util.sh"

# cleanup and error logging trap
cleanup() {
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        echo "[$(get_timestamp)]: [FATAL] service.sh failed with exit code $exit_code" >> "$LOG_FILE"
        echo "<3>skia_vulkan: service.sh failed with exit code $exit_code" >> /dev/kmsg 2>/dev/null
    fi
}
trap cleanup EXIT

run_service() {
    # exit early if module is disabled
    if [ -f "$MODDIR/disable" ]; then
        echo "[$(get_timestamp)]: [INFO] late boot: module disabled, service.sh exiting." >> "$LOG_FILE"
        return 0
    fi

    echo "[$(get_timestamp)]: [INFO] late boot: service.sh started, waiting for boot completion..." >> "$LOG_FILE"

    # wait for boot completion (robust polling to avoid resetprop -w hangs)
    local timeout=480
    local elapsed=0
    until [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] || {
        local val
        val=$("$RESETPROP" sys.boot_completed 2>/dev/null)
        [ "${val%$(printf '\r')}" = "1" ]
    }; do
        if [ "$elapsed" -ge "$timeout" ]; then
            echo "[$(get_timestamp)]: [WARNING] boot completion timeout reached (${elapsed}s)." >> "$LOG_FILE"
            echo "<4>skia_vulkan: boot completion timeout reached." >> /dev/kmsg 2>/dev/null
            update_description "Why is ur boot time so long?"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    # check resetprop availability for property injection
    if ! command -v "$RESETPROP" >/dev/null 2>&1; then
        echo "[$(get_timestamp)]: [ERROR] resetprop binary not found. Skipping late boot recovery." >> "$LOG_FILE"
        echo "<3>skia_vulkan: resetprop not found." >> /dev/kmsg 2>/dev/null
        write_state 0 1
        return 1
    fi

    # fallback: re-apply if property is overridden
    echo "[$(get_timestamp)]: [INFO] late boot: boot completed, verifying renderer state..." >> "$LOG_FILE"
    local ACTIVE_RENDERER
    ACTIVE_RENDERER=$("$RESETPROP" debug.hwui.renderer 2>/dev/null | tr -d '\r')
    if [ "$ACTIVE_RENDERER" != "skiavk" ]; then
        echo "[$(get_timestamp)]: [WARNING] late boot: override detected ($ACTIVE_RENDERER), re-applying skiavk" >> "$LOG_FILE"
        "$RESETPROP" -n debug.hwui.renderer skiavk
        echo "<4>skia_vulkan: late-boot override detected, re-applied skiavk." >> /dev/kmsg 2>/dev/null
    fi

    # disarm bootloop guard atomically
    write_state 0 1
    echo "[$(get_timestamp)]: [INFO] late boot: bootloop guard disarmed." >> "$LOG_FILE"

    # verify final state of renderer
    local FINAL_RENDERER
    FINAL_RENDERER=$("$RESETPROP" debug.hwui.renderer 2>/dev/null | tr -d '\r')
    if [ "$FINAL_RENDERER" = "skiavk" ]; then
        update_description "status: active (skiavk) | boot: normal ;)"
        echo "<6>skia_vulkan: boot successful, bootloop guard disarmed." >> /dev/kmsg 2>/dev/null
        echo "[$(get_timestamp)]: [SUCCESS] successfully enforced skiavk renderer (late boot)" >> "$LOG_FILE"
    else
        update_description "status: failed to apply skiavk | but at least boot still normal ;)"
        echo "<3>skia_vulkan: boot successful, but failed to enforce skiavk renderer." >> /dev/kmsg 2>/dev/null
        echo "[$(get_timestamp)]: [ERROR] failed to enforce skiavk renderer (late boot)" >> "$LOG_FILE"
    fi
}

run_service
