#!/system/bin/sh
# skia_vulkan - service.sh
# late boot: confirm successful boot, disarm guard, and apply airtight recovery

# shellcheck disable=SC3043


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
    until [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] || [ "$("$RESETPROP" sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
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
    if [ ! -x "$RESETPROP" ] && ! command -v "$RESETPROP" >/dev/null 2>&1; then
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

    # verify and re-apply renderengine backend if opt-in file exists
    if [ -f "$PERSISTENT/enable_renderengine" ]; then
        local ACTIVE_RE
        ACTIVE_RE=$("$RESETPROP" debug.renderengine.backend 2>/dev/null | tr -d '\r')
        if [ "$ACTIVE_RE" != "skiavk" ]; then
            echo "[$(get_timestamp)]: [WARNING] late boot: RE override detected ($ACTIVE_RE), re-applying skiavk" >> "$LOG_FILE"
            "$RESETPROP" -n debug.renderengine.backend skiavk
            echo "<4>skia_vulkan: late-boot RE override detected, re-applied skiavk." >> /dev/kmsg 2>/dev/null
        fi
    fi

    # disarm bootloop guard atomically
    write_state 0 1
    echo "[$(get_timestamp)]: [INFO] late boot: bootloop guard disarmed." >> "$LOG_FILE"

    # verify final state of renderer
    local FINAL_RENDERER
    FINAL_RENDERER=$("$RESETPROP" debug.hwui.renderer 2>/dev/null | tr -d '\r')
    local FINAL_RE=""
    if [ -f "$PERSISTENT/enable_renderengine" ]; then
        FINAL_RE=$("$RESETPROP" debug.renderengine.backend 2>/dev/null | tr -d '\r')
    fi

    if [ "$FINAL_RENDERER" = "skiavk" ]; then
        if [ -f "$PERSISTENT/enable_renderengine" ] && [ "$FINAL_RE" = "skiavk" ]; then
            update_description "status: active (skiavk+RE) | boot: normal ;)"
            echo "<6>skia_vulkan: boot successful (skiavk+RE), bootloop guard disarmed." >> /dev/kmsg 2>/dev/null
            echo "[$(get_timestamp)]: [SUCCESS] successfully enforced skiavk+RE renderer (late boot)" >> "$LOG_FILE"
        else
            update_description "status: active (skiavk) | boot: normal ;)"
            echo "<6>skia_vulkan: boot successful (skiavk), bootloop guard disarmed." >> /dev/kmsg 2>/dev/null
            echo "[$(get_timestamp)]: [SUCCESS] successfully enforced skiavk renderer (late boot)" >> "$LOG_FILE"
        fi
    else
        update_description "status: failed to apply skiavk | but at least boot still normal ;)"
        echo "<3>skia_vulkan: boot successful, but failed to enforce skiavk renderer." >> /dev/kmsg 2>/dev/null
        echo "[$(get_timestamp)]: [ERROR] failed to enforce skiavk renderer (late boot)" >> "$LOG_FILE"
    fi
}

run_service
