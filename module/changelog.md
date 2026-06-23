# SkiaVK Changelog

## v2.3.2
- **Ruthless Refactor**: Completely refactored module scripts to remove noise comments and improve readability.
- **Improved Logging**: Centralized logging logic within `util.sh` for cleaner code and a smaller footprint.
- **UI Freeze Fix**: Wrapped file I/O operations into a detached subshell inside `action.sh` to prevent KernelSU/APatch UI freezes.

hi lol