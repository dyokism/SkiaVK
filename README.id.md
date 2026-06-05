# SkiaVK

<p align="center">
  <img src="vulkan.webp" alt="Vulkan Logo" width="600">
</p>

<p align="center">
  <strong>Memaksa rendering Skia Vulkan di Android dengan perlindungan bootloop otomatis berbasis atomic.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Lisensi-MIT-708090?style=for-the-badge" alt="Lisensi">
  <img src="https://img.shields.io/badge/Android-10.0%2B-78c257?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Versi-2.1-0078d7?style=for-the-badge&logo=github&logoColor=white" alt="Versi">
  <img src="https://img.shields.io/badge/Root-KSU%20%7C%20APatch%20%7C%20Magisk-e52b20?style=for-the-badge&logo=linux&logoColor=white" alt="Root">
  <br>
  <br>
  <a href="README.md">English</a> | <a href="README.id.md">Bahasa Indonesia</a>
</p>

## Deskripsi Umum

SkiaVK mengubah renderer bawaan HWUI dari OpenGL ke Vulkan untuk menghasilkan animasi antarmuka yang lebih lancar, rendah latensi, dan optimalisasi penggunaan akselerasi hardware GPU pada perangkat yang kompatibel.

---

## Mengapa Memilih SkiaVK?

- **UI Jauh Lebih Mulus**: Memaksa penggunaan Vulkan untuk animasi yang lebih cepat dan mengurangi lag pada GPU.
- **Proteksi Bootloop Aman**: Mematikan modul secara otomatis jika gagal booting 3 kali berturut-turut dengan sistem tulis berkas yang aman (atomic).
- **Pemulihan Sekali Ketuk**: Aktifkan kembali modul dan reset penghitung bootloop cukup dengan menekan tombol **Action** di manajer KernelSU/APatch.

---

## Bukti Uji Coba

Telah diuji dan diverifikasi pada **Samsung Galaxy S23 (Snapdragon 8 Gen 2)** dengan KernelSU-Next. Berikut adalah tangkapan layar **GPUWatch** yang menampilkan pipa rendering Vulkan (`skiavk`) aktif beserta status modul yang terpasang:

<p align="center">
  <img src="s23_verify.webp" alt="Verifikasi GPUWatch Samsung S23" width="500">
</p>

---

## Persyaratan Sistem

| Persyaratan | Detail |
|-------------|--------|
| Android | 10.0+ (API 29+) |
| Perangkat Keras | Perangkat dengan driver Vulkan yang mendukung akselerasi GPU |
| Root | Magisk, KernelSU, atau APatch |

---

## Instalasi & Konfigurasi

1. Unduh berkas `SkiaVK.zip` terbaru dari halaman [Releases](https://github.com/dyokism/SkiaVK/releases).
2. Pasang berkas ZIP melalui tab **Modules** di manager root Anda.
3. **Reboot** (Mulai ulang) perangkat Anda untuk mengaktifkan.
4. Periksa berkas log di: `/data/adb/skia_vulkan/skia_vulkan.log`

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

## Pengembang, Kredit & Lisensi

- **Pengembang**: [dyokism](https://github.com/dyokism)
- **Lisensi**: [MIT](LICENSE)
- **Kredit & Apresiasi**:
  - **Vulkan API** oleh [The Khronos Group](https://www.vulkan.org/)
  - **Manajer Root**: [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), dan [APatch](https://github.com/bmax121/APatch)
  - **Samsung GPUWatch** sebagai alat bantu debugging performa grafis
