# SkiaVK Changelog

## v2.3.1
- **Subshell and Process Optimizations**: Replaced `tr -d '\r'` pipeline forks in `customize.sh`, `post-fs-data.sh`, and `service.sh` with fast POSIX parameter expansion to reduce early-boot CPU overhead.
- **Robust Recovery Compatibility**: Added `API="${API:-0}"` fallback guard in `customize.sh` to prevent shell evaluation crashes in custom recoveries (like TWRP or OrangeFox) where `$API` might be empty.
- **Double Fork Elimination**: Refactored the late-boot polling check in `service.sh` to query `getprop` directly and verify `sys.boot_completed` without forking process groups.
- **Installer Safety Comments**: Added safety clarifications to `update-binary` confirming that `exit` calls are safe because the script is executed as a standalone binary process.
- **Metadata Fixes**: Added a trailing newline to `module.prop` to ensure proper parsing in BusyBox environments.

## v2.3
- **RenderEngine Opt-in Feature**: Added dynamic opt-in support for SurfaceFlinger RenderEngine Vulkan backend, controllable via the presence of `/data/adb/skia_vulkan/enable_renderengine`.
- **Bootloop Guard Recovery Fix**: Resolved a critical UX trap where manual module activation in manager apps did not reset the guard, resulting in immediate re-disabling on the next boot cycle.
- **Robustness and ShellCheck Cleanliness**: Removed all global `set -e` blocks from boot scripts, replaced unstable command-substitution strings, refactored `update_description` to prevent SC2015 warnings, and added defensive guards for the Android `$API` variable.

## v2.2
- **Airtight Deadlock and Stability Refactor**: Enforced `resetprop -n` for late-boot injections to prevent socket deadlocks, and hardened Vulkan screening to filter out and block software Vulkan renderers (like SwiftShader/Lavapipe) preventing bootloops.
- **POSIX & Subshell Optimizations**: Re-implemented state file parsing via a pure POSIX `while read` loop, optimized uptime parsing using native `read` rather than forking `cut`, and replaced subshell command groupings with curly brace blocks `{ ... }` to minimize early-boot process forks.
- **SELinux Resiliency**: Added stderr redirection to `/dev/null` for all `/dev/kmsg` logging calls to prevent permission denials and noise in custom domains.

## v2.1
- **Crucial Boot Completed Watchdog Fix**: Fixed a bug where `resetprop -w` waited for `sys.boot_completed` to be `0` instead of `1`.
- **Fast Devices Deadlock Fix**: Replaced the buggy `resetprop -w` wait with a highly robust polling loop to prevent bootloop guard deadlocks due to SELinux/socket constraints in custom root domains.
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
