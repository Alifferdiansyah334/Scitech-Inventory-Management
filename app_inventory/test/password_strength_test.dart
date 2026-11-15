import 'package:app_inventory/production/password_strength.dart';
import 'package:app_inventory/ui/palette.dart';
import 'package:app_inventory/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Password rules stay folded until opened, with the met count always visible', (tester) async {
    final password = TextEditingController(text: 'Aa1!aaaa');
    final confirmation = TextEditingController();
    addTearDown(password.dispose);
    addTearDown(confirmation.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AppPalette.resolve(scheme: SchemeKey.navy, dark: false)),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PasswordStrength(controller: password, confirmation: confirmation),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Five policy rules met, "both passwords match" not yet.
    expect(find.text('5/6'), findsOneWidget);
    expect(find.textContaining('Minimal 8 karakter').hitTestable(), findsNothing);
    await tester.tap(find.text('Syarat kata sandi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Minimal 8 karakter').hitTestable(), findsOneWidget);
    confirmation.text = 'Aa1!aaaa';
    await tester.pumpAndSettle();
    expect(find.text('6/6'), findsOneWidget);
    await tester.tap(find.text('Syarat kata sandi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Minimal 8 karakter').hitTestable(), findsNothing);
  });
}
