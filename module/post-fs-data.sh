#!/system/bin/sh
# shellcheck disable=SC3043

MODDIR=${0%/*}
. "$MODDIR/util.sh"

cleanup() {
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        log_err "post-fs-data.sh failed with exit code $exit_code"
    fi
}
trap cleanup EXIT

# We wrap execution in a function because sourcing files in some root managers can cause premature exits.
run_post_fs_data() {
    mkdir -p "$PERSISTENT" 2>/dev/null
    chmod 700 "$PERSISTENT" 2>/dev/null

    echo "=== SkiaVK Boot Log ===" > "$LOG_FILE"
    log_info "early boot: post-fs-data.sh started."

    if [ ! -x "$RESETPROP" ] && ! command -v "$RESETPROP" >/dev/null 2>&1; then
        log_err "resetprop binary not found in PATH or standard directories."
        update_description "[ERROR!][WARNING!] NO RESETPROP AAHHHhhHH"
        return 1
    fi

    local BOOT_COUNTER=0
    local COMPLETED_FLAG=1
    if [ -f "$STATE_FILE" ]; then
        # Pure POSIX loops avoid expensive subshell forks during early init phase where timing is critical.
        while IFS= read -r line; do
            case "$line" in
                BOOT_COUNTER=*) BOOT_COUNTER="${line#*=}" ;;
                COMPLETED_FLAG=*) COMPLETED_FLAG="${line#*=}" ;;
            esac
        done < "$STATE_FILE"
        
        case "$BOOT_COUNTER" in ''|*[!0-9]*) BOOT_COUNTER=0 ;; esac
        case "$COMPLETED_FLAG" in ''|*[!0-9]*) COMPLETED_FLAG=0 ;; esac
    fi

    if [ "$COMPLETED_FLAG" -ne 1 ]; then
        BOOT_COUNTER=$((BOOT_COUNTER + 1))
    else
        BOOT_COUNTER=0
    fi

    COMPLETED_FLAG=0
    write_state "$BOOT_COUNTER" "$COMPLETED_FLAG"
    log_info "boot counter: ${BOOT_COUNTER}/3"

    # Limit to 3 failed boots to prevent permanent soft-bricks.
    if [ "$BOOT_COUNTER" -ge 3 ]; then
        log_err "Bootloop detected! Disabling module."
        touch "$MODDIR/disable"
        write_state 0 1
        update_description "Bootloop guard triggered! Please re-enable me :("
        return 0
    fi

    log_info "applying debug.hwui.renderer=skiavk via $RESETPROP -n"
    "$RESETPROP" -n debug.hwui.renderer skiavk

    if [ -f "$PERSISTENT/enable_renderengine" ]; then
        log_info "opt-in found, applying debug.renderengine.backend=skiavk"
        "$RESETPROP" -n debug.renderengine.backend skiavk
    fi

    # Verify state against resetprop rather than getprop since early init may deadlock property_service sockets.
    local VERIFIED_RENDERER
    VERIFIED_RENDERER=$("$RESETPROP" debug.hwui.renderer 2>/dev/null)
    VERIFIED_RENDERER="${VERIFIED_RENDERER%%[[:cntrl:]]}"
    
    if [ "$VERIFIED_RENDERER" = "skiavk" ]; then
        log_info "successfully applied skiavk (early boot)"
        if [ -f "$PERSISTENT/enable_renderengine" ]; then
            update_description "status: active (skiavk+RE) | bootloop guard: armed (${BOOT_COUNTER}/3)"
        else
            update_description "status: active (skiavk) | bootloop guard: armed (${BOOT_COUNTER}/3)"
        fi
    else
        log_err "failed to apply skiavk (early boot)"
        update_description "failed to apply skiavk renderer :("
    fi
}

run_post_fs_data
