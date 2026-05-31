# SkiaVK Changelog

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
