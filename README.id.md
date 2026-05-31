[English](README.md) | [Bahasa Indonesia](README.id.md)

# SkiaVK

**Memaksa rendering Skia Vulkan di Android dengan perlindungan bootloop otomatis.**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Android](https://img.shields.io/badge/Android-10.0%2B-green.svg)
![Version](https://img.shields.io/badge/Version-1.1-orange.svg)
![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red.svg)

## Deskripsi Umum

SkiaVK mengubah renderer bawaan HWUI dari OpenGL ke Vulkan untuk menghasilkan animasi antarmuka yang lebih lancar, rendah latensi, dan performa GPU yang lebih optimal pada perangkat yang kompatibel.

---

## Mengapa Menggunakan SkiaVK?

- **UI Lebih Lancar & Animasi Halus**: Mengalihkan rendering antarmuka ke Vulkan untuk performa yang lebih responsif.
- **Proteksi Bootloop Otomatis**: Jika perangkat gagal booting 3 kali berturut-turut, modul akan otomatis nonaktif secara aman.
- **Reset Manual untuk KernelSU/APatch**: Me-reset penghitung bootloop dan mengaktifkan kembali modul dengan sekali ketuk lewat tombol **Action** di manager.
- **Pemeriksaan Driver Ganda**: Memastikan perangkat mendukung Vulkan sebelum menerapkan perubahan guna menghindari kegagalan booting.
- **Konsistensi Rendering**: Memastikan konfigurasi tetap aktif meskipun ada layanan sistem lain yang mencoba mengubahnya kembali.

---

## Persyaratan Sistem

| Persyaratan | Detail |
|-------------|--------|
| Android | 10.0+ (API 29+) |
| Perangkat Keras | Perangkat dengan driver Vulkan yang mendukung akselerasi GPU |
| Root | Magisk, KernelSU, atau APatch |

---

## Cara Kerja

```mermaid
flowchart TD
    FlashZip([Mulai: Flash ZIP Modul]) --> CheckVulkan{Dukungan Vulkan?}
    CheckVulkan -- Tidak --> Abort[Abort: Instalasi Dibatalkan]
    CheckVulkan -- Ya --> Install[Selesaikan Instalasi]
    
    Install --> BootStart([Perangkat Reboot & Booting Dimulai])
    
    BootStart --> LoadState[Muat Status Proteksi]
    LoadState --> BootCheck{Gagal Booting >= 3?}
    
    BootCheck -- Ya --> TriggerSafety[Nonaktifkan Modul & Bypass Aman]
    BootCheck -- Tidak --> ApplySkia[Set debug.hwui.renderer = skiavk]
    
    ApplySkia --> WaitBoot[Tunggu Sistem Selesai Memuat]
    WaitBoot --> BootSuccess[Booting Selesai dengan Sukses]
    BootSuccess --> ResetState[Reset Penghitung Proteksi ke 0]
    ResetState --> Finished([Selesai: Berjalan Stabil])

    %% Kustomisasi Tampilan dan Warna (Tema Gelap Ultra-Redup)
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

## Pengembang & Lisensi

- **Pengembang**: [dyokism](https://github.com/dyokism)
- **Lisensi**: MIT
