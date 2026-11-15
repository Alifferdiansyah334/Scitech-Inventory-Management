import 'package:flutter/material.dart';
import '../../ui/controls.dart';
import '../../ui/shapes.dart';
import '../../ui/tokens.dart';
import '../workspace/actions.dart';
import '../workspace/chrome.dart';
import '../workspace/procurement.dart' show rupiah;
import 'admin_stats.dart';
import 'chart_parts.dart';
import 'charts.dart';
import 'donut_chart.dart';
import 'ranked_ledger.dart';
import 'stats_overview.dart';
import 'stock_chart.dart';

const _periods = [7, 30, 90];
const _periodShapes = [ExpressiveShape.cookie9, ExpressiveShape.sunny8, ExpressiveShape.flower8];

const _procurementLabels = {'ordered': 'Menunggu diterima', 'received': 'Sudah diterima', 'cancelled': 'Dibatalkan'};

/// Admin 'Statistik' with the AgroLens page header: the period as a
/// connected button group, the one open-loans hero with counted period
/// figures, the interactive daily chart, then status donut, top items,
/// category stock and procurement value as chart groups (radius 28; two
/// columns when wide).
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
    final late = stats.buckets[LoanBucket.late]!;
    final categoryOf = {for (final item in app.items) item.id: item.category};
    final period = '$days hari terakhir';
    final end = stats.start.add(Duration(days: days - 1));

    final figures = <StatFigure>[
      (
        icon: Icons.assignment_outlined,
        shape: ExpressiveShape.cookie9,
        value: stats.requests,
        suffix: '',
        text: '',
        label: 'pinjaman dalam $days hari',
        alert: false,
      ),
      (
        icon: Icons.inventory_2_outlined,
        shape: ExpressiveShape.pentagon,
        value: stats.units,
        suffix: '',
        text: '',
        label: 'unit dipinjam',
        alert: false,
      ),
      (
        icon: Icons.task_alt_rounded,
        shape: ExpressiveShape.circle,
        value: rate == null ? null : (rate * 100).round(),
        suffix: '%',
        text: '-',
        label: 'disetujui dari putusan',
        alert: false,
      ),
      (
        icon: Icons.schedule_rounded,
        shape: ExpressiveShape.sunny8,
        value: null,
        suffix: '',
        text: average == null ? '-' : '${average.toStringAsFixed(1).replaceAll('.', ',')} hr',
        label: 'rata-rata durasi rencana',
        alert: false,
      ),
      (
        icon: Icons.alarm_rounded,
        shape: ExpressiveShape.burst,
        value: late,
        suffix: '',
        text: '',
        label: 'terlambat saat ini',
        alert: late > 0,
      ),
      (
        icon: Icons.group_outlined,
        shape: ExpressiveShape.flower8,
        value: stats.activeUsers,
        suffix: '/${stats.totalUsers}',
        text: '',
        label: 'pengguna aktif',
        alert: false,
      ),
    ];

    final dailyCard = ChartCard(
      title: 'Aktivitas peminjaman',
      icon: Icons.show_chart_rounded,
      shape: ExpressiveShape.sunny8,
      period: '${dayMonth(stats.start)} – ${dayMonth(end)}',
      subtitle: 'Berdasarkan tanggal pinjam. Sentuh grafik untuk rincian harian.',
      child: stats.requests == 0
          ? const ChartEmpty('Belum ada pinjaman pada periode ini. Pilih periode yang lebih panjang.')
          : DailyLoansChart(key: ValueKey(days), stats: stats),
    );

    final gridCards = <Widget>[
      ChartCard(
        title: 'Status pinjaman terbuka',
        icon: Icons.donut_large_rounded,
        shape: ExpressiveShape.flower8,
        period: 'Saat ini',
        subtitle: 'Pilih status untuk melihat porsinya.',
        child: stats.openLoans == 0 ? const ChartEmpty('Tidak ada pinjaman terbuka.') : LoanStatusDonut(stats: stats),
      ),
      RankedLedger(
        key: ValueKey('top-$days'),
        title: 'Barang paling sering dipinjam',
        period: period,
        subtitle: 'Jumlah pinjaman dan unit per barang',
        empty: const ChartEmpty('Belum ada pinjaman pada periode ini.'),
        rows: [
          for (final item in stats.topItems)
            (
              category: categoryOf[item.id],
              label: item.name,
              value: item.loans.toDouble(),
              text: '${item.loans}× · ${item.units} unit',
            ),
        ],
      ),
      ChartCard(
        title: 'Stok per kategori',
        icon: Icons.inventory_2_outlined,
        shape: ExpressiveShape.pentagon,
        period: 'Saat ini',
        subtitle: 'Maksimal enam kategori dengan stok terbanyak',
        legend: Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.xs + 2,
          children: [
            LegendSwatch(color: ChartColors.main, shape: ChartShapes.main, label: '${stats.totalAvailable} siap'),
            LegendSwatch(color: ChartColors.soft, shape: ChartShapes.soft, label: '${stats.totalInUse} dipakai'),
          ],
        ),
        child: stats.categories.isEmpty
            ? const ChartEmpty('Belum ada barang dalam inventaris.')
            : CategoryStockChart(stats: stats),
      ),
      _procurementCard(stats),
    ];

    return SectionLayout(
      title: 'Statistik',
      extra: const Text('Angka periode mengikuti pilihan di bawah; pinjaman terbuka dan stok selalu kondisi saat ini.'),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ExpressiveButtonGroup<int>(
              vertical: true,
              height: 96 + 30 * (MediaQuery.textScalerOf(context).scale(14) / 14 - 1).clamp(0.0, 2.0),
              segments: [
                for (final (i, p) in _periods.indexed)
                  ExpressiveSegment(
                    value: p,
                    label: '$p hari',
                    icon: Icons.date_range_rounded,
                    shape: _periodShapes[i],
                  ),
              ],
              selected: days,
              onChanged: (p) => setState(() => days = p),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        StatsOverview(stats: stats, figures: figures),
        const SizedBox(height: AppSpace.xl),
        dailyCard,
        const SizedBox(height: AppSpace.lg),
        _CardGrid(cards: gridCards),
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }

  Widget _procurementCard(AdminStats stats) {
    final total = stats.procurement.fold<double>(0, (sum, r) => sum + r.value);
    return ChartCard(
      title: 'Nilai pengadaan',
      icon: Icons.local_shipping_outlined,
      shape: ExpressiveShape.gem,
      period: 'Semua periode',
      subtitle: total > 0 ? 'Total ${rupiah(total)} · biaya per status' : 'Total biaya per status',
      child: stats.procurement.isEmpty
          ? const ChartEmpty('Belum ada catatan pengadaan.')
          : RankedBars(
              rows: [
                for (final row in stats.procurement)
                  (
                    label: _procurementLabels[row.status] ?? row.status,
                    value: row.value,
                    text: '${row.count}× · ${rupiah(row.value)}',
                  ),
              ],
              colors: [
                for (final row in stats.procurement)
                  switch (row.status) {
                    'received' => ChartColors.ok,
                    'cancelled' => ChartColors.failed,
                    _ => ChartColors.main,
                  },
              ],
              leading: [for (final row in stats.procurement) _procurementBadge(row.status)],
            ),
    );
  }

  Widget _procurementBadge(String status) {
    final (icon, shape, fill, fg) = switch (status) {
      'received' => (Icons.inventory_rounded, ExpressiveShape.circle, AppColors.okContainer, AppColors.onOkContainer),
      'cancelled' => (Icons.block_rounded, ExpressiveShape.burst, AppColors.errorContainer, AppColors.onErrorContainer),
      _ => (Icons.local_shipping_outlined, ExpressiveShape.sunny8, AppColors.secondary, AppColors.onSecondary),
    };
    return ShapeIcon(icon: icon, shape: shape, size: 40, fill: fill, foreground: fg);
  }
}

/// Cards in two masonry columns when wide (alternating, so heights balance
/// without gaps), one column otherwise or when text is enlarged.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.cards});
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final two = box.maxWidth >= 860 && MediaQuery.textScalerOf(context).scale(14) <= 18;
      Widget column(Iterable<Widget> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, card) in items.indexed) ...[if (i > 0) const SizedBox(height: AppSpace.lg), card],
        ],
      );
      if (!two) return column(cards);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: column([for (var i = 0; i < cards.length; i += 2) cards[i]])),
          const SizedBox(width: AppSpace.lg),
          Expanded(child: column([for (var i = 1; i < cards.length; i += 2) cards[i]])),
        ],
      );
    },
  );
}
