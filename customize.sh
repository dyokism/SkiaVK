#!/system/bin/sh
# skia_vulkan - customize.sh
# clean, brief installation log with real vulkan hal checks

ui_print "- Installing SkiaVK..."

# check for vulkan feature and vendor vulkan hal drivers
HAS_VULKAN_FEATURE=0
HAS_VULKAN_LIB=0

if pm list features 2>/dev/null | grep -q android.hardware.vulkan; then
    HAS_VULKAN_FEATURE=1
fi

# search for vendor vulkan hal driver (.so files)
for libpath in /vendor/lib64/hw/vulkan.*.so /vendor/lib/hw/vulkan.*.so; do
    if [ -f "$libpath" ]; then
        HAS_VULKAN_LIB=1
        break
    fi
done

if [ "$HAS_VULKAN_FEATURE" -eq 0 ] && [ "$HAS_VULKAN_LIB" -eq 0 ]; then
    ui_print " "
    ui_print "[!] Warning:"
    ui_print "  Vulkan hardware driver was not detected on your device."
    ui_print "  Installation will proceed, but the bootloop guard"
    ui_print "  will automatically bypass rendering to keep you safe."
    ui_print " "
else
    ui_print "- Vulkan hardware driver detected."
fi

ui_print "- Bootloop guard configured."
ui_print "- Installation complete! Please reboot."
