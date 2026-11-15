import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_inventory/models.dart';
import 'package:app_inventory/production/admin_contact_picker.dart';

void main() {
  testWidgets('The user explicitly chooses one of the two configured administrators', (tester) async {
    const contacts = [
      AdminContact(id: 'admin-1', name: 'Admin 1', phone: '6288212854299'),
      AdminContact(id: 'admin-2', name: 'Admin 2', phone: '6288289375343'),
    ];
    AdminContact? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await chooseAdminContact(context, contacts);
              },
              child: const Text('Hubungi admin'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Hubungi admin'));
    await tester.pumpAndSettle();
    expect(find.text('+6288212854299'), findsOneWidget);
    expect(find.text('+6288289375343'), findsOneWidget);
    expect(selected, isNull);
    await tester.tap(find.text('Admin 2'));
    await tester.pumpAndSettle();
    expect(selected!.phone, '6288289375343');
  });
}
