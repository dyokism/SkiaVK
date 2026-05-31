[English](README.md) | [Bahasa Indonesia](README.id.md)

# SkiaVK

**Memaksa rendering Skia Vulkan di Android dengan perlindungan bootloop otomatis.**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Android](https://img.shields.io/badge/Android-10.0%2B-green.svg)
![Version](https://img.shields.io/badge/Version-1.2-orange.svg)
![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red.svg)

## Deskripsi Umum

SkiaVK mengubah renderer bawaan HWUI dari OpenGL ke Vulkan untuk menghasilkan animasi antarmuka yang lebih lancar, rendah latensi, dan performa GPU yang lebih optimal pada perangkat yang kompatibel.

---

## Mengapa Menggunakan SkiaVK?

- **Animasi Antarmuka Super Halus**: Mengalihkan rendering UI ke Vulkan untuk mengurangi latensi dan meningkatkan efisiensi daya GPU.
- **Proteksi Bootloop Otomatis**: Menonaktifkan modul secara otomatis jika perangkat gagal booting 3 kali berturut-turut agar perangkat Anda tetap aman.
- **Reset Instan Sekali Ketuk**: Mengaktifkan kembali modul dan menyetel ulang penghitung bootloop dengan mudah lewat tombol **Action** di manajer KernelSU/APatch.

---

## Persyaratan Sistem

| Persyaratan | Detail |
|-------------|--------|
| Android | 10.0+ (API 29+) |
| Perangkat Keras | Perangkat dengan driver Vulkan yang mendukung akselerasi GPU |
| Root | Magisk, KernelSU, atau APatch |

---

## Fitur Teknis Utama & Keamanan

- **Proteksi Bootloop Otomatis (Sistem 3-Percobaan)**: Menonaktifkan modul secara mandiri setelah 3 kali gagal booting berturut-turut dan melaporkan statusnya secara dinamis di manajer root Anda.
- **Log Persisten Lokal**: Mencatat seluruh tahapan booting dan status kesalahan secara lokal di `/data/adb/skia_vulkan/skia_vulkan.log` untuk kebutuhan analisis luring (*offline debugging*).
- **Late-Boot Persistence**: Memantau dan menerapkan ulang konfigurasi secara aktif jika layanan vendor agresif (seperti override bawaan HWUI Samsung) mencoba mereset renderer setelah booting.
- **Pemeriksaan Multi-Jalur HAL**: Memindai direktori vendor standar, direktori sistem, dan lokasi ARM Mali BSP kustom untuk memastikan kompatibilitas maksimal.

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
