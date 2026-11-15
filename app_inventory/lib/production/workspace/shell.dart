import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/components.dart';
import '../../ui/controls.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'rail.dart';

/// One workspace destination with the shape that marks it everywhere (dock,
/// rail, "Lainnya" sheet).
class NavDest {
  const NavDest(this.label, this.icon, this.selectedIcon, this.shape);
  final String label;
  final IconData icon, selectedIcon;
  final ExpressiveShape shape;
}

/// Destinations the admin phone dock shows directly; the rest sit behind
/// "Lainnya".
const _dockLabels = {'Ringkasan', 'Pinjaman', 'Barang'};

/// Responsive frame around a section: expressive dock on phones (admins get
/// a "Lainnya" sheet for the remaining destinations), an expanded rail from
/// 900 px; thin progress line, pull-to-refresh and the last-updated footnote.
class WorkspaceShell extends StatelessWidget {
  const WorkspaceShell({
    required this.wide,
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.isAdmin,
    required this.name,
    required this.email,
    required this.userId,
    required this.pending,
    required this.progress,
    required this.onRefresh,
    required this.onSignOut,
    required this.child,
    this.footnote,
    super.key,
  });
  final bool wide, isAdmin, progress;
  final List<NavDest> destinations;
  final int selected, pending;
  final ValueChanged<int> onSelect;
  final String name, email, userId;
  final Future<void> Function() onRefresh;
  final VoidCallback? onSignOut;
  final Widget child;
  final String? footnote;

  /// Indices of [destinations] shown in the phone dock, in order.
  List<int> get _dock => isAdmin
      ? [
          for (var i = 0; i < destinations.length; i++)
            if (_dockLabels.contains(destinations[i].label)) i,
        ]
      : [for (var i = 0; i < destinations.length; i++) i];

  Widget _navBar(BuildContext context) {
    final dock = _dock;
    final hasMore = dock.length < destinations.length;
    final inDock = dock.indexOf(selected);
    final items = [
      for (final i in dock)
        ExpressiveNavItem(
          label: destinations[i].label,
          icon: destinations[i].icon,
          selectedIcon: destinations[i].selectedIcon,
          shape: destinations[i].shape,
        ),
      if (hasMore)
        const ExpressiveNavItem(
          label: 'Lainnya',
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
          shape: ExpressiveShape.softBurst,
        ),
    ];
    // Labels stay one line in the 76 dp dock; very large text is capped here
    // and remains full size everywhere else.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: ExpressiveNavBar(
        key: ValueKey(items.length),
        items: items,
        selectedIndex: inDock < 0 ? items.length - 1 : inDock,
        onSelected: (i) {
          if (i < dock.length) {
            onSelect(dock[i]);
          } else {
            _showMore(context, dock);
          }
        },
      ),
    );
  }

  void _showMore(BuildContext context, List<int> dock) {
    final rest = [
      for (var i = 0; i < destinations.length; i++)
        if (!dock.contains(i)) i,
    ];
    // AgroLens sheet: headlineSmall title, connected destination rows, then
    // sign-out as a 52 dp error-outlined button.
    showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: sheetAnimation(context),
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheet) {
        final scheme = Theme.of(sheet).colorScheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(header: true, child: Text('Lainnya', style: Theme.of(sheet).textTheme.headlineSmall)),
                const SizedBox(height: 4),
                Text(
                  'Bagian lain dari ruang kerja admin.',
                  style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                LinkGroup(
                  children: [
                    for (final i in rest)
                      LinkTile(
                        icon: destinations[i].icon,
                        shape: destinations[i].shape,
                        title: destinations[i].label,
                        selected: i == selected,
                        onTap: () {
                          Navigator.of(sheet).pop();
                          onSelect(i);
                        },
                      ),
                  ],
                ),
                if (onSignOut != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                    ),
                    onPressed: () {
                      Navigator.of(sheet).pop();
                      onSignOut!();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TabEntrance(key: ValueKey(selected), child: child),
        if (footnote != null)
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 12 : AppSpace.xl, AppSpace.xl, AppSpace.lg, 0),
            child: Text(footnote!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
          ),
      ],
    );
    final content = Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            // Each destination starts at the top, like AgroLens' tabs.
            key: PageStorageKey<int>(selected),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: wide
                ? const EdgeInsets.fromLTRB(0, AppSpace.lg, AppSpace.lg, AppSpace.xl)
                : const EdgeInsets.only(bottom: AppSpace.xl),
            children: [page],
          ),
        ),
        if (progress)
          Positioned(
            top: wide ? 0 : MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 3, color: AppColors.brand, backgroundColor: Colors.transparent),
          ),
      ],
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: wide ? AppColors.container : AppColors.page,
        bottomNavigationBar: wide ? null : _navBar(context),
        body: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 248,
                    child: SafeArea(
                      right: false,
                      child: RailContent(
                        destinations: destinations,
                        selected: selected,
                        onSelect: onSelect,
                        isAdmin: isAdmin,
                        name: name,
                        email: email,
                        userId: userId,
                        pending: pending,
                        onSignOut: onSignOut,
                      ),
                    ),
                  ),
                  Expanded(child: SafeArea(left: false, child: content)),
                ],
              )
            : content,
      ),
    );
  }
}

/// AgroLens tab change: the newly selected destination springs up 14 px
/// and fades in (default spatial / effects springs). Reduced motion shows it
/// at once.
class _TabEntrance extends StatefulWidget {
  const _TabEntrance({required this.child, super.key});
  final Widget child;

  @override
  State<_TabEntrance> createState() => _TabEntranceState();
}

class _TabEntranceState extends State<_TabEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.value != 0) return;
    if (reducedMotion(context)) {
      _c.value = 1;
    } else {
      springTo(_c, 1, AppSprings.defaultSpatial, velocity: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Opacity(
      opacity: _c.value.clamp(0, 1).toDouble(),
      child: Transform.translate(offset: Offset(0, 14 * (1 - _c.value)), child: child),
    ),
    child: widget.child,
  );
}
