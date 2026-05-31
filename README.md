[English](README.md) | [Bahasa Indonesia](README.id.md)

# SkiaVK

**Forces Skia Vulkan rendering on Android with built-in bootloop protection.**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Android](https://img.shields.io/badge/Android-10.0%2B-green.svg)
![Version](https://img.shields.io/badge/Version-1.2-orange.svg)
![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red.svg)

## Overview

SkiaVK changes the default HWUI renderer from OpenGL to Vulkan. This provides smoother UI rendering, less latency, and better GPU performance on compatible devices.

---

## Why Use SkiaVK?

- **Butter-Smooth UI & Animations**: Offloads UI rendering to Vulkan for reduced latency and better GPU efficiency.
- **Built-in Bootloop Guard**: Automatically disables the module after 3 failed boot attempts to keep your device completely safe.
- **One-Tap Counter Reset**: Easily re-enable the module and reset the safety counter with the KernelSU/APatch manager **Action** button.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Android | 10.0+ (API 29+) |
| Hardware | Device with Vulkan driver and hardware support |
| Root | Magisk, KernelSU, or APatch |

---

## Advanced Technical Features

- **Automated Bootloop Guard (3-Strike System)**: Auto-disables the module after 3 consecutive failed boots and reports status dynamically in your root manager.
- **Persistent Local Logging**: Records all boot milestones and error states at `/data/adb/skia_vulkan/skia_vulkan.log` for quick, offline debugging.
- **Smart Late-Boot Re-Apply**: Actively monitors and enforces the SkiaVK renderer even if aggressive vendor services (e.g. Samsung HWUI overrides) try to reset it.
- **Multi-Path HAL Detection**: Scans standard vendor libraries, system directories, and custom ARM Mali BSP locations for maximum compatibility.

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
