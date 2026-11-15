# Aplikasi Flutter SIMS Scitech

Client **SIMS — Sistem Inventory Management Scitech** untuk inventaris dan peminjaman internal. Entry point `lib/main.dart` membuka aplikasi produksi di `lib/production/`; data dan otorisasi berasal dari API Next.js, bukan database langsung dari Flutter.

Lihat [overview, screenshot terbaru, tech stack, dan app flow](../README.md), [spesifikasi desain](../DESIGN.md), serta [riwayat perubahan dan batas verifikasi](docs/ui-redesign.md).

## Menjalankan aplikasi

Jalankan backend dari root repository dengan konfigurasi `.env.local` sesuai `.env.example`:

```sh
npm ci
npm run dev
```

Kemudian dari `app_inventory`:

```sh
flutter pub get
flutter run -d chrome --web-port=5173 --no-web-resources-cdn
```

Web lokal memakai API port 3000. Web rilis memakai origin yang sama; override dengan `--dart-define=API_URL=...`. Build native rilis memerlukan URL API HTTPS yang dapat dijangkau perangkat:

```sh
flutter build apk --release --dart-define=API_URL=https://YOUR-API-DOMAIN
```

Untuk web di `/app/`:

```sh
flutter build web --release --base-href=/app/ --no-web-resources-cdn
```

Bundling dan distribusi APK dijelaskan di [README utama](../README.md). CanvasKit dibundel lokal; Poppins dan Roboto Mono juga tersedia sebagai aset lokal.

## Struktur aplikasi

| Lokasi | Tanggung jawab |
|---|---|
| `lib/core/` | API client, state sesi/data, token vault, preferensi tampilan, pembaruan aplikasi |
| `lib/models.dart` | Model profil, barang, pinjaman, dan data workspace |
| `lib/production/auth/` | Masuk email/sandi, pendaftaran + OTP, pemulihan sandi |
| `lib/production/home/` | Beranda peminjam, hero stok/pinjaman, peti kategori interaktif |
| `lib/production/catalog/` | Daftar barang, detail, status stok, aktivitas rekan |
| `lib/production/request/` | Jumlah, jadwal, keperluan, ringkasan pengajuan |
| `lib/production/workspace/` | Navigasi per peran, persetujuan, serah terima, pengembalian, barang, pengadaan, pengguna, akun |
| `lib/production/stats/` | Statistik dan grafik custom dari data workspace |
| `lib/ui/` | Tema, palet, komponen, bentuk, pegas, motion, dan penanganan keyboard Android |
| `assets/brand/` | Logo Kit Case, varian lockup, dan panduan merek |
| `test/` | Regresi alur pengguna, input, media, tema/gerak, dan pembaruan |

## UI terkini: Material 3 Expressive

- **Identitas:** logo SIMS Kit Case; Navy Scitech `#0F2C59`, kanvas slate `#F5F7FB`, kontainer biru langit. Tujuh palet: Navy Scitech, Kobalt, Zamrud, Koral, Amber, Violet, Magenta.
- **Tipografi:** Poppins 400–800; Roboto Mono untuk kode/ID. ID pendek berasal dari record, bukan kode inventaris buatan.
- **Navigasi:** peminjam memakai Beranda · Katalog · Pinjaman · Akun; admin memakai Ringkasan · Barang · Pinjaman · Lainnya. Lebar ≥900 px beralih ke rail.
- **Auth:** masuk hanya email dan sandi. OTP enam digit untuk verifikasi daftar dan pemulihan sandi, bukan pilihan login. Hero interaktif menyesuaikan langkah; isian tonal, tombol tampil sibuk saat request berjalan.
- **Komponen:** `HeroCard`, `GroupCard`, `LinkGroup`/`LinkTile`, `StatusPill`, `ExpressiveTextField`, `ExpressiveSearchBar`, `ExpressiveFilterChip`, `ExpressiveButtonGroup`, dan `ExpressiveNavBar`.
- **Interaksi:** tombol morph dan memantul, feedback haptic, transisi tab, reveal judul, indikator bergelombang, ilustrasi kategori, serta semburan bentuk setelah aksi berhasil.
- **Preferensi lokal:** mode sistem/terang/gelap, palet, kontras, ukuran teks, kurangi gerak, pesan WhatsApp, dan foto/avatar per akun disimpan lewat `shared_preferences`. Token sesi memakai `flutter_secure_storage`. Warna dinamis bergantung dukungan Android 12+.

### Gerak dan aksesibilitas

`lib/ui/springs.dart` menyediakan pegas spasial untuk perpindahan/ukuran/bentuk dan pegas efek untuk warna/opasitas. `MorphBorder` menangani perubahan bentuk tombol; `PressSpring` menangani respons tekan. Preferensi **Kurangi gerak** mematikan gerak spasial tanpa mematikan aksi.

Target sentuh minimum 48 dp; status dilengkapi teks/ikon, bukan hanya warna. Form menggulir saat keyboard muncul. Android <30 memakai inset IME native saat metrik Flutter nol; metrik tidak dijumlahkan. Klaim ini bukan hasil audit aksesibilitas menyeluruh.

## Pemeriksaan

```sh
flutter test
flutter analyze --no-pub
```

`flutter test` pada 2026-11-15: **42 tes lulus**. Detail verifikasi native dan keterbatasan perangkat ada di [catatan UI](docs/ui-redesign.md). Hasil tersebut tidak membuktikan layanan produksi, pengiriman email nyata, kamera fisik, atau instalasi APK rilis sudah diuji.
