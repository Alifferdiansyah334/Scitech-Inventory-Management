import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_state.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/motion.dart';
import '../../ui/physics.dart';
import '../../ui/progress.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import 'team_loan_tile.dart';

part 'item_details_parts.dart';
part 'item_details_verdict.dart';

/// Availability of an item in words and tone.
({String label, Tone tone}) itemStatus(InventoryItem item) => !item.enabled
    ? (label: 'Nonaktif', tone: Tone.bad)
    : item.available > 0
    ? (label: 'Tersedia', tone: Tone.ok)
    : (label: 'Stok habis', tone: Tone.waiting);

/// Item identity, current stock, colleagues' usage and the borrowing
/// action, as a page in the AgroLens result recipe.
Future<void> showItemDetails(
  BuildContext context, {
  required AppState app,
  required InventoryItem item,
  required Widget Function(String) picture,
  required void Function(InventoryItem) onBorrow,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => _ItemDetailsPage(
      usage: app.activity.where((l) => l.itemId == item.id).toList(),
      item: item,
      picture: picture,
      onBorrow: onBorrow,
    ),
  ),
);

/// AgroLens result_screen: the photo (or category block) 42% of the screen
/// with bottom corners 44, the verdict card overlapping it by 44 (Reveal +
/// TiltOnTouch .05), the body 20 from the sides in titled sections, and the
/// action bar with the square outlined button and the primary action.
class _ItemDetailsPage extends StatelessWidget {
  const _ItemDetailsPage({required this.usage, required this.item, required this.picture, required this.onBorrow});
  final List<TeamLoan> usage;
  final InventoryItem item;
  final Widget Function(String) picture;
  final void Function(InventoryItem) onBorrow;

  static double _headerHeight(BuildContext context) => (MediaQuery.sizeOf(context).height * .42).clamp(220.0, 440.0);

  Widget _limit(Widget child) => Center(
    heightFactor: 1,
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: child),
  );

  @override
  Widget build(BuildContext context) {
    final header = _headerHeight(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // One box so the verdict card can overlap the photo: inside a
          // viewport, earlier slivers paint on top of later ones.
          SliverToBoxAdapter(
            child: _limit(
              Stack(
                children: [
                  _Header(item: item, picture: picture, height: header),
                  Padding(
                    padding: EdgeInsets.only(top: header - 44, bottom: 20),
                    child: Reveal(
                      child: TiltOnTouch(maxAngle: .05, child: _Verdict(item: item)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _limit(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Title('Ketersediaan'),
                    _StockBar(
                      label: 'Siap dipinjam',
                      value: item.available,
                      total: item.total,
                      color: context.colors.primary,
                    ),
                    _StockBar(
                      label: 'Sedang dipakai',
                      value: item.reserved,
                      total: item.total,
                      color: context.colors.secondary,
                    ),
                    const SizedBox(height: 12),
                    const _Title('Deskripsi'),
                    Text(
                      item.description.isEmpty ? 'Belum ada deskripsi barang.' : item.description,
                      style: context.text.bodyLarge,
                    ),
                    if (usage.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _Title('Dipakai rekan'),
                      for (final (i, loan) in usage.indexed) ...[
                        if (i > 0) const SizedBox(height: 10),
                        TeamLoanTile(loan: loan, showItem: false),
                      ],
                    ],
                    const SizedBox(height: 24),
                    _Note(
                      icon: item.canBorrow ? Icons.info_outline_rounded : Icons.error_outline_rounded,
                      color: item.canBorrow
                          ? context.colors.onSurfaceVariant
                          : item.enabled
                          ? AppColors.deadline
                          : context.colors.error,
                      text: !item.enabled
                          ? 'Barang ini dinonaktifkan untuk peminjaman.'
                          : item.available == 0
                          ? 'Stok sedang habis. Pengajuan tersedia saat barang dikembalikan.'
                          : 'Maksimal ${item.available} unit per pengajuan. '
                                'Admin meninjau sebelum barang diambil.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        item: item,
        onBorrow: item.canBorrow
            ? () {
                Navigator.pop(context);
                onBorrow(item);
              }
            : null,
      ),
    );
  }
}

/// The photo with the dark top fade, or the category tint with its shape
/// large; bottom corners 44 and the dark translucent back disc.
class _Header extends StatelessWidget {
  const _Header({required this.item, required this.picture, required this.height});
  final InventoryItem item;
  final Widget Function(String) picture;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(item.category);
    final (fill, ink) = AppColors.category(style.tone);
    final photo = item.imageUrl.isNotEmpty;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
              child: photo
                  ? picture(item.imageUrl)
                  : ColoredBox(
                      color: fill,
                      child: Stack(
                        children: [
                          Positioned(
                            right: -36,
                            bottom: -24,
                            child: ShapeIcon(
                              icon: style.icon,
                              shape: style.shape,
                              size: (height * .9).clamp(180.0, 300.0),
                              iconScale: 0,
                              fill: ink.withValues(alpha: .07),
                              foreground: Colors.transparent,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 44),
                            child: Center(
                              child: Bob(
                                distance: 3,
                                turn: .03,
                                child: ShapeIcon(
                                  icon: style.icon,
                                  shape: style.shape,
                                  size: (height * .5).clamp(110.0, 200.0),
                                  iconScale: .4,
                                  fill: ink,
                                  foreground: fill,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (photo)
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Color(0x80000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: IconButton(
                  tooltip: 'Kembali',
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(backgroundColor: const Color(0x66000000), foregroundColor: Colors.white),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
