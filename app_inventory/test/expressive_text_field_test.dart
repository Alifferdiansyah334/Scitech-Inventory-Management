import 'package:app_inventory/ui/controls.dart';
import 'package:app_inventory/ui/palette.dart';
import 'package:app_inventory/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: buildAppTheme(AppPalette.resolve(scheme: SchemeKey.navy, dark: false)),
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  );

  testWidgets('a password field never shows typed characters in its shapes', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      app(ExpressiveTextField(controller: c, label: 'Kata sandi', icon: Icons.lock_outline, obscureText: true)),
    );
    await tester.enterText(find.byType(TextFormField), 'Rahasia9');
    await tester.pump(const Duration(milliseconds: 100));
    for (final ch in 'RAHASIA9'.split('').toSet()) {
      expect(find.text(ch), findsNothing, reason: 'letter $ch leaked');
    }
    expect(c.text, 'Rahasia9');
    await tester.pumpAndSettle();
  });

  testWidgets('validator errors show and the field is announced by its label', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    final form = GlobalKey<FormState>();
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        Form(
          key: form,
          child: ExpressiveTextField(
            controller: c,
            label: 'Email kantor',
            hint: 'Email yang terdaftar',
            icon: Icons.mail_outline,
            validator: (v) => (v ?? '').contains('@') ? null : 'Masukkan email yang valid.',
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('Email kantor')), findsWidgets);
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Masukkan email yang valid.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'a@b.co');
    expect(form.currentState!.validate(), isTrue);
    semantics.dispose();
  });
}
