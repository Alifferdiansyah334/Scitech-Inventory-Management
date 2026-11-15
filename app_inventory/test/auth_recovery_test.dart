import 'dart:convert';
import 'package:app_inventory/core/api.dart';
import 'package:app_inventory/core/app_state.dart';
import 'package:app_inventory/production/app.dart';
import 'package:app_inventory/production/auth/auth_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'connected_app_test.dart' show MemoryVault;

void main() {
  testWidgets('Recovery keeps OTP editable and actions reachable with enlarged text and keyboard', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var sends = 0;
    var verifies = 0;
    Map<String, dynamic>? reset;
    final api = ApiClient(
      baseUrl: 'https://api.example.com',
      client: MockClient((request) async {
        final path = request.url.path.replaceAll(RegExp(r'/$'), '');
        final body = request.body.isEmpty ? <String, dynamic>{} : jsonDecode(request.body) as Map<String, dynamic>;
        if (path.endsWith('/send-otp')) {
          sends++;
          expect(body['purpose'], 'forgot_password');
          return http.Response('{"success":true}', 200);
        }
        if (path.endsWith('/verify-otp')) {
          verifies++;
          expect(body['purpose'], 'forgot_password');
          return body['otp'] == '654321'
              ? http.Response('{"success":true}', 200)
              : http.Response('{"error":"Kode tidak cocok."}', 400);
        }
        if (path.endsWith('/reset-password')) {
          reset = body;
          return http.Response('{"success":true}', 200);
        }
        return http.Response('{}', 401);
      }),
    );
    final state = AppState(api: api, vault: MemoryVault());
    Future<void> tapText(String label) async {
      final finder = find.text(label);
      // A focused field re-reveals its caret after typing; let that settle
      // before scrolling the action into view, as a user would.
      await tester.pumpAndSettle();
      await tester.ensureVisible(finder);
      await tester.pump();
      expect(finder.hitTestable(), findsOneWidget);
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(ConnectedScitechApp(state: state));
    await tester.pumpAndSettle();
    await tapText('Lupa kata sandi?');
    await tester.enterText(find.byType(TextFormField), 'recovery@example.com');
    await tapText('Kirim kode pemulihan');
    expect(sends, 1);
    expect(state.profile, isNull);

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '12');
    await tapText('Verifikasi');
    expect(verifies, 0);
    expect(find.text('Masukkan 6 digit kode.'), findsWidgets);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tapText('Verifikasi');
    expect(verifies, 1);
    expect(find.textContaining('Kode tidak cocok.'), findsOneWidget);
    expect(state.profile, isNull);

    tester.view.resetViewInsets();
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
    await tapText('Kirim ulang kode');
    expect(sends, 2);
    // A whole replacement also exercises paste/autofill's single field path.
    await tester.enterText(find.byType(TextFormField), '654321');
    await tapText('Verifikasi');
    expect(verifies, 2);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'BetterPassword123!');
    await tester.enterText(fields.at(1), 'DifferentPassword123!');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Simpan kata sandi')).onPressed, isNull);
    await tester.enterText(fields.at(1), 'BetterPassword123!');
    await tapText('Simpan kata sandi');
    expect(reset, containsPair('otp', '654321'));
    expect(reset, containsPair('newPassword', 'BetterPassword123!'));
    expect(reset, containsPair('confirmPassword', 'BetterPassword123!'));
    expect(state.profile, isNull);
    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    api.close();
    state.dispose();
  });

  testWidgets('Keyboard scrolls the field into view without reflowing the hero, and closing it restores the page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final api = ApiClient(
      baseUrl: 'https://api.example.com',
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    final state = AppState(api: api, vault: MemoryVault());
    await tester.pumpWidget(ConnectedScitechApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lupa kata sandi?'));
    await tester.pumpAndSettle();
    final tall = tester.getSize(find.byType(AuthHero)).height;
    expect(tall, greaterThan(320));
    final initialTop = tester.getRect(find.byType(AuthHero)).top;
    // Focus alone (hardware keyboard, or a slow IME) must not manufacture a
    // keyboard-sized gap or lift the already visible field after a timer.
    final initialField = tester.getRect(find.byType(TextFormField));
    await tester.tap(find.byType(TextFormField));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TextFormField)), initialField);
    // Real Android metrics remove bottom safe padding when the IME opens.
    // The hero must stay stable through every keyboard animation frame.
    tester.view.padding = const FakeViewPadding(top: 24);
    for (final inset in [80.0, 180.0, 300.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AuthHero)).height, closeTo(tall, .5));
    }
    expect(tester.getSize(find.byType(AuthHero)).height, closeTo(tall, .5));
    expect(tester.getRect(find.byType(TextFormField)).bottom, lessThanOrEqualTo(844 - 300));
    // Keyboard closes: the page returns to its untouched layout.
    tester.view.resetViewInsets();
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorStateOfType<EditableTextState>(), isNull);
    expect(tester.getSize(find.byType(AuthHero)).height, closeTo(tall, .5));
    expect(tester.getRect(find.byType(AuthHero)).top, initialTop);
    expect(tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    api.close();
    state.dispose();
  });

  testWidgets('Switching fields and losing focus do not pull the form back while the keyboard is open', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final api = ApiClient(
      baseUrl: 'https://api.example.com',
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    final state = AppState(api: api, vault: MemoryVault());
    await tester.pumpWidget(ConnectedScitechApp(state: state));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.tap(fields.first);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.showKeyboard(fields.last);
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    final offset = scroll.pixels;
    expect(offset, greaterThan(0));
    expect(tester.getRect(fields.last).bottom, lessThanOrEqualTo(544));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(scroll.pixels, closeTo(offset, .5));
    // A field refocused before the IME closes must keep its new caret visible.
    await tester.showKeyboard(fields.last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.last, 'LayoutCheck123!');
    await tester.pumpAndSettle();
    expect(scroll.pixels, closeTo(offset, .5));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(scroll.pixels, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    api.close();
    state.dispose();
  });
}
