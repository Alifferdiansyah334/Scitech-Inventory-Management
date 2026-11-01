import '../../models.dart';

/// Active-loan buckets shown in the status donut, in display order.
enum LoanBucket { waiting, ready, borrowed, checking, late }

const loanBucketLabels = {
  LoanBucket.waiting: 'Menunggu persetujuan',
  LoanBucket.ready: 'Siap diambil',
  LoanBucket.borrowed: 'Sedang dipinjam',
  LoanBucket.checking: 'Menunggu pemeriksaan',
  LoanBucket.late: 'Terlambat',
};

/// Which bucket an open loan belongs to at [now]; `null` for closed loans.
LoanBucket? loanBucket(Loan loan, DateTime now) {
  if (loan.closed) return null;
  final pastDue =
      const ['borrowed', 'overdue'].contains(loan.status) &&
      loan.dueDate.isBefore(now);
  if (pastDue || loan.status == 'overdue') return LoanBucket.late;
  return switch (loan.status) {
    'pending' => LoanBucket.waiting,
    'approved' => LoanBucket.ready,
    'borrowed' => LoanBucket.borrowed,
    'returning' || 'needs_review' => LoanBucket.checking,
    _ => null,
  };
}

typedef ItemCount = ({String id, String name, int loans, int units});
typedef CategoryStock = ({String name, int available, int inUse});
typedef ProcurementTotal = ({String status, int count, double value});

/// Every figure on the admin statistics page, computed from the data the
/// app already loaded. [days] bounds the period-based figures; open-loan and
/// stock figures always describe "now".
class AdminStats {
  AdminStats._({
    required this.days,
    required this.start,
    required this.daily,
    required this.requests,
    required this.units,
    required this.topItems,
    required this.buckets,
    required this.categories,
    required this.approvalRate,
    required this.averageDays,
    required this.procurement,
    required this.activeUsers,
    required this.totalUsers,
  });

  factory AdminStats.from({
    required List<InventoryItem> items,
    required List<Loan> loans,
    required List<Procurement> procurements,
    required List<Profile> users,
    required DateTime now,
    int days = 30,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final inPeriod = [
      for (final loan in loans)
        if (!_day(loan.borrowDate).isBefore(start) &&
            !_day(loan.borrowDate).isAfter(today))
          loan,
    ];

    final daily = List<int>.filled(days, 0);
    for (final loan in inPeriod) {
      daily[_day(loan.borrowDate).difference(start).inDays]++;
    }

    final byItem = <String, ItemCount>{};
    for (final loan in inPeriod) {
      final current = byItem[loan.itemId];
      byItem[loan.itemId] = (
        id: loan.itemId,
        name: loan.name,
        loans: (current?.loans ?? 0) + 1,
        units: (current?.units ?? 0) + loan.quantity,
      );
    }
    final topItems = byItem.values.toList()
      ..sort((a, b) {
        final byLoans = b.loans.compareTo(a.loans);
        return byLoans != 0 ? byLoans : b.units.compareTo(a.units);
      });

    final buckets = {for (final bucket in LoanBucket.values) bucket: 0};
    for (final loan in loans) {
      final bucket = loanBucket(loan, now);
      if (bucket != null) buckets[bucket] = buckets[bucket]! + 1;
    }

    final byCategory = <String, CategoryStock>{};
    for (final item in items) {
      final name = item.category.trim().isEmpty
          ? 'Tanpa kategori'
          : item.category;
      final current = byCategory[name];
      byCategory[name] = (
        name: name,
        available: (current?.available ?? 0) + item.available,
        inUse: (current?.inUse ?? 0) + item.reserved,
      );
    }
    final categories = byCategory.values.toList()
      ..sort(
        (a, b) => (b.available + b.inUse).compareTo(a.available + a.inUse),
      );

    // Approval rate counts only requests an admin has decided.
    const approvedStatuses = {
      'approved',
      'borrowed',
      'returning',
      'needs_review',
      'overdue',
      'returned',
    };
    final approved = inPeriod
        .where((l) => approvedStatuses.contains(l.status))
        .length;
    final rejected = inPeriod.where((l) => l.status == 'rejected').length;
    final decided = approved + rejected;

    final durations = [
      for (final loan in inPeriod)
        _day(loan.dueDate).difference(_day(loan.borrowDate)).inDays,
    ];

    final byStatus = <String, ProcurementTotal>{};
    for (final record in procurements) {
      final current = byStatus[record.status];
      byStatus[record.status] = (
        status: record.status,
        count: (current?.count ?? 0) + 1,
        value: (current?.value ?? 0) + record.quantity * record.cost,
      );
    }

    return AdminStats._(
      days: days,
      start: start,
      daily: daily,
      requests: inPeriod.length,
      units: inPeriod.fold(0, (sum, l) => sum + l.quantity),
      topItems: topItems.take(6).toList(),
      buckets: buckets,
      categories: categories,
      approvalRate: decided == 0 ? null : approved / decided,
      averageDays: durations.isEmpty
          ? null
          : durations.reduce((a, b) => a + b) / durations.length,
      procurement: byStatus.values.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
      activeUsers: users.where((u) => u.active).length,
      totalUsers: users.length,
    );
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  final int days;

  /// First day of the period (local midnight).
  final DateTime start;

  /// Loans per borrow date, oldest first, one entry per day of the period.
  final List<int> daily;

  /// Loans and units whose borrow date falls in the period.
  final int requests, units;

  /// Most borrowed items in the period, at most six.
  final List<ItemCount> topItems;

  /// Open loans right now, per bucket.
  final Map<LoanBucket, int> buckets;

  /// Current stock per category, largest first.
  final List<CategoryStock> categories;

  /// Approved share of decided requests in the period; `null` when none.
  final double? approvalRate;

  /// Mean planned loan length in days in the period; `null` when none.
  final double? averageDays;

  final List<ProcurementTotal> procurement;
  final int activeUsers, totalUsers;

  int get openLoans => buckets.values.fold(0, (sum, n) => sum + n);
  int get busiestDay => daily.fold(0, (a, b) => a > b ? a : b);
  int get busiestDayIndex {
    var best = 0;
    for (var i = 1; i < daily.length; i++) {
      if (daily[i] >= daily[best]) best = i;
    }
    return best;
  }

  double get dailyAverage => days == 0 ? 0 : requests / days;
  int get totalAvailable => categories.fold(0, (sum, c) => sum + c.available);
  int get totalInUse => categories.fold(0, (sum, c) => sum + c.inUse);
}
