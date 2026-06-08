# SkiaVK

<p align="center">
  <img src="vulkan.webp" alt="Vulkan Logo" width="600">
</p>

<p align="center">
  <strong>Forces Skia Vulkan rendering on Android with built-in atomic bootloop protection.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-708090?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Android-10.0%2B-78c257?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Version-2.3-0078d7?style=for-the-badge&logo=github&logoColor=white" alt="Version">
  <img src="https://img.shields.io/badge/Root-KSU%20%7C%20APatch%20%7C%20Magisk-e52b20?style=for-the-badge&logo=linux&logoColor=white" alt="Root">
  <br>
  <br>
  <a href="README.md">English</a> | <a href="README.id.md">Bahasa Indonesia</a>
</p>

## Overview

SkiaVK changes the default HWUI renderer from OpenGL to Vulkan. This provides smoother UI rendering, reduced animation latency, and better GPU hardware utilization on compatible devices.

---

## Why Use SkiaVK?

- **Butter-Smooth UI**: Forces Vulkan rendering for faster animations and less GPU lag.
- **Fail-Safe Bootloop Guard**: Automatically disables the module after 3 failed boot attempts using safe, atomic file updates.
- **Easy Recovery**: Re-enable the module and reset the safety counter with a single tap of the **Action** button in your root manager.
- **Software Vulkan Protection**: Automatically aborts installation on emulators, virtual machines, or devices running software Vulkan renderers (e.g. SwiftShader, Lavapipe) to prevent GUI freezes.

---

## Verification

Verified and tested on **Samsung Galaxy S23 (Snapdragon 8 Gen 2)** running KernelSU-Next. Below is the GPUWatch overlay showing the active Vulkan (`skiavk`) rendering pipeline and module status:

<p align="center">
  <img src="s23_verify.webp" alt="Samsung S23 GPUWatch Verification" width="500">
</p>

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Android | 10.0+ (API 29+) |
| Hardware | Device with Vulkan driver and hardware support |
| Root | Magisk, KernelSU, or APatch |

---

## Installation & Configuration

1. Download the latest `SkiaVK.zip` from [Releases](https://github.com/dyokism/SkiaVK/releases).
2. Install the ZIP file via your root manager's **Modules** tab.
3. **Reboot** your device to activate.
4. Check logs at: `/data/adb/skia_vulkan/skia_vulkan.log`

### RenderEngine Vulkan Backend (Opt-in)

By default, SkiaVK forces the HWUI rendering pipeline to Vulkan (`skiavk`). You can optionally force the **SurfaceFlinger RenderEngine** backend to also use Vulkan. 

> [!WARNING]
> RenderEngine Vulkan backend is highly experimental on some Android versions/ROMs and might cause UI glitches or screen flickering. Use with caution.

* **To Enable**: Create an empty file named `enable_renderengine` in the persistent module directory:
  ```bash
  su -c "touch /data/adb/skia_vulkan/enable_renderengine"
  ```
* **To Disable**: Delete the file and reboot:
  ```bash
  su -c "rm -f /data/adb/skia_vulkan/enable_renderengine"
  ```
  *(A device reboot is required to apply the RenderEngine changes)*

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
    Flash([Flash ZIP]) --> Customize[customize.sh: API 29+ / Vulkan HW / SW reject]
    Customize --> Reboot([Reboot])

    Reboot --> postFsData[post-fs-data.sh: early boot]
    
    postFsData --> ReadState[Read boot_state: counter + completed flag]
    ReadState --> PrevBoot{Previous boot completed?}
    PrevBoot -- Yes (flag=1) --> ResetCounter[Counter = 0]
    PrevBoot -- No (flag=0) --> IncCounter[Counter += 1]
    
    ResetCounter --> CheckThresh{Check: counter >= 3?}
    IncCounter --> CheckThresh
    
    CheckThresh -- Yes --> Disable[touch disable + reset state]
    CheckThresh -- No --> SetProp[resetprop -n debug.hwui.renderer = skiavk]
    
    SetProp --> OptRE{RenderEngine file exists?}
    OptRE -- Yes --> SetRE[resetprop -n debug.renderengine.backend = skiavk]
    OptRE -- No --> VerifyProp[Verify property applied]
    SetRE --> VerifyProp
    
    VerifyProp --> postFsDone([Done: early boot props set])

    Reboot --> Service[service.sh: late boot]

    Service --> Wait[Poll sys.boot_completed up to 480s]
    Wait --> Override{debug.hwui.renderer == skiavk?}
    Override -- No --> ReApply[re-apply skiavk override]
    Override -- Yes --> CheckRE{RenderEngine opt-in?}
    ReApply --> CheckRE
    CheckRE -- Yes --> VerifyRE[Verify renderengine = skiavk]
    CheckRE -- No --> Disarm[write_state 0 1: disarm guard]
    VerifyRE --> Disarm
    Disarm --> ServiceDone([Done: bootloop guard disarmed])

    Reboot --> Action[User taps Action Button]
    Action --> ResetAll[write_state 0 1 + rm disable]
    ResetAll --> ActionDone([Done: re-enable module, reboot required])

    classDef startEnd fill:#1b2c24,stroke:#34d399,stroke-width:1.5px,color:#e6f4ea;
    classDef fail fill:#2c1b1b,stroke:#f87171,stroke-width:1.5px,color:#fce8e6;
    classDef decision fill:#2d2216,stroke:#fbbf24,stroke-width:1.5px,color:#fef3c7;
    classDef process fill:#1e293b,stroke:#475569,stroke-width:1px,color:#f1f5f9;
    
    class Flash,Reboot,postFsDone,ServiceDone,ActionDone startEnd;
    class Disable fail;
    class PrevBoot,CheckThresh,OptRE,Override,CheckRE decision;
    class Customize,postFsData,ReadState,ResetCounter,IncCounter,SetProp,SetRE,VerifyProp,Service,Wait,ReApply,VerifyRE,Disarm,Action,ResetAll process;
```

---

## Developer, Credits & License

- **Developer**: [dyokism](https://github.com/dyokism)
- **License**: [MIT](LICENSE)
- **Credits & Acknowledgements**:
  - **Vulkan API** by [The Khronos Group](https://www.vulkan.org/)
  - **Root Managers**: [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), and [APatch](https://github.com/bmax121/APatch)
  - **Samsung GPUWatch** for performance debugging tools
