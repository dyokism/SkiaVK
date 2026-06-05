# SkiaVK Changelog

## v2.0
- **Crucial Boot Completed Watchdog Fix**: Fixed a bug where `resetprop -w` waited for `sys.boot_completed` to be `0` instead of `1`.
- **Accurate Vulkan Detection**: Removed core system Vulkan loader checks in `customize.sh` to prevent false-positives and ensure actual hardware driver presence.
- **Improved Filesystem Robustness**: Added copy fallback to `update_description` in `util.sh` when moving files on overlayfs filesystems.
- **Robust Watchdog Handling**: Avoid disarming the bootloop guard if the boot wait ends prematurely due to timeout or being killed.
- **Visuals and Descriptions**: Polished active/fail status descriptions to be more clear and casual, and updated banner artwork.

## v1.5
- **Airtight KSU & APatch Compatibility**: Switched property injection to `resetprop -n` in `post-fs-data.sh` to prevent `init` deadlocks, and replaced all sourced `exit` calls with clean function returns.
- **Robust Boot completed Watchdog**: Replaced getprop poll loop with efficient `resetprop -w` and implemented a parallel 480-second watchdog fallback.
- **Strict Error Handling**: Added `set -eu` and trap handlers to log failures to `/dev/kmsg` and persistent logs.
- **Layout & Metadata Cleanup**: Relocated core module files to a dedicated `module/` subdirectory and removed non-standard `module.prop` fields.

## v1.4
- **Clean Vulkan Detection**: Removed EGL/OpenGL ES library (`libGLES_mali.so`) from customize.sh Vulkan check to prevent false-positives on older Mali GPUs.
- **Improved Logging & Robustness**: Dynamically log timeout durations and log manual counter reset actions.
- **Robust Filesystem Handling**: Add fallback logging when updating properties on OverlayFS filesystems, and clean up redundant directory checks.

## v1.3
- **Atomic State & Safeguards**: Switched to atomic state writes to prevent file corruption, and corrected the first-boot counter to start at `0/3`.
- **Improved Root & Recovery Compatibility**: Expanded Vulkan checks during TWRP/recovery installs, and added dynamic `resetprop` path resolution for Magisk, KernelSU, and APatch.
- **Code Refactor & Logging**: Cleaned up codebase by centralizing functions into a shared utility script (`util.sh`), and added proper syslog priority prefixes to `/dev/kmsg` outputs.

## v1.2
- **Boot Timeout Margin**: Increased boot completion wait timeout from 300s to 480s to prevent false-positives on slower devices.
- **Robust Guarding**: Prevented late-boot `service.sh` from writing state resets if the module has already been disabled by the bootloop guard.
- **Expanded Compatibility**: Added support for non-standard layout Vulkan HAL drivers (Mali-specific and system-level fallback paths).
- **Persistent Logging**: Implemented local storage boot log (`/data/adb/skia_vulkan/skia_vulkan.log`) refreshed per boot cycle for reliable debugging.

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
