# Sistem visual SIMS · Sistem Inventory Management Scitech (V11 · Material 3 Expressive)

## Arahan eksplisit pengguna

- 2026-11-12: rombak besar UI dan penempatan aplikasi mengikuti panduan `~/Downloads/Material3-Design-Systems` (style AgroLens). "Tidak harus diikuti semuanya, tapi arahnya kurang lebih begitu."
- 2026-11-13: hasil V6 "masih ga sama" → UI harus benar-benar mirip plantify3. Pengguna memilih **warna persis AgroLens** (palet Daun default, enam palet AgroLens + Navy Scitech sebagai pilihan) dan **tab Beranda** untuk peminjam (Beranda · Katalog · Pinjaman · Akun).
- 2026-11-13: tombol, kartu, respons haptic, dan teks besar expressive juga mengikuti plantify3; bukan hanya animasi perpindahan layar.
- 2026-11-13 (terbaru): "revamp UI-nya agar style-nya benar-benar seperti plantify3, buang UI yang lama: login, lupa password, dll., pokoknya semua menu." Setiap layar meniru anatomi layar plantify3 terdekat (`~/Downloads/Material3-Design-Systems/04-Anatomi-Layar.md`), bukan sekadar arah.
- 2026-11-13 (V8): UI M3E diselaraskan untuk aplikasi inventaris Scitech: bawaan kembali ke Navy Scitech (`#0F2C59`), toples diganti peti peralatan, hero Beranda langsung menampilkan stok/rak + status pinjaman (bukan tutorial 3 langkah), dan kartu barang membawa kode ID pendek + status stok.
- 2026-11-06 (masih berlaku sebagai fitur): beberapa skema warna tema, foto profil, edit profil, pengaturan tema, dan pengaturan aplikasi.
- 2026-11-06 "default dominan putih" dan navy sebagai warna bawaan: **superseded** 2026-11-13 oleh palet Daun AgroLens.

Produksi tetap Flutter di `app_inventory/lib/production` dengan sistem bersama di `lib/ui`. Semua alur, hak akses, API, dan data dipertahankan. Tidak ada perubahan database, commit, push, atau deploy.

## Fakta identitas

Nama produk **SIMS** (Sistem Inventory Management Scitech), konstanta di `app_inventory/lib/core/brand.dart`. Logo SIMS **Kit Case** (2026-11-14, dipilih pengguna dari tiga konsep logo-design-skill): koper alat navy `#0F2C59` dengan wajah prompt `>|` Scitech beraksen Kobalt `#2E5BD0`; master dan aturan pakai di `app_inventory/assets/brand/` (`kit/sims-logo-guidelines.md`). Di atas navy selalu tanda putih; ≤24 px pakai versi kecil tanpa wajah. Logo induk Scitech (`assets/images/Logo.png`) tidak lagi dipakai di aplikasi. Palet bawaan **Navy Scitech** (`#0F2C59`) dengan kanvas slate sejuk `#F5F7FB` dan kontainer biru langit `#D2E4FF`; enam palet ekspresif lain (Kobalt, Zamrud, Koral, Amber, Violet, Magenta) tetap tersedia sebagai pilihan.

## Keputusan implementasi

- **Tipografi:** Poppins 400–800 dibundel (OFL), skala tema persis plantify3: headlineMedium 28/w700 (judul halaman), headlineSmall 24/w700, titleLarge 22/w600 (judul seksi), body tinggi baris 1,5–1,55, tombol 52 dengan label 15. Ukuran 32/40 iterasi sebelumnya superseded karena mendorong pill header ke bawah judul. Judul membungkus, tidak diperkecil.
- **Warna:** `lib/ui/palette.dart`: **Navy Scitech** default (skema tangan `_navyLight`/`_navyDark`), **Zamrud** memakai skema hijau tangan (`_leafLight`/`_leafDark`), palet lain dari seed `DynamicSchemeVariant.vibrant`; hero = seed (terang) atau primaryContainer (gelap), `onHero` putih bila kontras ≥ 3:1. Status (ok/deadline/error) terpisah dari palet. Preferensi `palette` lama `'leaf'` otomatis beralih ke Navy Scitech.
- **Hero:** `HeroCard` (radius 32, warna merek penuh, bentuk lembut `heroSoft` di belakang, CTA pil putih). Satu fokus per layar.
- **Bentuk:** bentuk organik polar (`lib/ui/shapes.dart`) stabil per tujuan dan kategori. Tujuan: Ringkasan/Katalog cookie9, Pinjaman clover4, Barang sunny8, Statistik gem, Pengadaan pentagon, Pengguna flower8, Riwayat burst, Akun cookie12, Lainnya softBurst. Swatch skema: Navy cookie12, Teal clover4, Ungu gem, Hijau flower8, Beri burst. Status: ok lingkaran, menunggu sunny8, masalah burst.
- **Sudut:** tombol pil → 12 saat ditekan; chip 8 → 16 terpilih; input 16; kartu 24; grup/daftar tersambung luar 28 dalam 8; sheet/dialog 28; hero 32.
- **Navigasi:** dock `ExpressiveNavBar` AgroLens. Peminjam: Beranda (cookie9) · Katalog (clover4) · Pinjaman (flower8) · Akun (sunny8). Admin: Ringkasan · Barang · Pinjaman · Lainnya (sheet). ≥900 px: rail dengan badge yang morph.
- **Peta layar:** Auth (V9.1, 2026-11-13) = header hero penuh selebar layar (bar merek + tombol kanan atas + tombol kembali pada sub-langkah, seni peti alat/amplop/kunci/gembok/ID, titik langkah hanya untuk alur >1 langkah) + sheet melengkung `surface` (`radius 32` atas) yang menumpuk `-28 px` ke hero berisi `ExpressiveTextField`, kartu kekuatan sandi, dan tombol utama 56. Masuk hanya memakai email + kata sandi; OTP khusus verifikasi daftar akun dan lupa sandi. Beranda = sapaan nama + hero 2 halaman langsung (stok & peti alat `BallPit` di halaman 0, status pinjaman di halaman 1). Katalog = Pustaka + lencana ID monospace & titik status di `ItemRow`. Detail barang = layar hasil (header 42 %, kartu vonis −44 dengan ring 96, action bar). Pengajuan, edit profil, editor barang = editor artikel. Pinjaman = Riwayat. Akun & pengaturan = Pengaturan. Barang/Pengadaan/Pengguna admin = Kelola artikel (aksi bentuk 38, FAB). Form prompt = sheet editor; konfirmasi = dialog hapus.
- **Header halaman:** header Pustaka/Riwayat: headlineMedium + subjudul, satu `PillAction` (48, label 15) sebaris di kanan.
- **Kontrol:** `ExpressiveTextField` (V10.4: satu isian tonal, bukan kartu berisi kotak kedua; `PressSpring` saat ditekan, haptic seleksi, fokus morph sudut 24→16 + garis primary + lencana bentuk berputar, lencana pop dan huruf berbentuk melompat saat mengetik; isian sandi hanya menampilkan titik), `PasswordStrength` (meter bergelombang + syarat yang dilipat di balik baris `n/6`), `ExpressiveSearchBar`, `ExpressiveFilterChip`, `ExpressiveButtonGroup` untuk semua pilihan, `GroupCard`, `LinkGroup/LinkTile`, `StatusPill`. Dihapus: `AssetTag`, `UnitMeter`, `LedgerGroup`, `SegmentedTabs`, `FormDialog`, baris register berkolom, header kartu editor.
- **Gerak:** pegas (`lib/ui/springs.dart`): fastSpatial/defaultSpatial/slowSpatial, effects, bouncy, wobbly. `PressSpring` dengan squash kecil, morph tombol di tema (`lib/ui/morph.dart`), `Reveal`, `CountUp`, `ShapeBurst` hanya setelah operasi berhasil. Reduced motion (sistem atau "Kurangi gerak") mematikan gerak spasial helper ini.
- **Respons kontrol:** tombol Material memakai `ButtonStyle.foregroundBuilder` bersama di `lib/ui/button_feedback.dart`: isi mengempis saat ditekan dan memantul kembali; outline tetap morph lewat tema. Haptic ringan sekali saat tombol memasuki state pressed adalah tanda sentuhan, bukan tanda operasi server berhasil. Aksi `InkWell` kustom memakai `tactileTap` setelah tap diterima; batal scroll dan kontrol nonaktif tidak mengeksekusi aksi. Haptic bergantung dukungan platform/perangkat; reduced motion mematikan gerak, tidak membatalkan aksi.

## Kontrak adaptif dan aksesibilitas

- Layar 360×640 dengan keyboard dan text scaling hingga 2×: konten membungkus dan menggulir. Label dock dibatasi 1,15× agar tetap satu baris; teks lain tidak dibatasi.
- Desktop memakai rail dan panel daftar–detail, konten maks. 1160.
- Target sentuh minimal 48 dp, fokus terlihat, status tidak bergantung pada warna.

## Verifikasi

Hasil perintah dan batasnya dicatat di `app_inventory/docs/ui-redesign.md`.
