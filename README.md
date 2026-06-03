[English](README.md) | [Bahasa Indonesia](README.id.md)

# SkiaVK

**Forces Skia Vulkan rendering on Android with built-in atomic bootloop protection.**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Android](https://img.shields.io/badge/Android-10.0%2B-green.svg)
![Version](https://img.shields.io/badge/Version-1.3-orange.svg)
![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red.svg)

## Overview

SkiaVK changes the default HWUI renderer from OpenGL to Vulkan. This provides smoother UI rendering, reduced animation latency, and better GPU hardware utilization on compatible devices.

---

## Why Use SkiaVK?

- **Butter-Smooth UI**: Forces Vulkan rendering for faster animations and less GPU lag.
- **Fail-Safe Bootloop Guard**: Automatically disables the module after 3 failed boot attempts using safe, atomic file updates.
- **Easy Recovery**: Re-enable the module and reset the safety counter with a single tap of the **Action** button in KernelSU/APatch.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Android | 10.0+ (API 29+) |
| Hardware | Device with Vulkan driver and hardware support |
| Root | Magisk, KernelSU, or APatch |

---

## Installation & Configuration

1. Install the ZIP file via your root manager's **Modules** tab.
2. **Reboot** your device to activate.
3. Check logs at: `/data/adb/skia_vulkan/skia_vulkan.log`

---

## File Structure

```text
SkiaVK/
├── META-INF/
│   └── com/
│       └── google/
│           └── android/
│               ├── update-binary
│               └── updater-script
├── action.sh        # resets bootloop counter (KSU/APatch Action)
├── customize.sh     # install-time compatibility checks & Vulkan check
├── module.prop      # module metadata properties
├── post-fs-data.sh  # early boot property injection & bootloop guard
├── service.sh       # late boot completion watchdog & override recovery
├── uninstall.sh     # clean up persistent data on uninstall
└── util.sh          # shared helper functions & variables
```

---

## How It Works

```mermaid
flowchart TD
    FlashZip([Start: Flash ZIP Module]) --> CheckVulkan{Vulkan Supported?}
    CheckVulkan -- No --> Abort[Abort: Installation Terminated]
    CheckVulkan -- Yes --> Install[Complete Installation]
    
    Install --> BootStart([Device Reboots & Early Boot])
    
    BootStart --> LoadState[Load Boot Counter / State]
    LoadState --> BootCheck{Failed Boots >= 3?}
    
    BootCheck -- Yes --> TriggerSafety[Disable Module & Safe Bypass]
    BootCheck -- No --> ApplySkia[Set debug.hwui.renderer = skiavk]
    
    ApplySkia --> WaitBoot[Wait for System Boot Completion]
    WaitBoot --> BootSuccess[Boot Completed Successfully]
    BootSuccess --> ResetState[Reset Guard Counter to 0]
    ResetState --> Finished([Finished: Running Smoothly])

    %% Custom Styles and Colors (Ultra-Muted Slate Theme)
    classDef startEnd fill:#1b2c24,stroke:#34d399,stroke-width:1.5px,color:#e6f4ea;
    classDef fail fill:#2c1b1b,stroke:#f87171,stroke-width:1.5px,color:#fce8e6;
    classDef decision fill:#2d2216,stroke:#fbbf24,stroke-width:1.5px,color:#fef3c7;
    classDef process fill:#1e293b,stroke:#475569,stroke-width:1px,color:#f1f5f9;
    
    class FlashZip,Finished startEnd;
    class TriggerSafety,Abort fail;
    class CheckVulkan,BootCheck decision;
    class Install,BootStart,LoadState,ApplySkia,WaitBoot,BootSuccess,ResetState process;
```

---

## Developer & License

- **Developer**: [dyokism](https://github.com/dyokism)
- **License**: MIT
