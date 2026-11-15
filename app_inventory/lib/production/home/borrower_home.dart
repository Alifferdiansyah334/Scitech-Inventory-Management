import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/button_feedback.dart';
import '../../ui/motion.dart';
import '../../ui/physics.dart';
import '../../ui/playground.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../catalog/dates.dart';
import '../catalog/item_details.dart';
import '../catalog/item_row.dart';
import '../workspace/actions.dart';
import '../workspace/chrome.dart';
import 'home_header.dart';
import 'inventory_jar.dart';

part 'home_story.dart';
part 'story_page.dart';
part 'story_painter.dart';
part 'catalog_hero.dart';
part 'shelf_pit.dart';
part 'home_cards.dart';

/// Borrower 'Beranda' (AgroLens home tab): the greeting header, the story
/// carousel ending on the category shelf, the newest own loan, category
/// cards and the items most ready to borrow. Wide layouts put the loan and
/// ready items in a second column beside the hero.
class BorrowerHome extends StatelessWidget {
  const BorrowerHome({
    required this.actions,
    required this.onBorrow,
    required this.onCatalog,
    required this.onLoans,
    super.key,
  });
  final WorkspaceActions actions;
  final void Function(InventoryItem) onBorrow;

  /// Opens Katalog, filtered to a category when given.
  final void Function([String? category]) onCatalog;
  final VoidCallback onLoans;

  static const _readyRows = 4;

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final items = app.items;
    final groups = <String, List<InventoryItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.category, () => []).add(item);
    }
    final categories = [for (final e in groups.entries) _Category(e.key, e.value)]
      ..sort((a, b) => b.items.length.compareTo(a.items.length));
    final ready = categories.fold(0, (sum, c) => sum + c.ready);
    // Loans arrive newest first.
    final latest = app.loans.firstOrNull;
    final active = app.loans.where((l) => const ['approved', 'borrowed', 'overdue'].contains(l.status)).firstOrNull;
    final available = items.where((i) => i.canBorrow).toList()..sort((a, b) => b.available.compareTo(a.available));

    void details(InventoryItem item) =>
        showItemDetails(context, app: app, item: item, picture: actions.picture, onBorrow: onBorrow);

    final story = Reveal(
      child: _HomeStory(categories: categories, ready: ready, active: active, onCatalog: onCatalog, onLoans: onLoans),
    );

    final loan = latest == null
        ? const <Widget>[]
        : [
            _SectionHeader('Pinjaman terakhir', action: 'Lihat semua', top: 10, onAction: onLoans),
            Reveal(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LastLoan(
                  loan: latest,
                  item: items.where((i) => i.id == latest.itemId).firstOrNull,
                  picture: actions.picture,
                  onTap: onLoans,
                ),
              ),
            ),
          ];

    final wide = chromeWide(context);
    final shelf = categories.isEmpty
        ? const <Widget>[]
        : [
            _SectionHeader('Kategori', action: 'Katalog', top: latest == null && !wide ? 10 : 24, onAction: onCatalog),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, category) in categories.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Reveal(
                      index: math.min(2 + i, 6),
                      child: _CategoryCard(
                        category: category,
                        picture: actions.picture,
                        onTap: () => onCatalog(category.name),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ];

    final readyNow = available.isEmpty
        ? const <Widget>[]
        : [
            _SectionHeader(
              'Tersedia sekarang',
              action: 'Lihat semua',
              top: latest == null && wide ? 10 : 24,
              onAction: onCatalog,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final (i, item) in available.take(_readyRows).indexed) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Reveal(
                      index: math.min(3 + i, 6),
                      child: ItemRow(
                        key: ValueKey(item.id),
                        item: item,
                        picture: actions.picture,
                        onTap: () => details(item),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ];

    final empty = items.isEmpty
        ? [
            StateMessage(
              title: 'Belum ada barang',
              message: app.loading
                  ? 'Inventaris sedang dimuat.'
                  : 'Inventaris masih kosong. Tarik ke bawah untuk memuat ulang.',
              icon: Icons.inventory_2_outlined,
            ),
          ]
        : const <Widget>[];

    final notice = WorkspaceChrome.maybeOf(context)?.notice;
    final firstName = app.profile?.name.trim().split(RegExp(r'\s+')).first ?? '';
    final head = [
      HomeHeader(subtitle: firstName.isEmpty ? null : '${greeting()}, $firstName'),
      if (notice != null) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: notice),
    ];

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...head, story, ...loan, ...empty, ...shelf, ...readyNow, const SizedBox(height: 4)],
      );
    }
    return WorkspacePane(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: SectionLayout.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...head,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [story, ...empty, ...shelf],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...loan, ...readyNow]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
