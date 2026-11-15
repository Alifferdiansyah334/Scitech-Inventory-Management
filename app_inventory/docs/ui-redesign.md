# Catatan UI aplikasi Flutter

## Dokumentasi dan screenshot terkini · 2026-11-15

- Overview, tech stack, fitur, arsitektur, dan diagram alur terbaru ada di [README repository](../../README.md); panduan client di [README Flutter](../README.md).
- `current-login-mobile.png`, `current-home-mobile.png`, `current-catalog-mobile.png`, dan `current-admin-desktop.png` pada `screenshots/ui-redesign/` diambil ulang dari build Flutter Web sumber V11.2 pada 15 November 2026. Mode gelap; viewport 390×844 dan 1440×1000. Preview memakai fixture lokal dengan identitas dan transaksi contoh, bukan layanan produksi.
- Verifikasi sesi ini: `flutter test` **42 tes lulus**; `flutter build web --release --base-href=/ --no-web-resources-cdn` berhasil; layar masuk, Beranda, Katalog, dan Ringkasan admin diperiksa di Chromium. Build melaporkan peringatan font CupertinoIcons tidak tersedia; build tetap selesai.
- Bagian V11.2 di bawah menjelaskan perilaku keyboard terkini. Bagian versi sebelumnya adalah riwayat, bukan spesifikasi aktif; beberapa screenshot historis hanya tersedia lokal. Berkas `after-*` yang sudah ada di Git berasal dari iterasi lama dan tidak dipakai sebagai screenshot UI terkini.

## V11.2 · koreksi field tertutup keyboard (2026-11-14)

- Laporan pengguna: setelah V11.1, teks yang sedang diketik tidak terlihat. Menghapus fallback fokus tanpa mengganti sumber inset mengembalikan masalah pada Android lama yang hanya menyediakan visible insets.
- `KeyboardInsets.kt` meneruskan `WindowInsetsCompat.Type.ime()` melalui event channel untuk Android API <30. Observer dilepas saat stream/engine ditutup. Android API ≥30 tetap memakai metrik engine Flutter.
- `AndroidKeyboardInsets` di builder aplikasi memakai pengukuran native hanya ketika inset Flutter nol; konversi piksel memakai DPR, tidak menjumlahkan kedua inset. Setelah viewport menyusut, caret digulir seperlunya dengan padding field, bukan diposisikan ke seperempat layar. Fokus dan teks tetap hidup saat keyboard buka/tutup. Berlaku juga pada form di luar auth.
- Tidak memakai timer, perkiraan persentase layar, atau perubahan ukuran hero.
- Verifikasi awal: 11 tes terkait lulus, termasuk inset Flutter nol/pengukuran native 600 px pada DPR 2, teks/fokus bertahan, pengukuran berulang tidak menggeser lagi, keyboard ditutup mengembalikan viewport, dan metrik Flutter normal tetap diprioritaskan. Analisis Dart file terkait bersih.
- Verifikasi native: APK debug x64 berhasil dibangun dan dipasang di Redroid Android 8.1. Email dan sandi tetap terlihat di atas LatinIME saat mengetik/pindah field; tombol Back menutup IME dan mengembalikan form dengan isi tetap utuh. Screenshot dan rekaman 15 detik diperiksa (`/tmp/sims-native-{keyboard,password,closed}.png`, `/tmp/sims-keyboard-fix.mp4`). Perubahan Kotlin memerlukan rebuild/relaunch penuh, bukan hot reload. HP fisik belum diuji.

## V11.1 · scroll input tanpa gerakan susulan (2026-11-14; jalur inset nol dikoreksi V11.2)

- Hapus dugaan keyboard berbasis timer 320 ms, padding buatan 45% layar, dan `ensureVisible` ke seperempat layar. Fokus tanpa keyboard (termasuk keyboard fisik) tidak lagi memindahkan form; keyboard lambat tidak memicu dua pengguliran.
- Tinggi hero memakai ukuran layar dan `viewPadding` di atas `Scaffold`, bukan safe padding yang berubah selama animasi keyboard. Footer tetap berada di alur form.
- Pemulihan offset hanya terjadi setelah inset keyboard turun ke nol dan viewport selesai layout, bukan setiap kali fokus lepas. Perpindahan isian tidak menarik halaman kembali; fokus baru membatalkan pemulihan lama, dan scroll manual membatalkan target pemulihan.
- Verifikasi: 9 tes auth/input lulus; analisis tiga file yang diubah bersih. Smoke render sementara dengan animasi aktif dan inset bertahap 0→300→0 lulus; frame fokus, keyboard terbuka, dan keyboard ditutup diperiksa. Script smoke dihapus.
- Batas: inset pada smoke disimulasikan, bukan IME native. Perangkat fisik terkunci; AVD gagal siap setelah startup biasa dan cold boot. Redroid yang tidak melaporkan inset kini mengikuti perilaku Flutter bawaan, tanpa tebakan tinggi keyboard. APK baru belum diverifikasi.

## V11 · SIMS: rebranding, performa, keyboard natural, splash baru, refactor ≤300 baris (2026-11-14, berlaku)

Permintaan pengguna: optimasi agar ramah spesifikasi rendah tanpa mengurangi interaksi; logo dengan logo-design-skill; auto-scroll keyboard yang natural; splash M3 Expressive; refactor maks 300 baris per file lewat subagent; rebranding menjadi SIMS (Sistem Inventory Management Scitech).

- **Rebranding (`lib/core/brand.dart`):** `appName = 'SIMS'`, `appTagline = 'Sistem Inventory Management Scitech'` dipakai di judul aplikasi, bar merek auth (nama + tagline), rail desktop, header Beranda/Ringkasan (`SIMS Admin`), label konteks admin, halaman pembaruan, splash. Label launcher Android/iOS `SIMS`, manifest/judul web `SIMS · Sistem Inventory Management Scitech`, deskripsi pubspec.
- **Performa tanpa mengurangi interaksi:**
  - `expressiveShapePath` (`lib/ui/shapes.dart`): radius tiap bentuk dan arah sampel dihitung sekali (tabel `Float64List`), rotasi diterapkan dengan 2 trigonometri per bentuk (sebelumnya ±700 per bentuk per frame), outline dikirim sebagai satu `addPolygon` alih-alih 180 panggilan `lineTo`. Semua bentuk morph/berputar (konfeti, orbit, lencana, BallPit) ikut lebih ringan.
  - `Ambient` kini membungkus dirinya dengan `RepaintBoundary`, jadi animasi loop (hero, konfeti, Bob) tidak me-repaint seluruh layar.
  - `ExpressiveTextField` dan `ExpressiveSearchBar`: huruf berbentuk yang melompat digambar di lapisan sendiri (`ValueNotifier` + `RepaintBoundary`); isian tidak lagi di-rebuild 60×/detik selama mengetik, dan "pop" lencana hanya me-rebuild lencananya.
  - `AuthSwitch`: `Opacity` per frame (save layer) diganti `FadeTransition` di compositor.
  - Foto barang (`WorkspaceActions.picture`) di-decode seukuran tampilan (`cacheWidth`, kelipatan 64 px) alih-alih resolusi penuh hingga 2 MB.
- **Keyboard (implementasi awal V11, digantikan V11.1 di atas):** hero dipertahankan saat keyboard terbuka, tetapi fallback timer 320 ms dan pemulihan saat fokus lepas masih menimbulkan gerakan susulan.
- **Splash (`lib/production/brand_splash.dart`):** satu controller linier 1,5 detik menggerakkan seluruh koreografi lewat kurva pegas: pelat putih memantul circle→cookie, tanda SIMS muncul, lima kategori alat terbang dari tepi dan mengorbit, huruf S-I-M-S mendarat satu per satu, tagline memudar, dua blob latar morph. Reduced motion: langsung selesai.
- **Refactor ≤300 baris:** gelombang 1 (components, palette, katalog, workspace, statistik) dan gelombang 2 (auth, kontrol inti, physics/playground/shapes) oleh subagen, berupa pemecahan `part` tanpa perubahan perilaku.
- **Logo SIMS (`assets/brand/`, logo-design-skill):** tiga konsep (A Hook & Peg, B Socket S, C Kit Case) dibuat, diaudit (100/100), dan diuji 16/32/48 px, satu warna, reversed, squint, rak tiruan. Pengguna memilih **C · Kit Case** dengan **aksen biru tua**: koper alat navy `#0F2C59` dengan wajah prompt `>|` Scitech berwarna Kobalt `#2E5BD0` (5,96:1 di putih). Kit: master SVG (warna, navy, hitam, putih, kecil tanpa wajah ≤24 px, lockup horizontal/stacked dengan wordmark Poppins ExtraBold yang di-outline), PNG untuk aplikasi, ikon launcher Android (lama + adaptive + monochrome Android 13), ikon splash Android 12+, favicon/ikon web/maskable, AppIcon iOS, papan presentasi dan panduan `assets/brand/kit/sims-logo-guidelines.md`. Dipasang: `BrandMark` (splash, warna penuh di pelat putih), `WhiteLogo`/`AuthLogo` (tanda satu warna di bar merek, Beranda, rail, Akun), splash native Android navy + tanda putih (`values-v31`, `launch_background.xml`, `colors.xml`), splash web navy. Belum ada penelusuran merek dagang.

## V10.5 · pertanyaan hero Beranda berganti dengan geser (2026-11-14, berlaku)

Koreksi pengguna: transisi "Butuh drone?" di hero Beranda harus seperti digeser kiri/kanan.

- **`home/catalog_hero.dart` `_CyclingQuestion`:** `WordReveal` per kata diganti `AnimatedSwitcher` geser: pertanyaan baru masuk dari kanan (55 % lebar) dengan pegas spasial (sedikit overshoot) sambil memudar masuk, pertanyaan lama keluar ke kiri dengan kurva mempercepat (260 ms). Dibungkus `ClipRect` agar teks tidak keluar dari kolom. Reduced motion: langsung berganti tanpa geser. Pertanyaan bergilir tidak diumumkan berulang ke pembaca layar.

## V10.4 · keyboard ditutup = kembali ke awal, syarat sandi dilipat, isian seragam ekspresif (2026-11-14, berlaku)

Koreksi pengguna: (1) setelah keyboard ditutup tampilan harus kembali seperti sebelum menggulir sendiri; (2) daftar syarat kata sandi dijadikan konten yang bisa dilipat; (3) isian di Edit profil (dan form lain) belum terasa Material 3 Expressive: kaku, tanpa feedback saat ditekan.

- **Kembali ke awal (`auth_entry.dart`):** offset gulir disimpan saat isian mulai fokus; saat fokus lepas, hero tumbuh lagi lalu halaman beranimasi kembali ke offset itu. Inset keyboard yang turun ke 0 (keyboard ditutup lewat back/tombol IME) melepas fokus isian, karena Android tidak melepasnya sendiri. Geser-untuk-menutup keyboard dihapus agar tidak melawan jari saat halaman kembali. Keterbatasan: di Redroid inset keyboard tidak pernah dilaporkan, jadi di emulator itu fokus baru lepas saat mengetuk di luar isian.
- **Syarat kata sandi (`password_strength.dart`, `_RulesPanel`):** daftar syarat dilipat di balik satu baris (lencana bentuk, "Syarat kata sandi", pil `n/6`, chevron). Ketuk: baris memadat (`PressSpring`), haptic ringan, chevron berputar, daftar terbuka dengan pegas `bouncy`; semantik tombol dengan jumlah syarat terpenuhi. Dipakai di Sandi baru dan form ganti sandi.
- **Isian seragam (`lib/ui/controls/text_field.dart`):** `ExpressiveTextField` tidak lagi berupa kartu berisi kotak isian kedua. Kini satu isian tonal: `PressSpring` saat ditekan, haptic seleksi saat diketuk, sudut morph 24→16 + garis primary + lencana berputar/berubah warna saat fokus (pegas `bouncy`), lencana "pop" tiap karakter, huruf berbentuk tetap melompat keluar, hitung kata untuk teks panjang, error hingga 3 baris, ketuk di luar melepas fokus. Berlaku untuk auth, Edit profil, editor barang, pengajuan, dan prompt admin. `_AuthInput` khusus auth dan `text_field_header.dart` dihapus (satu konvensi). Validasi tidak lagi muncul merah saat baru mulai mengetik; pesan muncul saat dikirim.
- **Verifikasi:** `flutter analyze` 0 issue; `flutter test` 39/39, termasuk tes baru `test/password_strength_test.dart` (syarat terlipat, `5/6` → `6/6`, buka/tutup) dan tes auth yang kini memastikan hero kembali ke tinggi dan posisi awal (gulir 0) setelah keyboard ditutup.

## V10.3 · isian tetap terlihat saat mengetik (2026-11-14, berlaku)

Koreksi pengguna (screenshot Lupa sandi): isian email tertutup keyboard saat mengetik karena hero tinggi V10.2 tetap memenuhi layar.

- **Penyebab:** hero tinggi bergantung pada sisa tinggi viewport, sedangkan Redroid (Android 8.1) tidak melaporkan inset keyboard ke Flutter, jadi layar tidak menyusut dan hero tetap tinggi.
- **Perbaikan (`auth_entry.dart`):** `AuthFrame` mendengarkan `FocusManager`; saat isian teks di dalam frame fokus, hero kembali ke ukuran alami (beranimasi), ruang gulir tambahan 45 % viewport ditambahkan di bawah form bila inset keyboard tidak dilaporkan, lalu isian digulir ke ±30 % tinggi layar setelah layout selesai (`endOfFrame` + `Scrollable.ensureVisible`). Lepas fokus mengembalikan hero tinggi.
- **Verifikasi:** tes baru di `test/auth_recovery_test.dart` (390×844, tanpa inset keyboard): hero menyusut setelah isian diketuk dan isian berakhir di atas 60 % tinggi layar (gagal sebelum perbaikan, lulus sesudahnya); `flutter test` 38/38, analyze 0 issue.

## V10.2 · hero auth mengisi layar (2026-11-14, berlaku)

Koreksi pengguna (screenshot Masuk): "terlalu kosong" — ±225 px kanvas kosong di bawah tautan Daftar.

- **`auth_entry.dart`:** ukuran bilah merek dan blok form diukur setelah layout (`_SizeReporter`); sisa tinggi viewport diberikan ke hero lewat `AuthHero.minHeight`.
- **`auth_hero.dart`:** bila sisa ≥ 320 px (dan teks ≤ 1,3×, ponsel), hero berubah ke tata letak tinggi: judul satu baris di atas, adegan kontekstual besar (maks. 260 px) di tengah blok, bentuk tahap besar di belakangnya, titik langkah di kaki. Keyboard terbuka, form panjang (Daftar, OTP), atau teks besar mengembalikan hero ke ukuran alaminya dengan `AnimatedSize`.
- **Verifikasi:** analyze 0 issue, 37/37 tes. Layout sementara 390×844: Masuk hero 322 px, Lupa sandi 461 px (tombol berakhir di 820/844), OTP & Daftar tetap ukuran alami; 360×640 tanpa exception. Redroid: Masuk dan Lupa sandi tampil penuh tanpa kanvas kosong.

## V10.1 · hero auth meriah + daftar tanpa Tim/divisi (2026-11-14, berlaku)

Koreksi pengguna: "tidak usah pakai Tim/divisi; buat hero login, lupa sandi, dan OTP lebih meriah, sesuai konteks, dan Material 3 Expressive."

- **Daftar akun:** isian `Tim / divisi (opsional)` dihapus, dan `department` tidak lagi dikirim ke `POST api/mobile/auth/register` (skema backend `department` opsional). Edit profil tetap punya isian divisi.
- **Hero (`auth_hero.dart`):** kembali ke blok warna merek penuh dengan sudut organik asimetris (36/60/48/24), bentuk tahap besar yang morph antarlangkah dengan pegas `bouncy` dan berputar pelan, bentuk kedua di kiri bawah, tujuh "konfeti" bentuk M3 (secondary/tertiary/putih transparan) yang melayang di tepi tanpa menutup teks, chip alur, judul `WordReveal` w800, titik langkah, dan kartu miring saat disentuh (`TiltOnTouch`). Adegan muncul dengan `PopIn`.
- **Adegan kontekstual (`auth_stages.dart`, satu kontrol `_Scene` per adegan: semantik tombol, `PressSpring`, `InkWell` + `tactileTap`, goyangan pegas `wobbly` tiap ketukan):**
  - **Masuk** `AuthEquipmentArt`: kotak inventaris Scitech di tengah, lima kategori (Kamera, Drone, Audio, Proyektor, Perkakas) mengorbit; ketuk memutar orbit satu slot dengan pegas dan memperbesar kategori berikutnya.
  - **Lupa sandi** `AuthKeyArt`: kunci melayang di samping gembok + tanda tanya; ketuk memasukkan dan memutar kunci (gembok terbuka), ketuk lagi mencabutnya. Hanya mainan, bukan hasil pemulihan.
  - **OTP** `AuthEnvelopeArt(filled:)`: enam gelembung kode keluar dari amplop dan terisi sesuai jumlah digit yang diketik (input, bukan verifikasi); ketuk mengganti amplop menjadi perisai "jangan bagikan kode".
  - **Sandi baru** `AuthLockArt`: gembok dikelilingi titik sandi yang mengorbit; menutup saat kedua isian siap disimpan (nilai semantik "belum disimpan").
  - **Daftar** `AuthBadgeArt`: kartu ID Scitech dengan stiker kategori; ketuk mengganti stiker.
- **Verifikasi:** `flutter analyze` 0 issue; `flutter test` 37/37 lulus (tes daftar kini memastikan `department` tidak terkirim). APK profile di Redroid: Masuk, Lupa sandi, OTP kosong dan terisi 3 digit, Daftar diperiksa lewat screenshot.

## V10 · auth tonal + feedback sentuh di setiap kontrol (2026-11-14, berlaku)

Koreksi pengguna: "revamp lagi login, forgot, dan OTP agar makin Material 3 Expressive; setiap komponen kalau diklik ada feedback-nya."

- **Masalah V9.1 (dari screenshot pengguna):** hero navy penuh + peti besar memakan separuh layar; isian berupa kartu editor yang memuat kotak isian lagi (kotak dalam kotak), sehingga pesan error terlihat terjepit.
- **Komposisi baru (`auth_entry.dart`, `auth_hero.dart`):** bar merek tenang di atas kanvas (tombol kembali bulat pada sub-langkah), hero tonal asimetris (sudut 28/48/36/20) dengan judul Poppins w800 besar dan satu ilustrasi interaktif kecil, lalu form langsung di kanvas. Tidak ada lagi loop ambient yang bersaing dengan form.
- **Isian (`auth/auth_input.dart`, baru):** satu `TextFormField` tonal per isian; saat fokus sudut morph 24→16, outline primary, dan lencana bentuk berputar + berubah warna; tekan memadat lewat `PressSpring`; ketuk memberi haptic seleksi; error tampil di bawah isian hingga 3 baris. Tombol mata sandi memakai `IconButton` terpilih (morph tema).
- **Tombol utama:** 60 px, ikon dalam lingkaran tonal, berganti `ExpressiveLoadingIndicator` saat memproses; tetap memakai feedback tema bersama (`button_feedback.dart`: isi mengempis + memantul, outline morph, haptic ringan).
- **Ilustrasi (`auth_stages.dart`):** setiap langkah punya satu kontrol nyata (semantik tombol, fokus keyboard, `PressSpring` + `InkWell` + `tactileTap`): kategori perlengkapan berganti saat diketuk (Masuk), kunci → tips email (Lupa sandi), amplop → pengingat keamanan kode (OTP), gembok → tips sandi unik (Sandi baru), kartu ID → tips email aktif (Daftar). OTP lengkap atau sandi cocok **tidak** lagi ditampilkan sebagai centang/sukses sebelum server memverifikasi.
- **OTP (`otp_input.dart`):** enam sel tersambung (sudut luar 22–26, dalam 8–18), sel aktif berbingkai primary + garis indikator, sel terisi `primaryContainer`, seleksi teks `secondaryContainer`; status "n/6 digit terisi"; tetap satu isian asli untuk tempel, autofill kode, seleksi, dan pembaca layar. Hitung mundur kirim ulang menjadi status non-interaktif; setelah habis menjadi `FilledButton.tonal`. `resend()` kini menolak saat sibuk/hitung mundur dan membersihkan pesan lama.
- **Lupa sandi:** penunjuk 3 langkah (Email · Kode · Sandi) muncul di ketiga langkah dengan status selesai/saat ini; email tujuan ditampilkan di atas sel OTP.
- **Verifikasi:** `flutter analyze` 0 issue; `flutter test` 37/37 lulus, termasuk tes baru `test/auth_recovery_test.dart` (360×640, teks 2×, tema gelap, keyboard 280: lupa sandi → OTP pendek ditolak tanpa request → kode salah tampil error → kirim ulang setelah 60 dtk → kode benar → sandi tidak cocok menonaktifkan simpan → reset terkirim, tetap belum login).

## V9.1 · hapus login OTP + sempurnakan sheet auth (2026-11-13, berlaku)

Koreksi pengguna: "tidak ada opsi login kode OTP — kode OTP itu untuk membuat akun — dan rapikan lagi style-nya."

- **Alur masuk (`auth_page.dart`, `auth_views.dart`):** tab `Kode OTP | Kata sandi` pada layar Masuk dihapus. Layar Masuk langsung menampilkan `Email kantor` + `Kata sandi` (`POST api/mobile/auth/login`). Kode OTP 6 digit kini khusus untuk verifikasi pendaftaran akun (`Daftar akun`) dan pemulihan kata sandi (`Lupa sandi`).
- **Penyempurnaan visual (`auth_entry.dart`, `auth_hero.dart`, `password_strength.dart`, `inventory_jar.dart`):**
  - Kartu putih ber-border dihilangkan agar tidak bertumpuk 3 lapis; sheet melengkung (`radius 32` di atas) kini memakai warna kanvas `#F5F7FB` langsung sehingga isian `ExpressiveTextField`, `RememberToggle`, dan kartu baru `PasswordStrength` (`radius 22`) tampil menyatu seperti layar lain.
  - Langkah tunggal (Masuk) menyembunyikan indikator titik langkah; sub-halaman (`Daftar`, `Lupa sandi`, `Kode`, `Sandi baru`) mendapat tombol kembali bulat transparan di kiri atas hero.
  - Bola kategori di `InventoryCrate` diperbesar sedikit agar peti peralatan terlihat lebih penuh.
- **Verifikasi:** `flutter analyze` 0 issue; `flutter test` 36/36 lulus (`connected_app_test.dart` dan `password_registration_test.dart` disesuaikan tanpa tab OTP login). APK profile di Redroid `emulator-5554`: screenshot diverifikasi untuk Masuk, Lupa sandi, dan Daftar akun (atas dan bawah).

## V9 · auth berlapis hero penuh + kartu form menyatu (2026-11-13, berlaku)

Koreksi pengguna: "tinggal di register screen, forgot password, dan sign in saja yang masih kurang; rombak dengan style Material 3 Expressive."

- **Masalah V8 pada layar auth:** hero berbentuk kotak kecil ber-margin sehingga terpisah dari bilah atas, ada ruang putih kosong ~300 px di antara isian satu kolom dan tombol bawah yang dipaku, serta daftar/sandi baru terpotong tepat di tepi bilah bawah.
- **V9 (`auth_hero.dart`, `auth_entry.dart`, `auth_views.dart`):**
  - **Ponsel:** hero penuh selebar layar sampai di bawah status bar (`topBar` menyatu di dalam hero dengan tombol pil transparan di kanan atas, sudut bawah 38), lalu kartu form putih `radius 32` naik menumpuk `-30 px` di atas tepi lengkung hero (serupa anatomi detail barang / `result_screen` AgroLens). Tombol aksi utama 56 px berada langsung di dalam kartu di bawah isian, sehingga ruang kosong hilang dan semua langkah mengalir alami bersama keyboard.
  - **Lupa sandi:** kartu mendapat penunjuk 3 langkah (`1. Email` · `2. Kode` · `3. Sandi`) di atas isian email; langkah kode dan sandi baru memakai kartu tumpuk yang sama tanpa memotong daftar syarat sandi.
  - **Desktop (≥900):** dua kolom (hero besar di kiri, kartu form + tombol + tautan di kanan, maks. 1160).
- **Verifikasi:** `flutter analyze` 0 issue; `flutter test` 36/36 lulus (termasuk `360×640` teks 2× + inset keyboard 280 dan alur registrasi); APK profile di Redroid `emulator-5554`: screenshot diverifikasi untuk Masuk OTP, Masuk kata sandi, Lupa sandi 1–2, Verifikasi OTP, dan Daftar akun.

## V8 · identitas inventaris Scitech (Navy + peti alat + Beranda langsung) (2026-11-13, berlaku)

Koreksi pengguna: menyukai gaya dan animasi Material 3 Expressive, tetapi tampilan sebelumnya terasa kurang cocok untuk aplikasi inventaris (masih terasa hijau tanaman AgroLens, toples kaca, dan tutorial pemula 3 langkah).

- **Warna dan merek (`lib/ui/palette.dart`, `lib/core/appearance.dart`):** bawaan kembali ke **Navy Scitech (`#0F2C59`)** menyesuaikan `Logo.png`, dengan kanvas slate sejuk (`#F5F7FB`), kontainer sekunder biru langit (`#D2E4FF`), dan mode gelap slate-navy (`#0E131B`). Tujuh palet ekspresif tetap tersedia dengan nama inventaris/studio: Navy Scitech, Kobalt, Zamrud (hijau tangan), Koral, Amber, Violet, Magenta. Gradien foto di Beranda & Katalog diganti slate gelap (`0xD90A101B`), label pilihan memakai `primaryFixed` tema.
- **Peti peralatan (`lib/production/home/inventory_jar.dart`, `queue_hero.dart`):** toples kaca AgroLens diganti peti perangkat keras (`CrateFramePainter`: pegangan atas, dua kait tutup, garis skala rak, pelindung sudut) dengan fisika `BallPit` tetap sama, dipakai bersama di login, Beranda, dan antrean admin.
- **Beranda peminjam (`lib/production/home/`):** tutorial 3 langkah dihapus. Hero kini 2 halaman langsung operasional: halaman 0 langsung menampilkan stok siap + peti bola kategori yang bisa dimainkan (`Buka katalog`); halaman 1 menampilkan status pinjaman aktif atau alur cepat + ilustrasi garis tergambar. `HomeHeader` menyapa nama depan pengguna.
- **Identitas aset (`item_row.dart`, `item_details.dart`, `inventory_admin.dart`):** setiap baris katalog menampilkan lencana kode ID monospace (`C3A9`) + titik status stok, dan daftar barang admin menampilkan ID pendek di meta. Detail barang tanpa foto mendapat lapisan bentuk lembut di latar.
- **Kepadatan form (`text_field.dart`, `text_field_header.dart`, `auth_views.dart`):** isian `ExpressiveTextField` satu baris dirapatkan (lencana 32, padding lebih ringkas) agar layar daftar/sandi lebih seimbang; teks sisa `"TPI"` di daftar dihapus; catatan bantu singkat ditambahkan pada layar satu isian (OTP/lupa sandi).
- **Verifikasi:** `flutter analyze` 0 issue; `flutter test` 36/36 lulus. APK profile di Redroid `emulator-5554`: screenshot diverifikasi untuk login OTP, mode kata sandi, daftar akun, Beranda, Katalog, Pinjaman, Akun, Ringkasan admin, dan Barang dalam tema Navy Scitech tanpa overflow.

## V7.1 · auth dirombak ulang + foto barang (2026-11-13, berlaku)

Koreksi pengguna: "overall Material 3 Expressive-nya sudah bagus, yang kurang banget login, sign in, dan forgot; sisanya dipoles; admin bisa upload foto barang dan tampil? Fokus mobile."

- **Masalah V7 di layar auth:** panel putih besar yang sebagian besar kosong (bola di dasar), baris chip + petunjuk, judul dan form terdorong ke bawah. Terasa seperti onboarding, bukan layar masuk.
- **V7.1:** setiap langkah auth memakai satu kartu hero berwarna seperti kartu cerita Beranda (radius 34, bentuk lembut berputar, chip langkah, judul WordReveal, titik langkah di dalam kartu) dengan seni interaktif di kanan: toples bola kategori (login), amplop yang berubah jadi centang saat 6 digit lengkap (kode), kunci yang bisa diputar (lupa sandi), gembok yang menutup saat sandi valid (sandi baru), kartu ID dengan bentuk yang bisa ditarik (daftar). Form di bawah kartu; bar bawah berisi tombol utama 56 + tautan Daftar/Masuk. Tinggi hero ±200–230 px di 390×844, sehingga login OTP muat tanpa gulir. Toples dipisah jadi `home/inventory_jar.dart` (`InventoryCrate`) dan dipakai Beranda juga.
- **Validasi:** email kosong kini "Masukkan email kantor Anda.", isian wajib kosong "Wajib diisi." (sebelumnya "Isi minimal 1 karakter.").
- **Foto barang:** alur yang sudah ada (pilih dari galeri → kompres ≤2 MB → `POST /api/images` multipart `bucket=item-images` → `image_id` disimpan di barang → `GET /api/images/<id>` dengan token sesi) kini punya tes regresi `test/item_photo_test.dart`. Foto memudar masuk di atas latar tonal saat dimuat.
- **Verifikasi:** analyze 0 issue, 36/36 tes. APK profile di Redroid (720×1600): login OTP, kata sandi, lupa sandi → kode → sandi baru, daftar; admin memilih foto dari galeri untuk dua barang dan menyimpan (log mock: upload 67 KB, PATCH dengan image); foto tampil di daftar admin, Beranda, Katalog, carousel Pilihan, dan detail barang peminjam. Keterbatasan Redroid: inset keyboard tidak dilaporkan ke Flutter, jadi bar bawah tertutup keyboard di emulator ini; perilaku keyboard dicakup tes widget 360×640 + inset 280.

## V7 · rombak total ke style plantify3 (2026-11-13, berlaku)

Permintaan: "revamp UI-nya agar style-nya benar-benar seperti plantify3, buang UI yang lama: login, lupa password, dll., pokoknya semua menu." Kontrak per layar di [`../../DESIGN.md`](../../DESIGN.md).

- **Fondasi:** tipografi dan tombol dikembalikan ke angka plantify3 (headlineMedium 28/w700, titleLarge 22/w600, tombol 52, label 15). Ukuran 32/40 dari iterasi sebelumnya membuat pill header turun ke bawah judul dan ring detail jatuh ke bawah, jadi dibatalkan. `ExpressiveTextField` (kartu editor plantify3) diport ke `lib/ui/controls` dengan tambahan email/sandi/autofill/trailing; isian sandi tidak pernah menampilkan huruf di jejak bentuk. Komponen lama dihapus: `AssetTag`, `UnitMeter`, `LedgerGroup`, `SegmentedTabs`, `FormDialog`, `LoanRow/LoanCard` + kolom register.
- **Auth** (pola onboarding): bar merek, bentuk panggung 340 yang morph per langkah, rak bola kategori (BallPit) di login, judul WordReveal, isian editor card, indikator langkah bentuk + pill aksi di bawah. Login OTP, daftar, lupa sandi jadi alur bertahap. OTP: sel bentuk yang morph jadi lingkaran saat terisi. Pembaruan app memakai pola layar hasil.
- **Katalog** = Pustaka, **detail barang** = layar hasil (header 42 %, kartu vonis −44, ring di kanan, action bar), **pengajuan** = editor artikel, **Pinjaman** = Riwayat (grup per hari, empty state bentuk yang bisa ditarik), **Akun** = Pengaturan, **Edit profil** = editor. Admin: **Barang/Pengadaan/Pengguna** = Kelola artikel (aksi bentuk 38, FAB "Barang baru"), **editor barang** jadi halaman penuh ala editor artikel, statistik dalam `GroupCard`. Form prompt = sheet editor; konfirmasi = dialog hapus plantify3.
- **Perubahan perilaku:** ganti kata sandi pindah ke Edit profil; kontras + warna dinamis pindah ke Akun; FAB admin ponsel mengambang di overlay.
- **Verifikasi:** `flutter analyze` 0 issue; `flutter test` 35/35, ditambah 9 smoke sementara (auth/peminjam/admin di 360×640 teks 2×, 390×844, 1280×900; dihapus setelah lulus) yang menemukan overflow header "Pinjaman terakhir" di 2×. Tes baru: `expressive_text_field_test.dart` (sandi tidak bocor, validator + label semantik). Build web release + fixture `/tmp/sims-harness/server.py` dilihat di Chromium 390×844: login (OTP, kata sandi), lupa sandi → kode pemulihan, daftar, Beranda, Katalog, detail, pengajuan, Pinjaman, Akun, Ringkasan admin, Barang, editor barang, Pinjaman admin, sheet Lainnya, Statistik, Barang mode gelap, dan Barang 1280×860. Temuan dari cek ini yang sudah diperbaiki: label pilihan Pinjaman/periode Statistik terpotong (kini badge di atas label), "Kembalikan" patah kata, pill nilai `GroupCard` turun ke bawah judul, chip hero admin terpotong, dan kartu kustom (`PillAction`, `SurfaceCard`, `HeroCard`, `LinkTile`, kartu pinjaman, FAB, baris donut) tidak terbaca sebagai tombol oleh pembaca layar web; kartu toggle kini satu node switch. APK belum diuji ulang.

## V6.1 · mengikuti AgroLens (2026-11-13, berlaku)

Koreksi pengguna atas V6: "masih ga sama, rombak agar UI-nya benar-benar mirip plantify3". Pilihan pengguna: warna persis AgroLens dan tab Beranda untuk peminjam. Detail di [`../../DESIGN.md`](../../DESIGN.md).

### Tombol, kartu, dan tipografi expressive (2026-11-13)

- Koreksi pengguna: komponen juga harus mengikuti plantify3, termasuk haptic dan teks besar. Tombol utama kini minimum 56 dp, label 17/w700; judul halaman 32/w800 dan hero 32–40. Judul utama serta nama barang membungkus penuh; hero menyusun artwork di bawah copy saat sempit/teks besar, rak horizontal mengikuti tinggi konten.
- `lib/ui/button_feedback.dart` mempertahankan gesture/fokus/keyboard tombol Material: konten mengempis saat state pressed dan kembali memakai pegas bouncy, outline morph tetap dari tema. Haptic ringan saat pressed hanya mengakui sentuhan. `tactileTap` untuk kartu/aksi InkWell kustom memberi haptic setelah tap diterima; disabled dan scroll batal tidak menjalankan aksi.
- `SurfaceCard`, `ItemRow`, `LinkTile`, dan `PillAction`: bentuk/sudut berubah dan warna tonal merespons tekanan, lalu memantul kembali. Kartu pasif tidak ikut menjadi tombol. Header grup dan judul item diperbesar, status dan aksi menyesuaikan ruang.
- Verifikasi kode: analyzer bersih. 19 tes terarah (feedback baru, morph, auth, alur admin/peminjam) lulus setelah perbaikan reduced-motion hero; 6 smoke sementara peminjam/admin pada 360×640 teks 2×, 390×844, dan 1280×900 lulus lalu dihapus. Haptic diuji melalui platform-channel, bukan getaran fisik; tidak ada perangkat ADB terhubung pada sesi ini.
- Regresi yang ditemukan: `AnimatedSize` berdurasi nol mencoba layout ulang saat ukuran hero berubah; reduced motion kini langsung membangun konten tanpa `AnimatedSize`. Tes alur aplikasi yang sudah ada mencakup jalur ini.

- **Warna:** palet Daun AgroLens jadi bawaan (hijau `#1E6B47`, lime `#D7F2A4`, kanvas `#F7FAF4`). Pilihan lain: Tomat, Jagung, Terong, Buah naga, Telang, dan Navy Scitech. Mode tema bawaan mengikuti sistem. Pilihan skema lama tidak dipakai lagi; pengguna mulai dari Daun.
- **Beranda peminjam** (port `home_tab.dart`): header logo + sapaan, carousel hero 4 halaman (3 langkah dengan ilustrasi garis yang digambar, lalu rak berisi bola kategori fisika `BallPit`), Pinjaman terakhir, carousel kartu kategori, Tersedia sekarang.
- **Katalog** (port Pustaka): search, chip kategori, carousel Pilihan, daftar `ItemRow`. Detail barang meniru layar hasil AgroLens. **Pinjaman** (port Riwayat): kartu hitungan, grup per hari, baris riwayat. **Akun** (port Pengaturan): grup Profil, Palet warna, Tema, tautan. **Admin**: Ringkasan dengan header Beranda dan hero antrean; halaman lain memakai header Pustaka/Riwayat.
- **Gerak (koreksi 2026-11-13: "animasi-animasinya mana, justru itu yang penting"):** splash merek AgroLens (lingkaran putih memantul jadi cookie + logo, lalu memudar ke layar pertama); setiap pindah tab konten naik dengan pegas; judul halaman muncul per kata (`WordReveal`); bagian halaman muncul berurutan (`Reveal`); kartu hero berputar pelan di latar (`Ambient`) dan miring saat disentuh (`TiltOnTouch`); kartu grup miring; bentuk di hero login mengambang dan bisa ditarik; operasi berhasil (setujui, serah terima, pengembalian, konfirmasi kembali, pengadaan, simpan barang/profil) memunculkan semburan bentuk dari titik ketuk. Sudah ada sebelumnya dan terbukti di rekaman: ilustrasi hero tergambar, rak bola kategori berfisika, huruf pencarian melompat, dock yang melebar/morph + semburan, palet dengan semburan. Rekaman Android: `screenshots/agrolens-motion/*.mp4` (+ lembar frame `*_sheet.png`).
- **Verifikasi gerak:** APK profile di emulator Android 8.1 (720×1600, skala animasi 1×), direkam dengan `screenrecord`: splash, login → Beranda, Lewati → rak bola, ketik pencarian, pilih palet. Frame per frame dicek. FPS tidak diukur.
- **Verifikasi (2026-11-13):** `flutter analyze` 0 issue, 28/28 tes; tes sementara peminjam & admin 360×640 (teks 1× dan 2×) dan 1280 lebar dengan pindah tab tanpa error (dihapus); build web + fixture dilihat di 390×844 (login, Beranda, Katalog, Pinjaman, Akun, Ringkasan admin). APK belum diuji.

---

## V6 · arah AgroLens Material 3 Expressive (2026-11-12, superseded oleh V6.1)

Permintaan: rombak besar UI dan penempatan mengikuti panduan `~/Downloads/Material3-Design-Systems` ("tidak harus diikuti semuanya, arahnya kurang lebih begitu"). Rincian keputusan ada di [`../../DESIGN.md`](../../DESIGN.md). Endpoint, skema database, autentikasi, hak akses, dan data tidak berubah.

- **Fondasi:** Poppins 400–800 (Roboto Flex dihapus); tema dengan tipografi berat untuk judul, input terisi tanpa garis, chip 8→16, sheet/dialog 28. Kontrol AgroLens diport ke `lib/ui/controls.dart` (dock, search, filter chip, button group), plus `motion.dart`, `physics.dart` (`ShapeBurst`), `widgets.dart` (`Reveal`). `BrandHeader` diganti `HeroCard`; baru `GroupCard`, `LinkGroup/LinkTile`; `StatusPill` kini membawa badge berbentuk.
- **Penempatan:** ponsel memakai dock ekspresif untuk semua peran (admin: Ringkasan, Barang, Pinjaman, Lainnya); drawer dan tombol Menu dihapus. Judul halaman 34 w800 di kanvas dengan aksi cakram tonal; satu `HeroCard` per layar (Katalog: pinjaman terdekat atau ajakan meminjam; Pinjaman: tenggat; Ringkasan admin: antrean persetujuan; Statistik: pinjaman terbuka; Akun: profil). Filter berangka memakai kartu hitungan ala Riwayat AgroLens.
- **Login:** tab OTP/Kata sandi dalam satu layar; tombol "Masuk dengan kode OTP" terpisah dihapus.
- **Verifikasi (2026-11-12):**
  - `flutter analyze --no-pub`: 0 issue. `flutter test --no-pub`: 28/28 lulus.
  - Tes sementara para subagen (dihapus): 360×640 dengan teks 2× untuk auth, katalog → pengajuan → sukses, pinjaman/akun/pengaturan, dan admin ponsel/tablet/lebar tanpa overflow.
  - Build web release + fixture `/tmp/sims-harness/server.py` (di luar repo, data contoh) di Chromium headless 390×844: login kata sandi, Katalog, Pinjaman, Akun, Tema (pindah ke Teal dan Gelap), admin Ringkasan, sheet Lainnya, Statistik; serta Statistik di 1440×900. Grup Kontras yang terpotong ("Stan…") diganti `SegmentedTabs` setelah cek ini; build web belum diulang sesudah perbaikan itu.
  - Belum diuji: APK di perangkat/emulator, keyboard native, kamera, warna dinamis.

---

## V5 · Material 3 Expressive (2026-11-07, superseded oleh V6)

Tampilan mengikuti rancangan FigCraft `SIMS-Scitech-UI-Redesign.figcraft`, halaman "SIMS Scitech · V5". Rinciannya ada di [`../../DESIGN.md`](../../DESIGN.md). Versi ini menggantikan revamp "register TPI" di bawah. Endpoint, skema database, autentikasi, hak akses, dan data tidak berubah.

- **Default dominan putih:** hero biru sangat muda dan permukaan putih. Skema Teal, Ungu, Hijau, Beri, serta mode gelap memakai hero berwarna penuh.
- **Komponen baru:**
  - bentuk M3E sebagai penanda kategori,
  - daftar bersegmen dan grup tombol terhubung,
  - progres bergelombang,
  - ID chip dan meter unit berbentuk pil,
  - pegas skema ekspresif.
- **Halaman baru:**
  - **Edit profil:** 8 avatar ilustrasi atau foto kamera/galeri, ditambah pilihan bentuk bingkai. Disimpan di perangkat per akun.
  - **Tema & tampilan:** mode, warna dinamis Android 12+, 5 skema, dan kontras.
  - **Pengaturan:** ukuran teks, kurangi gerak, default pesan WhatsApp, dan pembaruan aplikasi.
- **Verifikasi:**
  - `flutter analyze`: 0 issue. `flutter test`: 24/24 lulus.
  - Build web release dengan fixture lokal, diperiksa di 390×844 dan 1440×900: login, katalog, detail, pengajuan, pinjaman, akun, tema Teal dan Gelap, antrean admin ponsel dan desktop, daftar Barang.
  - APK debug di Redroid Android 8.1 (720×1600): katalog tampil dengan font bundel, logcat tanpa overflow atau error Flutter. Keyboard, kamera, dan warna dinamis belum diuji di perangkat nyata.
  - Screenshot ada di `screenshots/m3e-v5/`.

---

## Revamp UI inventaris TPI (superseded oleh V5)

Bagian ini menjelaskan tampilan sebelumnya untuk Android dan build web `/app/`. Revamp ini tidak menambah endpoint, tidak mengubah skema database, dan tidak mengubah alur autentikasi, hak akses, atau data.

## Arah tampilan

Permintaan pengguna: tampilan lebih tegas untuk perusahaan TPI tetapi tetap stylish, dengan filter antislop (mode *during* untuk sesi ini). Aplikasi ini alat kerja: staf mencari barang dan mengajukan pinjaman, admin memutuskan permintaan dan menjaga stok. Desain dibaca sebagai register inventaris operasional, dial ENERGY 2 / RHYTHM 2 / MOTION 1.

| Keputusan | Alasan |
|---|---|
| Navy `#0F2C59` untuk rail, masthead ponsel, dan aksi utama | Warna logo Scitech yang tersedia di repo; tidak ada logo TPI yang dibuat |
| Latar terang sejuk `#F2F4F7`, register putih bergaris tipis | Daftar panjang terbaca lebih mudah daripada kartu besar per record |
| Radius 4 / 6 / 8 / 12 | Bentuk terkendali; menggantikan label koper berlubang dan sudut 14 / 20 yang terasa membulat |
| Pelat ID persegi dari `shortId(record.id)` | ID tetap berasal dari data nyata, tanpa ornamen label |
| Status selalu berteks; oranye hanya untuk menunggu dan tenggat | Status tidak bergantung pada warna |
| Gerak hanya umpan balik dan transisi | Label gantung yang dapat diayun dan kemunculan berurutan dihapus |
| Target sentuh 48 dp, outline fokus pada tombol dan input | Kebutuhan Android dan keyboard |

## Perubahan per area

**Autentikasi.** Label merek gantung dihapus. Ponsel memakai masthead navy ringkas berisi logo dan "Inventaris TPI", lalu formulir dalam satu area gulir. Desktop memakai panel identitas statis dan kolom formulir. Kode OTP / Kata sandi kini satu pengalih (tautan ganda dihapus). Input OTP terlihat, bisa ditempel, dan menerima autofill. Dialog formulir menggulir sebagai satu kesatuan termasuk tombol aksi.

**Navigasi.** Rail navy 264 px mulai 900 px. Ponsel peminjam memakai navigasi bawah; ponsel admin memakai tombol berlabel "Menu" yang membuka drawer. Judul halaman ponsel berada di permukaan terang di bawah masthead, bukan di blok navy dengan kartu menimpa.

**Katalog, detail, pengajuan.** Desktop menampilkan register dengan kolom Barang / ID, Kategori, Tersedia / Total, Status. Ponsel menampilkan baris barang dengan ikon, ID, stok, dan status; kategori menjadi satu baris yang dapat digeser. Detail barang menampilkan angka siap / total / dipakai rekan dan meter unit, lalu satu aksi. Formulir pengajuan dikelompokkan menjadi "Jumlah & jadwal" serta "Keperluan & komunikasi". Tombol kirim ikut menggulir agar tetap terjangkau saat keyboard dan teks besar. Bukti pengajuan berbentuk ringkasan baris.

**Admin.** Ringkasan memakai strip status yang juga memfilter antrean, master-detail di layar lebar, dan sheet di ponsel. Petunjuk geser untuk menyetujui hanya tampil di ponsel. Barang, Pinjaman, Riwayat, Pengguna, dan Pengadaan memakai register berkolom sejajar dengan aksi ikon bertooltip. Statistik mempertahankan perhitungan dan grafik custom, dengan bilah angka ringkas, judul grafik yang menyebut periodenya, dan legenda berteks. Akun berisi profil dan daftar aksi.

## Screenshot

Rendering aplikasi, bukan mockup. Data berasal dari fixture lokal di luar repo (akun `example.com`, barang dan pinjaman berlabel data contoh), bukan data operasi.

### Sebelum (v5)

| Login desktop | Login ponsel 360×640 | Admin desktop | Android |
|---|---|---|---|
| ![](screenshots/tpi-revamp/before-login-desktop.webp) | <img src="screenshots/tpi-revamp/before-login-phone.png" width="200"> | ![](screenshots/tpi-revamp/before-admin-desktop.webp) | <img src="screenshots/tpi-revamp/before-android.png" width="200"> |

Riwayat v5 lengkap tetap ada di `screenshots/ui-redesign/`.

### Sesudah, browser

| Login desktop 1440 | Login ponsel 360×640 |
|---|---|
| ![](screenshots/tpi-revamp/after-login-desktop.png) | <img src="screenshots/tpi-revamp/after-login-phone.png" width="240"> |

![Katalog desktop](screenshots/tpi-revamp/after-catalog-desktop.png)

| Katalog ponsel | Detail ponsel | Formulir saat keyboard (viewport 360×340) |
|---|---|---|
| <img src="screenshots/tpi-revamp/after-catalog-phone.png" width="220"> | <img src="screenshots/tpi-revamp/after-item-detail-phone.png" width="220"> | <img src="screenshots/tpi-revamp/after-request-keyboard-phone.png" width="220"> |

| Formulir pengajuan desktop | Bukti pengajuan | Pinjaman peminjam |
|---|---|---|
| ![](screenshots/tpi-revamp/after-request-form-desktop.png) | ![](screenshots/tpi-revamp/after-request-success-desktop.png) | ![](screenshots/tpi-revamp/after-borrower-loans-desktop.png) |

![Ringkasan admin desktop](screenshots/tpi-revamp/after-admin-dashboard-desktop.png)

| Ringkasan admin ponsel | Drawer | Sheet permintaan | Dialog catatan |
|---|---|---|---|
| <img src="screenshots/tpi-revamp/after-admin-dashboard-phone.png" width="190"> | <img src="screenshots/tpi-revamp/after-admin-drawer-phone.png" width="190"> | <img src="screenshots/tpi-revamp/after-admin-request-sheet-phone.png" width="190"> | <img src="screenshots/tpi-revamp/after-form-dialog-phone.png" width="190"> |

![Statistik](screenshots/tpi-revamp/after-admin-stats-desktop.png)
![Barang](screenshots/tpi-revamp/after-admin-items-desktop.png)
![Pinjaman admin](screenshots/tpi-revamp/after-admin-loans-desktop.png)
![Pengadaan](screenshots/tpi-revamp/after-admin-procurement-desktop.png)
![Pengguna](screenshots/tpi-revamp/after-admin-users-desktop.png)
![Akun](screenshots/tpi-revamp/after-admin-account-desktop.png)

| Gagal memuat (data terakhir tetap tampil) | Inventaris kosong |
|---|---|
| ![](screenshots/tpi-revamp/after-error-state-desktop.png) | ![](screenshots/tpi-revamp/after-empty-state-desktop.png) |

### Sesudah, Android

Debug APK di Redroid Android 8.1, terhubung ke fixture lewat `adb reverse`. Layar diukur pada 720×1280 density 320 (360×640 dp) dan pada ukuran asli 720×1600 density 280 dengan `font_scale 2.0`.

| Login 360×640 | Katalog 360×640 | Pinjaman 360×640 |
|---|---|---|
| <img src="screenshots/tpi-revamp/after-android-login.png" width="200"> | <img src="screenshots/tpi-revamp/after-android-catalog.png" width="200"> | <img src="screenshots/tpi-revamp/after-android-loans.png" width="200"> |

| Login teks 2× | Katalog teks 2× | Pinjaman teks 2× |
|---|---|---|
| <img src="screenshots/tpi-revamp/after-android-login-2x.png" width="200"> | <img src="screenshots/tpi-revamp/after-android-catalog-2x.png" width="200"> | <img src="screenshots/tpi-revamp/after-android-loans-2x.png" width="200"> |

## Pemeriksaan yang dijalankan

| Pemeriksaan | Hasil |
|---|---|
| `flutter analyze --no-pub` | Tidak ada masalah |
| `flutter test --no-pub` | 24/24 lulus, termasuk regresi auth 360×640 dengan inset keyboard pada teks 2× |
| `flutter build web --release --base-href=/ --no-web-resources-cdn` | Berhasil |
| `flutter build apk --debug` | Berhasil; dipasang dan dijalankan di Redroid |
| Browser desktop 1440 | Login peminjam dan admin, validasi field kosong, katalog, detail, validasi keperluan kosong, kirim pengajuan (POST tercatat di fixture), pinjaman, keluar via dialog, ringkasan admin, setujui (PATCH `approve` tercatat), statistik, barang, pinjaman, pengadaan, pengguna, akun, state gagal dengan "Coba lagi", state kosong |
| Browser ponsel 360×640 | Login, katalog, detail sheet, formulir saat viewport dipendekkan seperti keyboard, admin: masthead "Menu", drawer (tutup dengan Escape), sheet permintaan, tolak lewat dialog catatan (PATCH `reject` tercatat). `scrollWidth` = 360, tidak ada geser horizontal |
| Android | Login kata sandi via input sentuh native, katalog, pinjaman pada 360×640 dp dan teks 2×; `SegmentedTabs` menumpuk pada 2×; logcat tanpa `RenderFlex`/overflow/exception |
| Kontras token | Ink pada latar 15,69:1; muted pada putih 6,91:1; faint pada latar 5,13:1; putih pada navy 13,77:1; teks status di latar status 4,60 sampai 5,61:1; garis kontrol `#738095` pada putih 4,00:1 (di atas 3:1 untuk komponen) |

## Batas bukti

- **Keyboard di Redroid.** Pada Redroid Android 8.1 ini, keyboard hanya dilaporkan sebagai inset `visible`; inset `content` tetap 84 px (navbar). Engine Flutter untuk API di bawah 30 membaca keyboard dari `systemWindowInsetBottom`, sehingga menerima tinggi keyboard 0. Field yang tertutup keyboard tidak tergulir otomatis di lingkungan ini ([bukti](screenshots/tpi-revamp/after-android-password-keyboard-2x.png)). Aplikasi native Messaging di perangkat yang sama tetap menyesuaikan tata letaknya. Pengguliran field fokus di atas keyboard terbukti di test widget dengan `viewInsets` dan simulasi viewport browser, tetapi **belum terbukti di perangkat Android nyata**. Build base `316f664` untuk pembanding gagal dibuild dengan toolchain saat ini, jadi belum dipastikan apakah perilaku ini juga terjadi sebelum revamp.
- Pengujian teks 2× di browser tidak dilakukan karena Flutter web tidak mengikuti ukuran font browser secara langsung; teks 2× diuji di Android dan di test widget.
- Backend produksi, pengiriman OTP nyata, build rilis bertanda tangan, pembaca layar, dan audit aksesibilitas menyeluruh tidak diverifikasi.
- Data screenshot adalah data contoh dari fixture lokal, bukan data operasi.
