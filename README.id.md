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
  <img src="https://img.shields.io/badge/Versi-2.3-0078d7?style=for-the-badge&logo=github&logoColor=white" alt="Versi">
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
- **Pemulihan Sekali Ketuk**: Aktifkan kembali modul dan reset penghitung bootloop cukup dengan menekan tombol **Action** di manajer root Anda.
- **Proteksi Vulkan Software**: Membatalkan instalasi secara otomatis pada emulator, mesin virtual, atau perangkat yang menggunakan renderer Vulkan berbasis software (seperti SwiftShader, Lavapipe) untuk menghindari kemacetan pada tampilan sistem.

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

### RenderEngine Vulkan Backend (Pilihan / Opt-in)

Secara bawaan, SkiaVK memaksa pipa rendering HWUI untuk menggunakan Vulkan (`skiavk`). Anda juga dapat memaksa backend **SurfaceFlinger RenderEngine** untuk menggunakan Vulkan secara opsional.

> [!WARNING]
> Backend RenderEngine Vulkan sangat eksperimental pada beberapa versi Android/ROM dan dapat menyebabkan glitch pada tampilan sistem atau layar berkedip. Gunakan dengan hati-hati.

* **Untuk Mengaktifkan**: Buat berkas kosong bernama `enable_renderengine` di direktori persistent modul:
  ```bash
  su -c "touch /data/adb/skia_vulkan/enable_renderengine"
  ```
* **Untuk Menonaktifkan**: Hapus berkas tersebut dan mulai ulang perangkat:
  ```bash
  su -c "rm -f /data/adb/skia_vulkan/enable_renderengine"
  ```
  *(Mulai ulang perangkat diperlukan untuk menerapkan perubahan RenderEngine)*

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
    Flash([Flash ZIP]) --> Customize[customize.sh: Cek API 29+ / Vulkan HW / Tolak SW]
    Customize --> Reboot([Reboot])

    Reboot --> postFsData[post-fs-data.sh: boot awal]
    
    postFsData --> ReadState[Baca boot_state: counter + completed flag]
    ReadState --> PrevBoot{Boot sebelumnya sukses?}
    PrevBoot -- Ya (flag=1) --> ResetCounter[Counter = 0]
    PrevBoot -- Tidak (flag=0) --> IncCounter[Counter += 1]
    
    ResetCounter --> CheckThresh{Cek: counter >= 3?}
    IncCounter --> CheckThresh
    
    CheckThresh -- Ya --> Disable[touch disable + reset state]
    CheckThresh -- Tidak --> SetProp[resetprop -n debug.hwui.renderer = skiavk]
    
    SetProp --> OptRE{Berkas RenderEngine ada?}
    OptRE -- Ya --> SetRE[resetprop -n debug.renderengine.backend = skiavk]
    OptRE -- Tidak --> VerifyProp[Verifikasi properti terpasang]
    SetRE --> VerifyProp
    
    VerifyProp --> postFsDone([Selesai: properti boot awal])

    Reboot --> Service[service.sh: boot akhir]

    Service --> Wait[Tunggu sys.boot_completed hingga 480s]
    Wait --> Override{debug.hwui.renderer == skiavk?}
    Override -- Tidak --> ReApply[Terapkan ulang skiavk]
    Override -- Ya --> CheckRE{RenderEngine dipilih?}
    ReApply --> CheckRE
    CheckRE -- Ya --> VerifyRE[Verifikasi renderengine = skiavk]
    CheckRE -- Tidak --> Disarm[write_state 0 1: nonaktifkan guard]
    VerifyRE --> Disarm
    Disarm --> ServiceDone([Selesai: guard bootloop dinonaktifkan])

    Reboot --> Action[Pengguna tekan Tombol Aksi]
    Action --> ResetAll[write_state 0 1 + rm disable]
    ResetAll --> ActionDone([Selesai: aktifkan ulang, reboot diperlukan])

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

## Pengembang, Kredit & Lisensi

- **Pengembang**: [dyokism](https://github.com/dyokism)
- **Lisensi**: [MIT](LICENSE)
- **Kredit & Apresiasi**:
  - **Vulkan API** oleh [The Khronos Group](https://www.vulkan.org/)
  - **Manajer Root**: [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), dan [APatch](https://github.com/bmax121/APatch)
  - **Samsung GPUWatch** sebagai alat bantu debugging performa grafis
