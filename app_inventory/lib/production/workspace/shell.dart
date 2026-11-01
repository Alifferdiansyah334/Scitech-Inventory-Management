import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/tokens.dart';
import 'rail.dart';

/// Responsive frame around a section: bottom bar (borrower phone), drawer
/// (admin phone) or inset navy rail (≥900 px); thin progress line,
/// pull-to-refresh, and the last-updated footnote.
class WorkspaceShell extends StatelessWidget {
  const WorkspaceShell({
    required this.scaffoldKey,
    required this.wide,
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.isAdmin,
    required this.name,
    required this.pending,
    required this.progress,
    required this.onRefresh,
    required this.child,
    this.footnote,
    super.key,
  });
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool wide, isAdmin, progress;
  final List<(String, IconData)> destinations;
  final int selected, pending;
  final ValueChanged<int> onSelect;
  final String name;
  final Future<void> Function() onRefresh;
  final Widget child;
  final String? footnote;

  RailContent _rail(ValueChanged<int> select) => RailContent(
    destinations: destinations,
    selected: selected,
    onSelect: select,
    isAdmin: isAdmin,
    name: name,
    pending: pending,
  );

  @override
  Widget build(BuildContext context) {
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        if (footnote != null)
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 4 : 20, 24, 20, 0),
            child: Text(
              footnote!,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
      ],
    );
    final content = Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: wide
                ? const EdgeInsets.fromLTRB(8, 16, 24, 32)
                : const EdgeInsets.only(bottom: 24),
            children: [
              if (wide)
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: page,
                  ),
                )
              else
                page,
            ],
          ),
        ),
        if (progress)
          Positioned(
            top: wide ? 0 : MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            child: const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.navyMuted,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.paper,
      drawer: !wide && isAdmin
          ? Drawer(
              backgroundColor: AppColors.navy,
              child: SafeArea(
                child: _rail((index) {
                  scaffoldKey.currentState?.closeDrawer();
                  onSelect(index);
                }),
              ),
            )
          : null,
      bottomNavigationBar: !wide && !isAdmin
          ? NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: onSelect,
              destinations: [
                for (final item in destinations)
                  NavigationDestination(icon: Icon(item.$2), label: item.$1),
              ],
            )
          : null,
      body: wide
          ? SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 256,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: _rail(onSelect),
                  ),
                  Expanded(child: content),
                ],
              ),
            )
          : AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: content,
            ),
    );
  }
}
