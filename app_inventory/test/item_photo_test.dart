import 'dart:convert';
import 'package:app_inventory/core/api.dart';
import 'package:app_inventory/core/app_state.dart';
import 'package:app_inventory/production/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connected_app_test.dart' show MemoryVault;

/// Gallery that hands back one real JPEG.
class _Gallery extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      XFile.fromData(img.encodeJpg(img.Image(width: 64, height: 48)), name: 'kamera.jpg', mimeType: 'image/jpeg');
}

void main() {
  testWidgets('Admin adds a photo to an item; the list shows it from the image endpoint', (tester) async {
    SharedPreferences.setMockInitialValues({});
    ImagePickerPlatform.instance = _Gallery();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final item = <String, dynamic>{
      'id': 'item-1',
      'name': 'Kamera Tim',
      'category': 'Kamera',
      'quantity_total': 2,
      'quantity_available': 2,
      'is_available': true,
    };
    final uploads = <String>[];
    final api = ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient((request) async {
        final path = request.url.path.replaceFirst(RegExp(r'/+$'), '');
        dynamic data;
        if (path.endsWith('/auth/session')) {
          data = {
            'profile': {
              'user_id': 'a',
              'full_name': 'Admin Uji',
              'email': 'admin@example.com',
              'role': 'admin',
              'is_active': true,
            },
          };
        } else if (path.endsWith('/api/images') && request.method == 'POST') {
          expect(request.headers['authorization'], 'Bearer admin-token');
          expect(request.headers['content-type'], startsWith('multipart/form-data'));
          final body = latin1.decode(request.bodyBytes);
          expect(body, contains('item-images'));
          uploads.add('file-1');
          return http.Response(jsonEncode({'fileId': 'file-1'}), 201);
        } else if (path.endsWith('/api/items/item-1') && request.method == 'PATCH') {
          final input = jsonDecode(request.body) as Map<String, dynamic>;
          item
            ..addAll(input)
            ..['image_url'] = '/api/images/${input['image_id']}?bucket=item-images';
          data = {'success': true, 'data': item};
        } else if (path.endsWith('/api/items')) {
          data = [item];
        } else if (path.endsWith('/mobile/workspace')) {
          data = {'activity': [], 'admin_contacts': []};
        } else {
          data = [];
        }
        return http.Response(jsonEncode(data), 200);
      }),
    );
    final state = AppState(api: api, vault: MemoryVault()..token = 'admin-token');
    await tester.pumpWidget(ConnectedScitechApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Barang').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Ubah')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('Pilih foto barang')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan barang'));
    await tester.tap(find.text('Simpan barang'));
    await tester.pumpAndSettle();

    expect(uploads, ['file-1'], reason: 'the picked photo is uploaded once');
    expect(item['image_id'], 'file-1', reason: 'the item is saved with the uploaded photo');
    // Photos decode at their shown size, so the network image may be wrapped
    // in a ResizeImage.
    final shown = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => i.image is ResizeImage ? (i.image as ResizeImage).imageProvider : i.image)
        .whereType<NetworkImage>();
    expect(
      shown.where(
        (p) =>
            p.url == 'http://localhost:3000/api/images/file-1?bucket=item-images' &&
            p.headers?['Authorization'] == 'Bearer admin-token',
      ),
      isNotEmpty,
      reason: 'the list loads the photo from the image endpoint with the session token',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    state.dispose();
    api.close();
  });
}
