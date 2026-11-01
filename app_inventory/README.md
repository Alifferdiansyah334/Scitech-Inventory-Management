# Aplikasi Flutter SAMS

lib/main.dart menjalankan lib/production. Katalog, transaksi, akun dan hak akses berasal dari API. Halaman demo lama tidak menjadi entrypoint produksi.

Pengembangan dengan API lokal port 3000:

    flutter run -d chrome --web-port=5173 --no-web-resources-cdn

Rilis untuk Vercel:

    flutter build web --release --base-href=/app/ --no-web-resources-cdn

Rilis browser memakai API pada origin yang sama. Build native memerlukan alamat HTTPS API melalui --dart-define=API_URL=.... CanvasKit dibundel lokal melalui web/flutter_bootstrap.js.

Verifikasi: flutter test dan flutter analyze --no-pub.
