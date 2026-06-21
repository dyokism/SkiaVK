#!/system/bin/sh
# shellcheck disable=SC3043

MODDIR=${0%/*}
. "$MODDIR/util.sh"

cleanup() {
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        log_err "service.sh failed with exit code $exit_code"
    fi
}
trap cleanup EXIT

run_service() {
    if [ -f "$MODDIR/disable" ]; then
        log_info "late boot: module disabled, exiting."
        return 0
    fi

    log_info "late boot: waiting for boot completion..."

    # Robust polling handles broken property_service sockets where `resetprop -w` hangs indefinitely.
    local timeout=480
    local elapsed=0
    local boot_val
    while true; do
        boot_val=$(getprop sys.boot_completed 2>/dev/null)
        boot_val="${boot_val%%[[:cntrl:]]}"
        [ "$boot_val" = "1" ] && break

        boot_val=$("$RESETPROP" sys.boot_completed 2>/dev/null)
        boot_val="${boot_val%%[[:cntrl:]]}"
        [ "$boot_val" = "1" ] && break

        if [ "$elapsed" -ge "$timeout" ]; then
            log_warn "boot completion timeout reached (${elapsed}s)."
            update_description "Why is ur boot time so long?"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    if [ ! -x "$RESETPROP" ] && ! command -v "$RESETPROP" >/dev/null 2>&1; then
        log_err "resetprop not found. Skipping late boot recovery."
        write_state 0 1
        return 1
    fi

    # Fallback injection: Some vendor init scripts forcefully override debug.hwui.renderer late in the boot sequence.
    log_info "late boot: boot completed, verifying renderer state..."
    
    local ACTIVE_RENDERER=$("$RESETPROP" debug.hwui.renderer 2>/dev/null)
    ACTIVE_RENDERER="${ACTIVE_RENDERER%%[[:cntrl:]]}"
    if [ "$ACTIVE_RENDERER" != "skiavk" ]; then
        log_warn "late boot: override detected ($ACTIVE_RENDERER), re-applying skiavk"
        "$RESETPROP" -n debug.hwui.renderer skiavk
    fi

    if [ -f "$PERSISTENT/enable_renderengine" ]; then
        local ACTIVE_RE=$("$RESETPROP" debug.renderengine.backend 2>/dev/null)
        ACTIVE_RE="${ACTIVE_RE%%[[:cntrl:]]}"
        if [ "$ACTIVE_RE" != "skiavk" ]; then
            log_warn "late boot: RE override detected ($ACTIVE_RE), re-applying skiavk"
            "$RESETPROP" -n debug.renderengine.backend skiavk
        fi
    fi

    write_state 0 1
    log_info "late boot: bootloop guard disarmed."

    local FINAL_RENDERER=$("$RESETPROP" debug.hwui.renderer 2>/dev/null)
    FINAL_RENDERER="${FINAL_RENDERER%%[[:cntrl:]]}"
    local FINAL_RE=""
    if [ -f "$PERSISTENT/enable_renderengine" ]; then
        FINAL_RE=$("$RESETPROP" debug.renderengine.backend 2>/dev/null)
        FINAL_RE="${FINAL_RE%%[[:cntrl:]]}"
    fi

    if [ "$FINAL_RENDERER" = "skiavk" ]; then
        if [ -f "$PERSISTENT/enable_renderengine" ] && [ "$FINAL_RE" = "skiavk" ]; then
            update_description "status: active (skiavk+RE) | boot: normal ;)"
            log_info "successfully enforced skiavk+RE renderer (late boot)"
        else
            update_description "status: active (skiavk) | boot: normal ;)"
            log_info "successfully enforced skiavk renderer (late boot)"
        fi
    else
        update_description "status: failed to apply skiavk | but at least boot still normal ;)"
        log_err "failed to enforce skiavk renderer (late boot)"
    fi
}

run_service
