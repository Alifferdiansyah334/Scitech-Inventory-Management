import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'category_icons.dart';
import 'dates.dart';

/// White search field and live totals inside the navy catalog header.
class CatalogSearch extends StatelessWidget {
  const CatalogSearch({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.totals,
    super.key,
  });
  final TextEditingController controller;
  final String query, totals;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.ink),
        decoration: InputDecoration(
          hintText: 'Cari barang, kategori, atau deskripsi',
          fillColor: AppColors.surface,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        onChanged: onChanged,
      ),
      const SizedBox(height: 12),
      Text(
        totals,
        style: const TextStyle(color: AppColors.navyMuted, fontSize: 13),
      ),
    ],
  );
}

/// Card overlapping the header: active loan count and the nearest due item.
class ActiveLoansCard extends StatelessWidget {
  const ActiveLoansCard({
    required this.active,
    required this.nearest,
    required this.onTap,
    super.key,
  });
  final int active;
  final Loan? nearest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loan = nearest;
    final detail = loan == null
        ? 'Pantau persetujuan, pengambilan, dan pengembalian.'
        : loan.late
        ? '${loan.name} terlambat sejak ${dayDate(loan.dueDate)}'
        : '${loan.name} kembali ${dayDate(loan.dueDate)}';
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          const IconTile(
            Icons.schedule_rounded,
            size: 48,
            background: AppColors.accentSoft,
            foreground: AppColors.accentText,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$active pinjaman aktif',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: loan == null
                        ? AppColors.muted
                        : loan.late
                        ? AppColors.bad
                        : AppColors.accentText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
        ],
      ),
    );
  }
}

/// Horizontal rail of category tiles with counts (selected = navy).
class CategoryRail extends StatelessWidget {
  const CategoryRail({
    required this.categories,
    required this.selected,
    required this.onSelect,
    super.key,
  });
  final List<(String, int)> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final duration = reducedMotion(context)
        ? Duration.zero
        : snappyCurve.duration;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (name, count) in categories)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: PressSpring(
                child: Semantics(
                  button: true,
                  selected: name == selected,
                  label: '$name, $count barang',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onSelect(name),
                    child: AnimatedContainer(
                      duration: duration,
                      curve: snappyCurve,
                      width: 88,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: name == selected
                            ? AppColors.navy
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _tile(name, count, name == selected),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(String name, int count, bool active) {
    final fg = active ? Colors.white : AppColors.navy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          name == 'Semua' ? Icons.grid_view_rounded : categoryIcon(name),
          color: fg,
          size: 24,
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: active ? AppColors.navyMuted : AppColors.muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
