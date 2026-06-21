#!/system/bin/sh

API="${API:-0}"
if [ "$API" -lt 29 ]; then
    abort "[!] Error: Android 10+ (API 29) is required for Skia Vulkan!"
fi

if [ "${APATCH:-}" = "true" ]; then ui_print "- Root Manager: APatch"
elif [ "${KSU:-}" = "true" ]; then ui_print "- Root Manager: KernelSU"
elif [ -n "${MAGISK_VER:-}" ]; then ui_print "- Root Manager: Magisk ($MAGISK_VER)"
else ui_print "- Root Manager: Unknown / Generic"; fi

# Reset persistent state on upgrade to prevent outdated bootloop guard triggers.
rm -f "/data/adb/skia_vulkan/boot_state" "/data/adb/skia_vulkan/skia_vulkan.log"

ui_print "- Installing SkiaVK..."

VULKAN_PROP=$(getprop ro.hardware.vulkan 2>/dev/null)
VULKAN_PROP="${VULKAN_PROP%%[[:cntrl:]]}"
case "$VULKAN_PROP" in
    pastel|swiftshader|lvp|lavapipe)
        ui_print "[!] Error: Software Vulkan renderer ($VULKAN_PROP) is active!"
        abort "  Software Vulkan is not supported by SkiaVK!"
        ;;
esac

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
        # Exclude software renderers from HAL detection to prevent false-positive driver matches on emulated environments.
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
