# Aplikasi Flutter SIMS Scitech

`lib/main.dart` menjalankan aplikasi di `lib/production/`. Katalog, transaksi, akun, dan hak akses memakai API. Halaman demo lama bukan entrypoint produksi.

## Menjalankan aplikasi

Dari direktori `app_inventory`, jalankan dengan API lokal pada port 3000:

```sh
flutter pub get
flutter run -d chrome --web-port=5173 --no-web-resources-cdn
```

Build web untuk penempatan di `/app/`:

```sh
flutter build web --release --base-href=/app/ --no-web-resources-cdn
```

Browser rilis memakai API pada origin yang sama, kecuali `API_URL` diatur. Build native memerlukan alamat HTTPS API melalui `--dart-define=API_URL=...`. Resolusi alamat ada di `lib/core/app_config.dart`. CanvasKit dibundel lokal melalui `web/flutter_bootstrap.js`.

Perintah pemeriksaan yang tersedia, bukan catatan hasil eksekusi:

```sh
flutter test
flutter analyze --no-pub
```

## Tampilan dan interaksi

[Catatan perubahan UI dan screenshot sebelum/sesudah](docs/ui-redesign.md) mencatat perubahan terhadap base `316f664` pada branch `SIMS-v1.0`, alur peminjam/admin, dan batas bukti pengujian.

Sumber tampilan yang dipelihara berada di repository:

- `lib/ui/tokens.dart`: navy Scitech `#0F2C59`, latar `#F3F2EE`, status, radius, dan nama font. Oranye menandai tenggat atau tindakan yang menunggu.
- `lib/ui/theme.dart` dan `lib/ui/components.dart`: tema, header, kartu, status berteks, serta motif label aset. `shortId()` mengambil paling banyak empat karakter alfanumerik awal dari ID record.
- `assets/fonts/`: Fira Sans untuk antarmuka dan IBM Plex Mono untuk ID, beserta lisensi font. Font tidak memerlukan CDN.
- `lib/production/auth/`: login, registrasi, pemulihan, dan input OTP. Layout ponsel menggulir hero dan formulir bersama agar formulir dapat bertambah tinggi.
- `lib/production/workspace/` dan `lib/production/catalog/`: navigasi menurut peran, peminjaman, persetujuan, katalog, dan detail barang.
- `lib/production/stats/`: statistik admin dari data aplikasi yang sudah dimuat, tanpa endpoint statistik baru atau library chart pihak ketiga.
- `web/index.html`, `web/manifest.json`, dan `web/icons/`: layar muat serta identitas web. Layout Next.js di `../app/layout.tsx` memakai warna tema yang sama.

### Pegas dan reduced motion

`lib/ui/springs.dart` menyediakan tiga preset dengan massa 1:

| Preset | Stiffness | Damping | Pemakaian |
|---|---:|---:|---|
| `snappy` | 500 | 30 | Umpan balik tekan dan pilihan aktif |
| `bouncy` | 300 | 16 | Buka sheet, centang pengajuan, kembali dari swipe |
| `gentle` | 180 | 27 | Transisi halaman, kemunculan daftar, grafik |

`springTo()` meneruskan kecepatan controller. `SpringCurve` menyediakan kurva dan durasi turunan simulasi untuk API Flutter yang membutuhkannya. Sheet menutup dengan `easeInCubic` selama 220 ms. `PressSpring` mengecilkan anak ke skala 0,96 ketika ditekan, lalu mengembalikannya dengan `snappy`, tanpa mengambil alih handler tap anak.

`reducedMotion(context)` membaca preferensi `MediaQuery`. Komponen yang memakainya melewati gerak spasial dan menampilkan nilai akhir; status serta kontrol tetap tersedia. Implementasi ini tidak berarti audit aksesibilitas menyeluruh sudah dilakukan.
