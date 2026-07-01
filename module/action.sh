#!/system/bin/sh
# shellcheck disable=SC3043

MODDIR=${0%/*}
. "$MODDIR/util.sh"

(
    write_state 0 1
    log_info "action.sh: counter reset by user."
    rm -f "$MODDIR/disable"
    if [ -f "$PERSISTENT/enable_renderengine" ]; then
        update_description "status: active (skiavk+RE) | bootloop guard: u reset it earlier bruh"
    else
        update_description "status: active (skiavk) | bootloop guard: u reset it earlier bruh"
    fi
) >/dev/null 2>&1 &

if command -v ui_print >/dev/null 2>&1; then
    ui_print "- Bootloop counter has been reset."
    ui_print "- Please reboot your device to apply changes."
else
    echo "- Bootloop counter has been reset."
    echo "- Please reboot your device to apply changes."
fi
