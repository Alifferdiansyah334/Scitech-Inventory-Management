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

[Catatan UI dan screenshot sebelum/sesudah](docs/ui-redesign.md) mencatat tampilan, alur yang diuji, dan batas bukti. Spesifikasi desain (V6 · arah AgroLens dari `~/Downloads/Material3-Design-Systems`) ada di [`../DESIGN.md`](../DESIGN.md).

Sumber tampilan yang dipelihara berada di repository:

- `lib/ui/palette.dart`: skema warna yang diturunkan dari seed merek (Navy Scitech `#0F2C59` bawaan, Teal Lab, Ungu Riset, Hijau Daun, Beri), mode gelap, dan tiga tingkat kontras. Semua peran warna (permukaan, container, hero, tint kategori, ID chip) memakai hue seed. `AppColors` membaca palet aktif saat runtime, jadi warna tidak boleh berada di ekspresi `const`. Oranye hanya menandai tenggat atau tindakan yang menunggu.
- `lib/ui/tokens.dart`: tangga sudut (8→16 chip, 16 input, 24 kartu, 28 grup tersambung/sheet/dialog, 32 hero; tombol pil yang menjadi 12 saat ditekan), skala jarak, dan nama font.
- `lib/ui/theme.dart` dan `lib/ui/components.dart`: tema dan komponen bersama, dengan target sentuh minimal 48 dp dan cincin fokus terlihat.
  - `HeroCard`: satu blok fokus berwarna merek per layar, dengan bentuk lembut di belakang.
  - `GroupCard`, `LinkGroup`/`LinkTile`: kelompok pengaturan dan baris tautan tersambung dengan badge berbentuk.
  - `StatusPill`: status berupa warna, bentuk, ikon, dan teks.
  - `AssetTag`: ID chip dengan ID pendek dari `shortId()`, yaitu paling banyak empat karakter alfanumerik awal dari ID record, bukan kode aset karangan.
  - `UnitMeter`: bar pil bersegmen, satu segmen per unit.
  - `LedgerGroup`: daftar bersegmen; setiap baris memiliki container sendiri.
  - `SegmentedTabs`: grup tombol terhubung; segmen terpilih memakai warna hero dan melebar dengan pegas; menumpuk saat teks diperbesar.
- `lib/ui/controls.dart` (+ `controls/`): dock `ExpressiveNavBar`, `ExpressiveSearchBar`, `ExpressiveFilterChip`, `ExpressiveButtonGroup`. `lib/ui/motion.dart`, `physics.dart`, `widgets.dart`: `CountUp`, `WordReveal`, `ShapeBurst`, `TiltOnTouch`, `PopIn`, `Reveal`.
- `lib/ui/shapes.dart`: bentuk M3 Expressive (cookie, clover, sunny, arch, pentagon, burst, dan lainnya) untuk penanda kategori, lencana, keadaan kosong, dan bingkai foto. `lib/ui/progress.dart` berisi indikator progres bergelombang linear dan cincin. `lib/ui/avatars.dart` berisi delapan avatar ilustrasi.
- `lib/core/appearance.dart`: preferensi tema (skema, mode, warna dinamis, kontras), ukuran teks, kurangi gerak, default pesan WhatsApp, dan foto profil per akun. Semuanya disimpan di perangkat dengan `shared_preferences`. Warna dinamis memakai `dynamic_color` dan hanya aktif di Android 12+.
- `assets/fonts/`: Poppins 400–800 dan Roboto Mono (ID saja), beserta lisensi OFL. Font tidak memerlukan CDN.
- `lib/production/auth/`: login (tab OTP/Kata sandi dalam satu layar), registrasi, pemulihan, dan input OTP; ponsel memakai satu `HeroCard` di atas formulir, layar lebar memakai hero tinggi di kiri dan formulir dalam kartu putih.
- `lib/production/workspace/` dan `lib/production/catalog/`: navigasi menurut peran, antrean persetujuan (daftar–detail di layar lebar, sheet di ponsel), peminjaman, katalog, detail barang, serta Akun, Edit profil, Tema & tampilan, dan Pengaturan.
- `lib/production/stats/`: statistik admin dari data aplikasi yang sudah dimuat, tanpa endpoint statistik baru atau library chart pihak ketiga.
- `web/index.html`, `web/manifest.json`, dan `web/icons/`: layar muat serta identitas web, dengan warna yang mengikuti hero terang bawaan. Layout Next.js di `../app/layout.tsx` memakai warna yang sama.

### Gerak dan reduced motion

`lib/ui/springs.dart` memakai skema pegas ekspresif Material 3 (massa 1). Pegas spasial memindahkan, mengubah ukuran, dan mengubah bentuk elemen, dan boleh melewati target sedikit. Pegas efek mengubah warna dan opasitas, dan tidak pernah melewati target.

| Pegas | Rasio redaman | Stiffness | Pemakaian |
|---|---:|---:|---|
| `fastSpatial` | 0,6 | 800 | Tekan tombol, chip, grup tombol |
| `defaultSpatial` | 0,8 | 380 | Transisi halaman, sheet, kartu |
| `slowSpatial` | 0,8 | 200 | Gerak besar, grafik |
| `fastEffects` / `defaultEffects` / `slowEffects` | 1 | 3800 / 1600 / 800 | Warna dan fade |

Gerak ekspresif yang terlihat pengguna:

- **Morph tombol** (`lib/ui/morph.dart`): Filled, Tonal, Outlined, Text, dan Elevated berubah dari pil ke sudut 12 saat ditekan. IconButton berubah dari lingkaran ke sudut 14, atau 16 saat terpilih. Material menganimasikan bentuk dengan kurva tetap, jadi `MorphBorder` membalik kurva itu lalu menerapkan pegas `fastSpatial` beserta overshoot-nya. Chip membulat ke 16 saat terpilih.
- **Grup tombol** (`SegmentedTabs`): segmen yang ditekan melebar 18% dan sudut dalamnya membulat, tetangganya menyempit, dan segmen terpilih memantul menjadi pil berwarna merek.
- **Ikon berbentuk** (`ShapeIcon`): di dalam `PressSpring`, bentuknya berputar 30° dan mendekati lingkaran selama ditekan. Ikonnya tetap tegak.
- **`ExpressiveLoadingIndicator`**: bentuk berganti setiap 650 ms sambil berputar. Dipakai di layar pemulihan sesi dan di tombol yang sedang memproses.

`PressSpring` memantul ke `scale` (0,96 untuk kartu, 1 untuk baris daftar) dan membagikan progres tekan lewat `PressSpring.progressOf`. `reducedMotion(context)` membaca preferensi `MediaQuery`, yang juga aktif bila "Kurangi gerak" dinyalakan di Pengaturan. Pada keadaan itu morph tombol menjadi instan, tekan tidak memantul, dan loading indicator berhenti pada satu bentuk. Implementasi ini tidak berarti audit aksesibilitas menyeluruh sudah dilakukan.
