import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Utility otomatis untuk mengompres gambar hingga ukurannya < 100 KB
/// Memastikan beban transfer jaringan dan penyimpanan Supabase sangat ringan, cepat, dan hemat kuota.
/// Dijalankan di background Isolate via `compute()` agar Main UI Isolate tetap 60/120 FPS tanpa frame drop/freeze.
class ImageCompressor {
  ImageCompressor._();

  static const int maxTargetBytes = 100 * 1024; // 100 KB

  /// Mengompres `Uint8List bytes` secara otomatis agar ukurannya di bawah 100 KB.
  /// Menjalankan kompresi berat (decode, resize, iterative encode) di background isolate.
  static Future<Uint8List> compressBytes(Uint8List rawBytes) async {
    // Jika ukuran awal sudah di bawah 100 KB, tidak perlu kompresi ulang atau spawn isolate
    if (rawBytes.lengthInBytes <= maxTargetBytes) {
      return rawBytes;
    }

    try {
      return await compute(_isolateCompress, rawBytes);
    } catch (e) {
      debugPrint(
        'Isolate image compression error: $e. Fallback ke gambar asli.',
      );
      return rawBytes;
    }
  }

  /// Worker function yang dieksekusi di background thread isolate
  static Uint8List _isolateCompress(Uint8List rawBytes) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return rawBytes;

      // 1. Resize proporsional jika dimensi terlalu besar (> 1024px)
      img.Image processed = decoded;
      final maxDim = processed.width > processed.height
          ? processed.width
          : processed.height;
      if (maxDim > 1024) {
        final scale = 1024 / maxDim;
        final targetW = (processed.width * scale).round();
        final targetH = (processed.height * scale).round();
        processed = img.copyResize(
          processed,
          width: targetW,
          height: targetH,
          interpolation: img.Interpolation.linear,
        );
      }

      // 2. Progressive quality compression loop (80 -> 65 -> 50 -> 40 -> 30 -> 20)
      final qualitySteps = [80, 65, 50, 40, 30, 20];
      Uint8List compressed = rawBytes;

      for (final q in qualitySteps) {
        final encoded = img.encodeJpg(processed, quality: q);
        compressed = Uint8List.fromList(encoded);
        if (compressed.lengthInBytes <= maxTargetBytes) {
          return compressed;
        }
      }

      // 3. Jika masih di atas 100 KB, perkecil resolusi lebih lanjut (width: 640px)
      if (compressed.lengthInBytes > maxTargetBytes) {
        final smaller = img.copyResize(processed, width: 640);
        final encoded = img.encodeJpg(smaller, quality: 35);
        return Uint8List.fromList(encoded);
      }

      return compressed;
    } catch (_) {
      // Fallback jika format tidak dapat didecode
      return rawBytes;
    }
  }

  /// Format ukuran bytes menjadi teks ramah pengguna (cth: "84.2 KB")
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(1)} KB';
  }
}
