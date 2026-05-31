[English](README.md) | [Bahasa Indonesia](README.id.md)

# SkiaVK

**Forces Skia Vulkan rendering on Android with built-in bootloop protection.**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Android](https://img.shields.io/badge/Android-10.0%2B-green.svg)
![Version](https://img.shields.io/badge/Version-1.1-orange.svg)
![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red.svg)

## Overview

SkiaVK changes the default HWUI renderer from OpenGL to Vulkan. This provides smoother UI rendering, less latency, and better GPU performance on compatible devices.

---

## Why Use SkiaVK?

- **Faster UI & Smooth Animations**: Offloads UI rendering to Vulkan for a buttery-smooth experience.
- **Smart Bootloop Protection**: If your device fails to boot 3 times, the module automatically disables itself.
- **Manual Reset for KernelSU/APatch**: Easily reset the bootloop counter and re-enable the module with a single tap via the manager's **Action** button.
- **Dual Hardware Check**: Scans device feature lists and driver files before applying changes to prevent bootloops on unsupported devices.
- **Late-Boot Persistence**: Ensures the renderer stays set to Vulkan even if overridden by other system services.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Android | 10.0+ (API 29+) |
| Hardware | Device with Vulkan driver and hardware support |
| Root | Magisk, KernelSU, or APatch |

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

    %% Custom Styles (Ultra-Muted Slate Theme)
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
