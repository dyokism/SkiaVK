#!/system/bin/sh
# skia_vulkan - customize.sh
# clean, brief installation log with real vulkan hal checks

# Enforce minimum SDK level (Android 10+, API 29)
if [ "$API" -lt 29 ]; then
    abort "[!] Error: Android 10+ (API 29) is required for Skia Vulkan!"
fi

# Detect active root manager
if [ "$APATCH" = "true" ]; then
    ui_print "- Root Manager: APatch"
elif [ "$KSU" = "true" ]; then
    ui_print "- Root Manager: KernelSU"
elif [ -n "$MAGISK_VER" ]; then
    ui_print "- Root Manager: Magisk ($MAGISK_VER)"
else
    ui_print "- Root Manager: Unknown / Generic"
fi

ui_print "- Installing SkiaVK..."

# check for vulkan feature and vendor vulkan hal drivers
HAS_VULKAN_FEATURE=0
HAS_VULKAN_LIB=0

# 1. check pm if available (normal system boot)
if command -v pm >/dev/null 2>&1; then
    if pm list features 2>/dev/null | grep -q android.hardware.vulkan; then
        HAS_VULKAN_FEATURE=1
    fi
fi

# 2. check system property (works in system and some recovery environments)
VULKAN_PROP=$(getprop ro.hardware.vulkan 2>/dev/null | tr -d '\r')
if [ -n "$VULKAN_PROP" ]; then
    HAS_VULKAN_FEATURE=1
fi

# 3. search for vendor/system vulkan hal driver (.so files) - expanded paths
for libpath in \
    /vendor/lib64/hw/vulkan.*.so \
    /vendor/lib/hw/vulkan.*.so \
    /vendor/lib64/vulkan.*.so \
    /vendor/lib/vulkan.*.so \
    /vendor/lib64/libvulkan_*.so \
    /vendor/lib/libvulkan_*.so \
    /system/lib64/hw/vulkan.*.so \
    /system/lib/hw/vulkan.*.so \
    /system/lib64/libvulkan.so \
    /system/lib/libvulkan.so; do
    if [ -f "$libpath" ]; then
        HAS_VULKAN_LIB=1
        break
    fi
done

if [ "$HAS_VULKAN_FEATURE" -eq 0 ] && [ "$HAS_VULKAN_LIB" -eq 0 ]; then
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
