import 'package:app_inventory/ui/components.dart';
import 'package:app_inventory/ui/palette.dart';
import 'package:app_inventory/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final haptics = <String>[];

  setUp(() {
    haptics.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget app(Widget child, {bool reduced = false}) => MaterialApp(
    theme: buildAppTheme(AppPalette.resolve(scheme: SchemeKey.navy, dark: false), still: reduced),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('held button compresses, then rebounds and activates once', (tester) async {
    var calls = 0;
    await tester.pumpWidget(app(FilledButton(onPressed: () => calls++, child: const Text('Simpan'))));
    final label = find.text('Simpan');
    final rest = tester.getRect(label);
    final gesture = await tester.startGesture(tester.getCenter(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getRect(label).height, lessThan(rest.height));
    expect(calls, 0);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.getRect(label).height, closeTo(rest.height, .05));
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('canceling a press never activates and disabled button gives no haptic', (tester) async {
    var calls = 0;
    await tester.pumpWidget(app(FilledButton(onPressed: () => calls++, child: const Text('Simpan'))));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Simpan')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(calls, 0);
    haptics.clear();
    await tester.pumpWidget(app(const FilledButton(onPressed: null, child: Text('Simpan'))));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(haptics, isEmpty);
  });

  testWidgets('keyboard activation and reduced motion keep the action usable', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var calls = 0;
    await tester.pumpWidget(
      app(FilledButton(focusNode: focus, onPressed: () => calls++, child: const Text('Simpan')), reduced: true),
    );
    focus.requestFocus();
    await tester.pump();
    final rest = tester.getRect(find.text('Simpan'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, 1);
    final gesture = await tester.startGesture(tester.getCenter(find.text('Simpan')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getRect(find.text('Simpan')).height, closeTo(rest.height, .05));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('custom card haptic occurs only on committed tap, not canceled scrolling', (tester) async {
    var calls = 0;
    await tester.pumpWidget(app(SurfaceCard(onTap: () => calls++, child: const Text('Buka barang'))));
    final card = find.text('Buka barang');
    final gesture = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(haptics, isEmpty);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('long-press-only card activates once without a tap action', (tester) async {
    var calls = 0;
    await tester.pumpWidget(app(SurfaceCard(onLongPress: () => calls++, child: const Text('Opsi barang'))));
    await tester.tap(find.text('Opsi barang'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(haptics, isEmpty);
    await tester.longPress(find.text('Opsi barang'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });
}
