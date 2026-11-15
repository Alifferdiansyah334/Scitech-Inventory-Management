import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_inventory/models.dart';
import 'package:app_inventory/production/stats/admin_stats.dart';
import 'package:app_inventory/production/stats/charts.dart';
import 'package:app_inventory/production/stats/donut_chart.dart';

final now = DateTime(2026, 11, 10, 15);

Loan loan(
  String id,
  String status, {
  required int borrowedDaysAgo,
  required int dueInDays,
  String item = 'i1',
  String name = 'Kamera',
  int quantity = 1,
}) => Loan(
  id: id,
  itemId: item,
  name: name,
  quantity: quantity,
  status: status,
  purpose: 'Uji',
  borrowDate: now.subtract(Duration(days: borrowedDaysAgo)),
  dueDate: now.add(Duration(days: dueInDays)),
);

InventoryItem item(String id, String category, int total, int available) =>
    InventoryItem(id: id, name: id, category: category, total: total, available: available, enabled: true);

void main() {
  test('Period figures count only loans borrowed inside the window', () {
    final stats = AdminStats.from(
      items: const [],
      loans: [
        loan('a', 'pending', borrowedDaysAgo: 0, dueInDays: 7, quantity: 2),
        loan('b', 'returned', borrowedDaysAgo: 6, dueInDays: -2),
        loan('c', 'approved', borrowedDaysAgo: 7, dueInDays: 1),
        loan('d', 'rejected', borrowedDaysAgo: 3, dueInDays: 4),
      ],
      procurements: const [],
      users: const [],
      now: now,
      days: 7,
    );
    expect(stats.daily, hasLength(7));
    // 'c' is 7 days old, one day before a 7-day window that ends today.
    expect(stats.requests, 3);
    expect(stats.units, 4);
    expect(stats.daily.last, 1);
    expect(stats.daily.first, 1);
    // Pending is undecided: 1 approved-type ('returned') of 2 decided.
    expect(stats.approvalRate, 0.5);
    expect(stats.averageDays, closeTo((7 + 4 + 7) / 3, 1e-9));
  });

  test('Open loans are bucketed by status, late wins over borrowed', () {
    final stats = AdminStats.from(
      items: const [],
      loans: [
        loan('a', 'pending', borrowedDaysAgo: 1, dueInDays: 5),
        loan('b', 'borrowed', borrowedDaysAgo: 9, dueInDays: -1),
        loan('c', 'borrowed', borrowedDaysAgo: 2, dueInDays: 3),
        loan('d', 'needs_review', borrowedDaysAgo: 4, dueInDays: 2),
        loan('e', 'returned', borrowedDaysAgo: 20, dueInDays: -10),
        loan('f', 'cancelled', borrowedDaysAgo: 2, dueInDays: 5),
      ],
      procurements: const [],
      users: const [],
      now: now,
    );
    expect(stats.buckets[LoanBucket.waiting], 1);
    expect(stats.buckets[LoanBucket.late], 1);
    expect(stats.buckets[LoanBucket.borrowed], 1);
    expect(stats.buckets[LoanBucket.checking], 1);
    expect(stats.openLoans, 4);
  });

  test('Top items rank by loan count, then units; categories by size', () {
    final stats = AdminStats.from(
      items: [item('cam', 'Kamera', 3, 1), item('tri', 'Kamera', 2, 2), item('drn', 'Drone', 6, 6)],
      loans: [
        loan('a', 'borrowed', borrowedDaysAgo: 1, dueInDays: 3, item: 'cam'),
        loan('b', 'returned', borrowedDaysAgo: 2, dueInDays: 1, item: 'cam'),
        loan('c', 'borrowed', borrowedDaysAgo: 1, dueInDays: 3, item: 'drn', name: 'Drone', quantity: 3),
      ],
      procurements: const [],
      users: const [],
      now: now,
    );
    expect(stats.topItems.first.id, 'cam');
    expect(stats.topItems.first.name, 'Kamera');
    expect(stats.topItems.first.loans, 2);
    expect(stats.topItems.last.units, 3);
    expect(stats.categories.first.name, 'Drone');
    final camera = stats.categories.firstWhere((c) => c.name == 'Kamera');
    expect((camera.available, camera.inUse), (3, 2));
    expect((stats.totalAvailable, stats.totalInUse), (9, 2));
    expect(stats.busiestDayIndex, 28);
  });

  testWidgets('Status donut legend tap updates center gauge share', (tester) async {
    final stats = AdminStats.from(
      items: const [],
      loans: [
        loan('a', 'pending', borrowedDaysAgo: 1, dueInDays: 5),
        loan('b', 'borrowed', borrowedDaysAgo: 9, dueInDays: -1),
        loan('c', 'borrowed', borrowedDaysAgo: 2, dueInDays: 3),
        loan('d', 'needs_review', borrowedDaysAgo: 4, dueInDays: 2),
      ],
      procurements: const [],
      users: const [],
      now: now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                DailyLoansChart(stats: stats),
                LoanStatusDonut(stats: stats),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('pinjaman terbuka'), findsOneWidget);
    await tester.ensureVisible(find.text('Terlambat'));
    await tester.tap(find.text('Terlambat'));
    await tester.pump();
    expect(find.textContaining('25% dari terbuka'), findsOneWidget);
  });

  test('No decided requests gives no approval rate instead of 0%', () {
    final stats = AdminStats.from(
      items: const [],
      loans: [loan('a', 'pending', borrowedDaysAgo: 0, dueInDays: 3)],
      procurements: const [],
      users: const [],
      now: now,
    );
    expect(stats.approvalRate, isNull);
  });
}
