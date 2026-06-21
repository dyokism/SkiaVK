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
  <img src="https://img.shields.io/badge/Versi-2.3.2-0078d7?style=for-the-badge&logo=github&logoColor=white" alt="Versi">
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

## Instalasi & Konfigurasi Teknis

1. Unduh berkas `SkiaVK.zip` terbaru dari halaman [Releases](https://github.com/dyokism/SkiaVK/releases).
2. Pasang berkas ZIP melalui tab **Modules** di manager root Anda.
3. **Reboot** (Mulai ulang) perangkat Anda untuk mengaktifkan.

### Konfigurasi Teknis

SkiaVK beroperasi menggunakan injeksi properti. Status persisten modul dikelola dalam direktori `/data/adb/skia_vulkan/`.
- **Berkas Log**: `/data/adb/skia_vulkan/skia_vulkan.log` (ditimpa ulang secara otomatis setiap kali perangkat dinyalakan).
- **Status Booting**: `/data/adb/skia_vulkan/boot_state` (mencatat penghitung penjaga bootloop).

**Properti yang Diinjeksi (Awal Booting):**
- `debug.hwui.renderer=skiavk` (Bawaan)

#### RenderEngine Vulkan Backend (Opsional)
Anda juga dapat memaksa backend **SurfaceFlinger RenderEngine** untuk menggunakan Vulkan (`debug.renderengine.backend=skiavk`).

> [!WARNING]
> Backend RenderEngine Vulkan sangat eksperimental pada beberapa versi Android/ROM dan dapat menyebabkan glitch pada tampilan sistem atau layar berkedip. Gunakan dengan hati-hati.

* **Mengaktifkan RenderEngine**:
  ```bash
  su -c "touch /data/adb/skia_vulkan/enable_renderengine"
  ```
* **Menonaktifkan RenderEngine**:
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

## Pengembang, Kredit & Lisensi

- **Pengembang**: [dyokism](https://github.com/dyokism)
- **Lisensi**: [MIT](LICENSE)
- **Kredit & Apresiasi**:
  - **Vulkan API** oleh [The Khronos Group](https://www.vulkan.org/)
  - **Manajer Root**: [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), dan [APatch](https://github.com/bmax121/APatch)
  - **Samsung GPUWatch** sebagai alat bantu debugging performa grafis
