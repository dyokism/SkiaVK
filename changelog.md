# SkiaVK Changelog

## v1.2
- **Boot Timeout Margin**: Increased boot completion wait timeout from 300s to 480s to prevent false-positives on slower devices.
- **Robust Guarding**: Prevented late-boot `service.sh` from writing state resets if the module has already been disabled by the bootloop guard.
- **Expanded Compatibility**: Added support for non-standard layout Vulkan HAL drivers (Mali-specific and system-level fallback paths).
- **Persistent Logging**: Implemented local storage boot log (`/data/adb/skia_vulkan/skia_vulkan.log`) with automatic rotation for reliable debugging.

## v1.1
- **Fix Update Button**: Added changelog support for Magisk updater.
- **Optimization**: Removed redundant Vulkan hardware driver verification on early boot (now checked solely at installation time).
- **Improved service.sh**: Updated description state to conditionally match verification outcomes dynamically.
- **Minor Fixes**: Fixed general scripting and documentation styling consistency.

## v1.0
- Initial release.
- Added force Skia Vulkan renderer config.
- Implemented smart bootloop protection (3-strike disable).
- Added manual reset action via KernelSU/APatch manager interface.
