import 'dart:async';
import 'package:app_inventory/ui/android_keyboard_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('native IME measurements reveal the caret when Flutter reports zero, preserving input and focus', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final insets = StreamController<num>();
    final text = TextEditingController();
    final focus = FocusNode();
    addTearDown(insets.close);
    addTearDown(text.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(MaterialApp(
      home: AndroidKeyboardInsets(
        insets: insets.stream,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 680),
              TextField(controller: text, focusNode: focus),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'tetap terlihat');
    await tester.pumpAndSettle();
    final initial = tester.getRect(find.byType(TextField));
    expect(initial.bottom, greaterThan(544));
    insets.add(600); // Physical pixels -> 300 logical pixels.
    await tester.pumpAndSettle();
    expect(tester.view.viewInsets.bottom, 0);
    expect(tester.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(544));
    expect(text.text, 'tetap terlihat');
    expect(focus.hasFocus, isTrue);
    final visible = tester.getRect(find.byType(TextField));
    insets.add(600);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TextField)), visible);
    insets.add(0);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TextField)), initial);
    expect(text.text, 'tetap terlihat');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('working Flutter IME metrics take priority over legacy measurements', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    final insets = StreamController<num>();
    addTearDown(insets.close);
    double? observed;
    await tester.pumpWidget(MaterialApp(
      home: AndroidKeyboardInsets(
        insets: insets.stream,
        child: Builder(builder: (context) {
          observed = MediaQuery.viewInsetsOf(context).bottom;
          return const Scaffold(body: SizedBox.expand());
        }),
      ),
    ));
    insets.add(400);
    await tester.pumpAndSettle();
    expect(observed, 300);
    insets.add(0);
    await tester.pumpAndSettle();
    expect(observed, 300);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
