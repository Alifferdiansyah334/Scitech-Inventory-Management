import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_inventory/core/api.dart';
import 'package:app_inventory/core/app_state.dart';
import 'package:app_inventory/core/vault.dart';
import 'package:app_inventory/production/app.dart';

class MemoryVault implements TokenVault {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

void main() {
  testWidgets(
    'Authenticated admin layout fits a narrow phone without a mode switch',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vault = MemoryVault()..token = 'admin-token';
      final api = ApiClient(
        baseUrl: 'http://localhost:3000',
        client: MockClient((request) async {
          final value = request.url.path.contains('/auth/session')
              ? {
                  'profile': {
                    'user_id': 'admin-id',
                    'full_name': 'Administrator Uji',
                    'email': 'admin@example.com',
                    'role': 'admin',
                    'is_active': true,
                  },
                }
              : [];
          return http.Response(jsonEncode(value), 200);
        }),
      );
      final state = AppState(api: api, vault: vault);
      await tester.pumpWidget(ConnectedScitechApp(state: state));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Mode Admin (Demo)'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      api.close();
      state.dispose();
    },
  );
  testWidgets(
    'Admin saves over API; borrower session reads the same server item without a mode switch',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final items = <Map<String, dynamic>>[];
      final requests = <http.Request>[];
      Map<String, dynamic> profile(bool admin) => {
        'user_id': admin ? 'admin-id' : 'borrower-id',
        'full_name': admin ? 'Admin Uji' : 'Peminjam Uji',
        'email': admin ? 'admin@example.com' : 'borrower@example.com',
        'role': admin ? 'admin' : 'client',
        'is_active': true,
      };
      final transport = MockClient((request) async {
        requests.add(request);
        final path = request.url.path.replaceFirst(RegExp(r'/+$'), '');
        dynamic data;
        if (path.endsWith('/auth/login') && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['password'] != 'ValidPass123!') {
            return http.Response(
              jsonEncode({'error': 'Email atau kata sandi tidak sesuai.'}),
              401,
            );
          }
          final admin = body['email'] == 'admin@example.com';
          data = {
            'token': admin ? 'admin-token' : 'borrower-token',
            'profile': profile(admin),
          };
        } else if (path.endsWith('/auth/login-otp')) {
          data = {'token': 'borrower-token', 'profile': profile(false)};
        } else if (path.endsWith('/auth/send-otp')) {
          data = {'success': true};
        } else if (path.endsWith('/auth/session')) {
          data = {
            'profile': profile(
              request.headers['authorization'] == 'Bearer admin-token',
            ),
          };
        } else if (path.endsWith('/items') && request.method == 'POST') {
          expect(request.headers['authorization'], 'Bearer admin-token');
          final item = jsonDecode(request.body) as Map<String, dynamic>;
          item['id'] = 'server-item';
          item['created_at'] = DateTime.now().toIso8601String();
          items.add(item);
          data = {'success': true, 'data': item};
        } else if (path.endsWith('/items')) {
          expect(request.headers['authorization'], isNotNull);
          data = items;
        } else if (path.endsWith('/mobile/workspace')) {
          data = {'activity': [], 'admin_contacts': []};
        } else if (path.endsWith('/admin/users')) {
          data = [profile(true), profile(false)];
        } else if (path.endsWith('/auth/logout')) {
          data = {'success': true};
        } else {
          data = [];
        }
        return http.Response(
          jsonEncode(data),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });
      final api = ApiClient(
        baseUrl: 'http://localhost:3000',
        client: transport,
      );
      final state = AppState(api: api, vault: MemoryVault());
      await tester.pumpWidget(ConnectedScitechApp(state: state));
      await tester.pumpAndSettle();
      expect(find.text('Mode Admin (Demo)'), findsNothing);
      await tester.tap(find.text('Masuk dengan kata sandi'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'admin@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'ValidPass123!');
      await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await tester.pumpAndSettle();
      expect(state.profile?.isAdmin, isTrue);
      await tester.tap(find.text('Barang').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Barang Integrasi',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Peralatan');
      await tester.enterText(find.byType(TextFormField).at(3), '4');
      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();
      expect(items, hasLength(1));
      expect(find.text('Barang Integrasi'), findsOneWidget);
      await tester.tap(find.byTooltip('Keluar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(state.profile, isNull);
      await tester.enterText(
        find.byType(TextFormField).first,
        'borrower@example.com',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Kirim kode OTP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Verifikasi'));
      await tester.pumpAndSettle();
      expect(state.profile?.isAdmin, isFalse);
      expect(find.text('Barang Integrasi'), findsOneWidget);
      expect(find.text('Tambah'), findsNothing);
      expect(find.text('Mode Admin (Demo)'), findsNothing);
      expect(
        requests.any(
          (request) =>
              request.url.path.contains('api/items') &&
              request.method == 'GET' &&
              request.headers['authorization'] == 'Bearer borrower-token',
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      api.close();
      state.dispose();
    },
  );

  test('Rejected login never creates a profile or saves a token', () async {
    final vault = MemoryVault();
    final api = ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'error': 'Login ditolak.'}), 401),
      ),
    );
    final state = AppState(api: api, vault: vault);
    await expectLater(
      state.authenticate({
        'email': 'admin@example.com',
        'password': 'wrong-pass',
      }),
      throwsA(isA<ApiException>()),
    );
    expect(state.profile, isNull);
    expect(vault.token, isNull);
    expect(api.token, isNull);
    api.close();
    state.dispose();
  });
  test(
    'Registration requires verification and does not create a fake signed-in session',
    () async {
      final vault = MemoryVault();
      final api = ApiClient(
        baseUrl: 'http://localhost:3000',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'success': true, 'verification_required': true}),
            200,
          ),
        ),
      );
      final state = AppState(api: api, vault: vault);
      await state.registerAccount({
        'email': 'user@example.com',
        'password': 'ValidPass123!',
        'full_name': 'Pengguna Uji',
      });
      expect(state.profile, isNull);
      expect(vault.token, isNull);
      api.close();
      state.dispose();
    },
  );
}
