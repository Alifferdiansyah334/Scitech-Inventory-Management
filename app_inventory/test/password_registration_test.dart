import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_inventory/core/api.dart';
import 'package:app_inventory/core/app_state.dart';
import 'package:app_inventory/core/password_policy.dart';
import 'package:app_inventory/production/app.dart';
import 'connected_app_test.dart' show MemoryVault;

void main() {
  test('Password rules and strength agree at the required boundaries', () {
    for (final value in [
      'Aa1!aaa',
      'lowercase1!',
      'UPPERCASE1!',
      'NoNumbers!',
      'NoSymbol123',
      'Aa1 aaaa',
    ]) {
      expect(PasswordPolicy(value).valid, isFalse);
      expect(PasswordPolicy(value).strength, 'Lemah');
    }
    expect(const PasswordPolicy('Aa1!aaaa').valid, isTrue);
    expect(const PasswordPolicy('Aa1!aaaa').strength, 'Sedang');
    expect(const PasswordPolicy('BetterPassword123!').strength, 'Kuat');
  });
  testWidgets(
    'Registration shows live strength, blocks weak passwords, and reaches OTP through API',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int submissions = 0;
      final api = ApiClient(
        baseUrl: 'https://api.example.com',
        client: MockClient((request) async {
          if (request.url.path.contains('/register/')) {
            submissions++;
            final body = jsonDecode(request.body);
            expect(body['password'], 'BetterPassword123!');
            expect(body.containsKey('role'), isFalse);
            return http.Response(
              jsonEncode({'success': true, 'verification_required': true}),
              200,
            );
          }
          return http.Response('{}', 401);
        }),
      );
      final state = AppState(api: api, vault: MemoryVault());
      await tester.pumpWidget(ConnectedScitechApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Belum punya akun? Daftar'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Pengguna Uji');
      await tester.enterText(fields.at(1), 'user@example.com');
      await tester.enterText(fields.at(4), 'lowercase');
      await tester.pump();
      expect(find.text('Kekuatan kata sandi: Lemah'), findsOneWidget);
      await tester.ensureVisible(find.text('Daftar dan verifikasi'));
      await tester.tap(find.text('Daftar dan verifikasi'));
      await tester.pumpAndSettle();
      expect(submissions, 0);
      await tester.enterText(fields.at(4), 'Aa1!aaaa');
      await tester.pump();
      expect(find.text('Kekuatan kata sandi: Sedang'), findsOneWidget);
      await tester.enterText(fields.at(4), 'BetterPassword123!');
      await tester.pump();
      expect(find.text('Kekuatan kata sandi: Kuat'), findsOneWidget);
      await tester.ensureVisible(find.text('Daftar dan verifikasi'));
      await tester.tap(find.text('Daftar dan verifikasi'));
      await tester.pumpAndSettle();
      expect(submissions, 1);
      expect(find.text('Verifikasi email'), findsOneWidget);
      expect(state.profile, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      api.close();
      state.dispose();
    },
  );
  test(
    'Unavailable server is described without incorrectly blaming internet',
    () async {
      final api = ApiClient(
        baseUrl: 'https://api.example.com',
        client: MockClient(
          (request) async => throw http.ClientException('offline'),
        ),
      );
      await expectLater(
        api.request('api/mobile/auth/register', method: 'POST', data: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('server aplikasi'),
          ),
        ),
      );
      api.close();
    },
  );
}
