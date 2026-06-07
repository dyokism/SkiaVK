#!/system/bin/sh
# skia_vulkan - customize.sh
# clean, brief installation log with real vulkan hal checks

# enforce minimum sdk (android 10+, api 29)
if [ "$API" -lt 29 ]; then
    abort "[!] Error: Android 10+ (API 29) is required for Skia Vulkan!"
fi

# detect active root manager
if [ "${APATCH:-}" = "true" ]; then
    ui_print "- Root Manager: APatch"
elif [ "${KSU:-}" = "true" ]; then
    ui_print "- Root Manager: KernelSU"
elif [ -n "${MAGISK_VER:-}" ]; then
    ui_print "- Root Manager: Magisk ($MAGISK_VER)"
else
    ui_print "- Root Manager: Unknown / Generic"
fi

ui_print "- Installing SkiaVK..."

# check for software Vulkan renderers to avoid fatal bootloops
VULKAN_PROP=$(getprop ro.hardware.vulkan 2>/dev/null | tr -d '\r')
case "$VULKAN_PROP" in
    pastel|swiftshader|lvp|lavapipe)
        ui_print "[!] Error: Software Vulkan renderer ($VULKAN_PROP) is active!"
        abort "  Software Vulkan is not supported by SkiaVK!"
        ;;
esac

# search for hardware Vulkan HAL libraries (.so files)
HAS_VULKAN_LIB=0
for libpath in \
    /vendor/lib64/hw/vulkan.*.so \
    /vendor/lib/hw/vulkan.*.so \
    /vendor/lib64/vulkan.*.so \
    /vendor/lib/vulkan.*.so \
    /vendor/lib64/libvulkan_*.so \
    /vendor/lib/libvulkan_*.so \
    /system/lib64/hw/vulkan.*.so \
    /system/lib/hw/vulkan.*.so; do
    if [ -f "$libpath" ]; then
        # exclude software renderers (swiftshader, pastel, lavapipe) to avoid false-positives
        case "$libpath" in
            *pastel*|*swiftshader*|*lvp*|*lavapipe*) continue ;;
        esac
        HAS_VULKAN_LIB=1
        break
    fi
done

if [ "$HAS_VULKAN_LIB" -eq 0 ]; then
    ui_print " "
    ui_print "[!] Error:"
    ui_print "  Vulkan hardware driver was not detected on your device."
    ui_print "  Aborting installation to keep your device safe."
    ui_print " "
    abort "  Vulkan is not supported by this device!"
else
    ui_print "- Vulkan hardware driver detected."
fi

ui_print "- Bootloop guard configured."
ui_print "- Installation complete! Please reboot."
