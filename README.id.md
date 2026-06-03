[English](README.md) | [Bahasa Indonesia](README.id.md)

# SkiaVK

**Memaksa rendering Skia Vulkan di Android dengan perlindungan bootloop otomatis berbasis atomic.**

![Lisensi](https://img.shields.io/badge/Lisensi-MIT-blue.svg)
![Android](https://img.shields.io/badge/Android-10.0%2B-green.svg)
![Versi](https://img.shields.io/badge/Versi-1.4-orange.svg)
![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red.svg)

## Deskripsi Umum

SkiaVK mengubah renderer bawaan HWUI dari OpenGL ke Vulkan untuk menghasilkan animasi antarmuka yang lebih lancar, rendah latensi, dan optimalisasi penggunaan akselerasi hardware GPU pada perangkat yang kompatibel.

---

## Mengapa Memilih SkiaVK?

- **UI Jauh Lebih Mulus**: Memaksa penggunaan Vulkan untuk animasi yang lebih cepat dan mengurangi lag pada GPU.
- **Proteksi Bootloop Aman**: Mematikan modul secara otomatis jika gagal booting 3 kali berturut-turut dengan sistem tulis berkas yang aman (atomic).
- **Pemulihan Sekali Ketuk**: Aktifkan kembali modul dan reset penghitung bootloop cukup dengan menekan tombol **Action** di manajer KernelSU/APatch.

---

## Persyaratan Sistem

| Persyaratan | Detail |
|-------------|--------|
| Android | 10.0+ (API 29+) |
| Perangkat Keras | Perangkat dengan driver Vulkan yang mendukung akselerasi GPU |
| Root | Magisk, KernelSU, atau APatch |

---

## Instalasi & Konfigurasi

1. Pasang berkas ZIP melalui tab **Modules** di manager root Anda.
2. **Reboot** (Mulai ulang) perangkat Anda untuk mengaktifkan.
3. Periksa berkas log di: `/data/adb/skia_vulkan/skia_vulkan.log`

---

## Struktur Berkas

```text
SkiaVK/
├── META-INF/
│   └── com/
│       └── google/
│           └── android/
│               ├── update-binary
│               └── updater-script
├── action.sh        # mengatur ulang penghitung bootloop (KSU/APatch Action)
├── customize.sh     # pemeriksaan kompatibilitas & Vulkan driver saat instalasi
├── module.prop      # metadata modul
├── post-fs-data.sh  # injeksi properti awal booting & proteksi bootloop
├── service.sh       # late-boot watchdog & pengembalian renderer jika diubah vendor
├── uninstall.sh     # menghapus berkas sisa saat modul dihapus
└── util.sh          # fungsi utilitas dan variabel bersama
```

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
