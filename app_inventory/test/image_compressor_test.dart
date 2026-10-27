import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:app_inventory/core/image_compressor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCompressor Tests', () {
    test('formatSize formats byte sizes accurately', () {
      expect(ImageCompressor.formatSize(500), '500 B');
      expect(ImageCompressor.formatSize(1024), '1.0 KB');
      expect(ImageCompressor.formatSize(51200), '50.0 KB');
      expect(ImageCompressor.formatSize(102400), '100.0 KB');
    });

    test('Small image under 100 KB skips recompression', () async {
      final smallBytes = Uint8List(50 * 1024); // 50 KB
      final result = await ImageCompressor.compressBytes(smallBytes);
      expect(result.lengthInBytes, 50 * 1024);
      expect(identical(result, smallBytes), isTrue);
    });

    test('Invalid non-image bytes fall back gracefully', () async {
      final dummyLargeBytes = Uint8List(120 * 1024); // 120 KB non-image
      final result = await ImageCompressor.compressBytes(dummyLargeBytes);
      expect(result.lengthInBytes, 120 * 1024);
    });

    test('Large synthetic image is compressed in isolate to <= 100 KB', () async {
      // Create a 1400x1400 synthetic RGB image
      final testImage = img.Image(width: 1400, height: 1400);
      for (var y = 0; y < 1400; y++) {
        for (var x = 0; x < 1400; x++) {
          testImage.setPixelRgb(x, y, (x * 255) ~/ 1400, (y * 255) ~/ 1400, 128);
        }
      }
      final uncompressedJpg = Uint8List.fromList(img.encodeJpg(testImage, quality: 100));
      expect(uncompressedJpg.lengthInBytes, greaterThan(ImageCompressor.maxTargetBytes));

      final compressed = await ImageCompressor.compressBytes(uncompressedJpg);
      expect(compressed.lengthInBytes, lessThanOrEqualTo(ImageCompressor.maxTargetBytes));
    });
  });
}
