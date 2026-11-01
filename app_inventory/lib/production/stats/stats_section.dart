import 'package:flutter/material.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../workspace/actions.dart';
import '../workspace/chrome.dart';
import '../workspace/procurement.dart' show rupiah;
import 'admin_stats.dart';
import 'chart_parts.dart';
import 'charts.dart';
import 'donut_chart.dart';

const _periods = [7, 30, 90];

const _procurementLabels = {
  'ordered': 'Menunggu diterima',
  'received': 'Sudah diterima',
  'cancelled': 'Dibatalkan',
};

/// Admin 'Statistik': period figures overlapping the navy header, interactive
/// daily line chart, status donut, top items with asset tags, category stock
/// gauge and procurement value.
class StatsSection extends StatefulWidget {
  const StatsSection({required this.actions, super.key});
  final WorkspaceActions actions;

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  int days = 30;

  @override
  Widget build(BuildContext context) {
    final app = widget.actions.app;
    final stats = AdminStats.from(
      items: app.items,
      loans: app.loans,
      procurements: app.procurements,
      users: app.users,
      now: DateTime.now(),
      days: days,
    );
    final rate = stats.approvalRate;
    final average = stats.averageDays;
    final totalProc = stats.procurement.fold<double>(
      0,
      (sum, row) => sum + row.value,
    );

    final dailyCard = ChartCard(
      title: 'Pinjaman per hari',
      subtitle:
          'Menurut tanggal pinjam, $days hari terakhir · sentuh atau geser grafik',
      child: stats.requests == 0
          ? const ChartEmpty('Belum ada pinjaman pada periode ini.')
          : DailyLoansChart(key: ValueKey(days), stats: stats),
    );

    final gridCards = <Widget>[
      ChartCard(
        title: 'Status pinjaman terbuka',
        subtitle: 'Semua pinjaman yang belum selesai · ketuk segmen/baris',
        child: stats.openLoans == 0
            ? const ChartEmpty('Tidak ada pinjaman terbuka.')
            : LoanStatusDonut(stats: stats),
      ),
      ChartCard(
        title: 'Barang paling sering dipinjam',
        subtitle: 'Jumlah pinjaman & unit, $days hari terakhir',
        child: stats.topItems.isEmpty
            ? const ChartEmpty('Belum ada pinjaman pada periode ini.')
            : RankedBars(
                key: ValueKey('top-$days'),
                rows: [
                  for (final item in stats.topItems)
                    (
                      tagId: item.id,
                      label: item.name,
                      value: item.loans.toDouble(),
                      text: '${item.loans}× · ${item.units} unit',
                    ),
                ],
              ),
      ),
      ChartCard(
        title: 'Stok per kategori',
        subtitle: 'Unit siap dipakai vs sedang dipinjam saat ini',
        trailing: _StockLegendPill(
          available: stats.totalAvailable,
          inUse: stats.totalInUse,
        ),
        child: stats.categories.isEmpty
            ? const ChartEmpty('Belum ada barang dalam inventaris.')
            : CategoryStockChart(stats: stats),
      ),
      ChartCard(
        title: 'Nilai pengadaan',
        subtitle: 'Total biaya per status pengadaan',
        trailing: totalProc > 0
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rupiah(totalProc),
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
        child: stats.procurement.isEmpty
            ? const ChartEmpty('Belum ada catatan pengadaan.')
            : RankedBars(
                color: ChartColors.blue,
                rows: [
                  for (final row in stats.procurement)
                    (
                      tagId: null,
                      label: _procurementLabels[row.status] ?? row.status,
                      value: row.value,
                      text: '${row.count}× · ${rupiah(row.value)}',
                    ),
                ],
              ),
      ),
    ];

    return SectionLayout(
      title: 'Statistik',
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${stats.requests} pinjaman · ${stats.units} unit dalam $days hari terakhir',
            style: const TextStyle(color: AppColors.navyMuted, fontSize: 14),
          ),
          const SizedBox(height: 14),
          _PeriodBar(
            days: days,
            onChanged: (value) => setState(() => days = value),
          ),
        ],
      ),
      overlap: _FiguresCard(
        figures: [
          ('${stats.requests}', 'pinjaman ($days hr)', null),
          ('${stats.units}', 'unit dipinjam', null),
          (
            rate == null ? '–' : '${(rate * 100).round()}%',
            'disetujui dari putusan',
            null,
          ),
          (
            average == null
                ? '–'
                : '${average.toStringAsFixed(1).replaceAll('.', ',')} hari',
            'rata-rata lama pinjam',
            null,
          ),
          (
            '${stats.buckets[LoanBucket.late]}',
            'terlambat saat ini',
            stats.buckets[LoanBucket.late]! > 0 ? Tone.waiting : null,
          ),
          ('${stats.activeUsers}/${stats.totalUsers}', 'pengguna aktif', null),
        ],
      ),
      children: [
        SpringReveal(index: 0, child: dailyCard),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 760 ? 2 : 1;
            final width = (box.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final (i, card) in gridCards.indexed)
                  SizedBox(
                    width: width,
                    child: SpringReveal(index: i + 1, child: card),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Sliding segmented period selector inside the navy header.
class _PeriodBar extends StatelessWidget {
  const _PeriodBar({required this.days, required this.onChanged});
  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final idx = _periods.indexOf(days).clamp(0, _periods.length - 1);
    final dur = reducedMotion(context) ? Duration.zero : snappyCurve.duration;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.navy2,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: dur,
              curve: snappyCurve,
              alignment: Alignment(-1 + idx * (2 / (_periods.length - 1)), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / _periods.length,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final value in _periods)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(value),
                      child: Center(
                        child: Text(
                          '$value hari',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: days == value
                                ? AppColors.navy
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// White summary card overlapping the bottom edge of the navy header.
class _FiguresCard extends StatelessWidget {
  const _FiguresCard({required this.figures});
  final List<(String, String, Tone?)> figures;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      boxShadow: const [
        BoxShadow(
          color: Color(0x140E1B2E),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 860
            ? 6
            : box.maxWidth >= 500
            ? 3
            : 2;
        final width = (box.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (value, label, tone) in figures)
              Container(
                width: width,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: tone == null ? AppColors.paper : toneColors(tone).bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: tone == null
                            ? AppColors.ink
                            : toneColors(tone).fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: tone == null
                            ? AppColors.muted
                            : toneColors(tone).fg,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _StockLegendPill extends StatelessWidget {
  const _StockLegendPill({required this.available, required this.inUse});
  final int available, inUse;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: ChartColors.ok,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$available siap',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 10),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: ChartColors.navy,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$inUse dipakai',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
