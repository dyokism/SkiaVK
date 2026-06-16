#!/system/bin/sh
# skia_vulkan - post-fs-data.sh
# early boot: safe property injection with bootloop guard

# shellcheck disable=SC3043


MODDIR=${0%/*}

# source shared utilities
. "$MODDIR/util.sh"

# cleanup and error logging trap
cleanup() {
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        echo "[$(get_timestamp)]: [FATAL] post-fs-data.sh failed with exit code $exit_code" >> "$LOG_FILE"
        echo "<3>skia_vulkan: post-fs-data.sh failed with exit code $exit_code" >> /dev/kmsg 2>/dev/null
    fi
}
trap cleanup EXIT

# run in function to avoid exit in sourced contexts
run_post_fs_data() {
    mkdir -p "$PERSISTENT" 2>/dev/null
    chmod 700 "$PERSISTENT" 2>/dev/null

    # initialize persistent log file (overwrite per boot)
    echo "=== SkiaVK Boot Log ===" > "$LOG_FILE"
    echo "[$(get_timestamp)]: [INFO] early boot: post-fs-data.sh started." >> "$LOG_FILE"

    # check resetprop availability
    if [ ! -x "$RESETPROP" ] && ! command -v "$RESETPROP" >/dev/null 2>&1; then
        echo "[$(get_timestamp)]: [ERROR] resetprop binary not found in PATH or standard directories." >> "$LOG_FILE"
        echo "<3>skia_vulkan: resetprop not found, aborting property injection." >> /dev/kmsg 2>/dev/null
        update_description "[ERROR!][WARNING!] NO RESETPROP AAHHHhhHH"
        return 1
    fi

    # load state using a pure posix loop to avoid subshell and process forks
    local BOOT_COUNTER=0
    local COMPLETED_FLAG=1 # default to 1 (completed) on fresh install or reset
    if [ -f "$STATE_FILE" ]; then
        while IFS= read -r line; do
            case "$line" in
                BOOT_COUNTER=*) BOOT_COUNTER="${line#*=}" ;;
                COMPLETED_FLAG=*) COMPLETED_FLAG="${line#*=}" ;;
            esac
        done < "$STATE_FILE"
        
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
    echo "[$(get_timestamp)]: [INFO] boot counter: ${BOOT_COUNTER}/3" >> "$LOG_FILE"

    # safe bootloop check (limit 3 failed boots)
    if [ "$BOOT_COUNTER" -ge 3 ]; then
        echo "<3>skia_vulkan: bootloop detected, disabling module." >> /dev/kmsg 2>/dev/null
        echo "[$(get_timestamp)]: [ERROR] Bootloop detected! Disabling module." >> "$LOG_FILE"
        
        # disable module
        touch "$MODDIR/disable"
        
        # reset state atomically so the module can be safely re-enabled later
        write_state 0 1
        
        # update description on failure
        update_description "Bootloop guard triggered! Please re-enable me :("
        return 0
    fi

    # apply early property injection with -n (no property_service socket dependency)
    echo "[$(get_timestamp)]: [INFO] applying debug.hwui.renderer=skiavk via $RESETPROP -n" >> "$LOG_FILE"
    "$RESETPROP" -n debug.hwui.renderer skiavk

    # surfaceflinger renderengine vulkan (opt-in)
    if [ -f "$PERSISTENT/enable_renderengine" ]; then
        echo "[$(get_timestamp)]: [INFO] opt-in found, applying debug.renderengine.backend=skiavk" >> "$LOG_FILE"
        "$RESETPROP" -n debug.renderengine.backend skiavk
    fi

    # verify if resetprop succeeded (using resetprop instead of getprop to avoid init deadlock)
    local VERIFIED_RENDERER
    VERIFIED_RENDERER=$("$RESETPROP" debug.hwui.renderer 2>/dev/null)
    VERIFIED_RENDERER="${VERIFIED_RENDERER%%[[:cntrl:]]}"
    if [ "$VERIFIED_RENDERER" = "skiavk" ]; then
        echo "<6>skia_vulkan: successfully applied skiavk." >> /dev/kmsg 2>/dev/null
        echo "[$(get_timestamp)]: [SUCCESS] successfully applied skiavk (early boot)" >> "$LOG_FILE"
        if [ -f "$PERSISTENT/enable_renderengine" ]; then
            update_description "status: active (skiavk+RE) | bootloop guard: armed (${BOOT_COUNTER}/3)"
        else
            update_description "status: active (skiavk) | bootloop guard: armed (${BOOT_COUNTER}/3)"
        fi
    else
        echo "<3>skia_vulkan: failed to apply skiavk." >> /dev/kmsg 2>/dev/null
        echo "[$(get_timestamp)]: [ERROR] failed to apply skiavk (early boot)" >> "$LOG_FILE"
        update_description "failed to apply skiavk renderer :("
    fi
}

run_post_fs_data
