#!/system/bin/sh
# skia_vulkan - service.sh
# late boot: confirm successful boot, disarm guard, and apply airtight recovery

set -eu

MODDIR=${0%/*}

# source shared utilities
. "$MODDIR/util.sh"

# Cleanup and error logging trap
cleanup() {
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        echo "$(date): [FATAL] service.sh failed with exit code $exit_code" >> "$LOG_FILE"
        echo "<3>skia_vulkan: service.sh failed with exit code $exit_code" >> /dev/kmsg
    fi
}
trap cleanup EXIT

run_service() {
    # exit early if module is disabled
    if [ -f "$MODDIR/disable" ]; then
        echo "$(date): [INFO] late boot: module disabled, service.sh exiting." >> "$LOG_FILE"
        return 0
    fi

    echo "$(date): [INFO] late boot: service.sh started, waiting for boot completion..." >> "$LOG_FILE"

    # Wait for boot completion
    if command -v "$RESETPROP" >/dev/null 2>&1; then
        # Use resetprop -w (efficient blocking wait)
        "$RESETPROP" -w sys.boot_completed 0 &
        local wait_pid=$!

        (
            sleep 480
            if kill -0 "$wait_pid" 2>/dev/null; then
                echo "$(date): [WARNING] boot completion timeout reached (480s)." >> "$LOG_FILE"
                echo "<4>skia_vulkan: boot completion timeout reached." >> /dev/kmsg
                update_description "status: timeout waiting for boot completion"
                kill "$wait_pid" 2>/dev/null
            fi
        ) &
        local watchdog_pid=$!

        if ! wait "$wait_pid"; then
            kill "$watchdog_pid" 2>/dev/null
            return 0
        fi
        kill "$watchdog_pid" 2>/dev/null
    else
        # Fallback to polling getprop if resetprop is not available
        local timeout=480
        local elapsed=0
        until [ "$(getprop sys.boot_completed)" = "1" ]; do
            if [ "$elapsed" -ge "$timeout" ]; then
                echo "$(date): [WARNING] boot completion timeout reached (${elapsed}s)." >> "$LOG_FILE"
                echo "<4>skia_vulkan: boot completion timeout reached." >> /dev/kmsg
                update_description "status: timeout waiting for boot completion"
                return 0
            fi
            sleep 2
            elapsed=$((elapsed + 2))
        done
    fi

    # check resetprop availability for property injection
    if ! command -v "$RESETPROP" >/dev/null 2>&1; then
        echo "$(date): [ERROR] resetprop binary not found. Skipping late boot recovery." >> "$LOG_FILE"
        echo "<3>skia_vulkan: resetprop not found." >> /dev/kmsg
        write_state 0 1
        return 1
    fi

    # fallback: re-apply if property is overridden
    echo "$(date): [INFO] late boot: boot completed, verifying renderer state..." >> "$LOG_FILE"
    local ACTIVE_RENDERER
    ACTIVE_RENDERER=$("$RESETPROP" debug.hwui.renderer 2>/dev/null | tr -d '\r')
    if [ "$ACTIVE_RENDERER" != "skiavk" ]; then
        echo "$(date): [WARNING] late boot: override detected ($ACTIVE_RENDERER), re-applying skiavk" >> "$LOG_FILE"
        "$RESETPROP" debug.hwui.renderer skiavk
        echo "<4>skia_vulkan: late-boot override detected, re-applied skiavk." >> /dev/kmsg
    fi

    # disarm bootloop guard atomically
    write_state 0 1
    echo "$(date): [INFO] late boot: bootloop guard disarmed." >> "$LOG_FILE"

    # verify final state of renderer
    local FINAL_RENDERER
    FINAL_RENDERER=$("$RESETPROP" debug.hwui.renderer 2>/dev/null | tr -d '\r')
    if [ "$FINAL_RENDERER" = "skiavk" ]; then
        update_description "status: active (skiavk) | boot: ok"
        echo "<6>skia_vulkan: boot successful, bootloop guard disarmed." >> /dev/kmsg
        echo "$(date): [SUCCESS] successfully enforced skiavk renderer (late boot)" >> "$LOG_FILE"
    else
        update_description "status: failed to apply skiavk | boot: ok"
        echo "<3>skia_vulkan: boot successful, but failed to enforce skiavk renderer." >> /dev/kmsg
        echo "$(date): [ERROR] failed to enforce skiavk renderer (late boot)" >> "$LOG_FILE"
    fi
}

run_service
