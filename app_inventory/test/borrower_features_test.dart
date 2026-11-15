import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_inventory/core/api.dart';
import 'package:app_inventory/core/app_state.dart';
import 'package:app_inventory/production/app.dart';
import 'package:app_inventory/services/whatsapp_service.dart';
import 'connected_app_test.dart' show MemoryVault;

void main() {
  test('WhatsApp drafts preserve the exact request without using a dummy destination', () {
    final uri = WhatsAppService.contactUri('081234567890', 'Kamera & tripod\n2 unit');
    expect(uri!.host, 'wa.me');
    expect(uri.path, '/6281234567890');
    expect(uri.queryParameters['text'], 'Kamera & tripod\n2 unit');
    expect(WhatsAppService.contactUri('', 'message'), isNull);
  });
  testWidgets('Borrower uses the catalogue, persists a request, sees WhatsApp action and colleague activity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Beranda loops ambient motion; reduced motion lets pumpAndSettle end.
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final loans = <Map<String, dynamic>>[];
    int submissions = 0;
    final item = {
      'id': 'item-1',
      'name': 'Kamera Tim',
      'category': 'Elektronik',
      'description': 'Kamera untuk dokumentasi kegiatan.',
      'quantity_total': 4,
      'quantity_available': 3,
      'is_available': true,
    };
    final api = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((request) async {
        final path = request.url.path;
        dynamic body;
        if (path.contains('/auth/session/')) {
          body = {
            'profile': {
              'user_id': 'viewer',
              'full_name': 'Peminjam Uji',
              'email': 'viewer@example.com',
              'role': 'client',
              'is_active': true,
            },
          };
        } else if (path == '/api/items/') {
          body = [item];
        } else if (path == '/api/mobile/workspace/') {
          body = {
            'admin_contacts': [
              {'id': 'admin-1', 'name': 'Admin 1', 'phone': '6288212854299'},
              {'id': 'admin-2', 'name': 'Admin 2', 'phone': '6288289375343'},
            ],
            'activity': [
              {
                'id': 'team-loan',
                'item_id': 'other-item',
                'item_name': 'Proyektor Tim',
                'borrower_name': 'Rekan Operasional',
                'department': 'Operasional',
                'quantity': 1,
                'status': 'borrowed',
                'return_date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
                'is_mine': false,
              },
            ],
          };
        } else if (path == '/api/loans/me/') {
          body = loans;
        } else if (path == '/api/loans/' && request.method == 'POST') {
          submissions++;
          final input = jsonDecode(request.body) as Map<String, dynamic>;
          expect(input['quantity'], 2);
          expect(input['purpose'], 'Meeting & Presentasi');
          final loan = {...input, 'id': 'saved-loan', 'status': 'pending', 'item': item};
          loans.add(loan);
          body = {'success': true, 'data': loan};
        } else {
          body = {};
        }
        return http.Response(jsonEncode(body), 200);
      }),
    );
    final state = AppState(api: api, vault: MemoryVault()..token = 'fixture');
    await tester.pumpWidget(ConnectedScitechApp(state: state));
    await tester.pumpAndSettle();
    // The borrower lands on Beranda; open Katalog from the rail.
    await tester.tap(find.text('Katalog').first);
    await tester.pumpAndSettle();
    // Page titles animate word by word; the title is exposed as one label.
    expect(find.bySemanticsLabel('Katalog Inventaris'), findsOneWidget);
    expect(find.text('Kamera Tim'), findsOneWidget);
    // The whole item row opens the item details page.
    await tester.ensureVisible(find.text('Kamera Tim').first);
    await tester.tap(find.text('Kamera Tim').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ajukan peminjaman').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tambah jumlah'));
    await tester.tap(find.text('3 hari'));
    await tester.tap(find.text('Meeting & Presentasi'));
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Ajukan peminjaman'));
    await tester.tap(find.widgetWithText(FilledButton, 'Ajukan peminjaman'));
    await tester.pumpAndSettle();
    expect(submissions, 1);
    expect(find.text('Menunggu persetujuan admin'), findsOneWidget);
    expect(find.text('Hubungi admin via WhatsApp'), findsOneWidget);
    await tester.ensureVisible(find.text('Lihat status pinjaman'));
    await tester.tap(find.text('Lihat status pinjaman'));
    await tester.pumpAndSettle();
    expect(find.text('Kamera Tim'), findsOneWidget);
    await tester.tap(find.text('Rekan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rekan Operasional'), findsOneWidget);
    expect(find.textContaining('Proyektor Tim'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    api.close();
    state.dispose();
  });
}
