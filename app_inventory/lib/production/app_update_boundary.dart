import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/app_updates.dart';
import '../ui/shapes.dart';
import '../ui/theme.dart';
import 'app_update_page.dart';

class AppUpdateBoundary extends StatefulWidget {
  const AppUpdateBoundary({required this.api, required this.child, super.key});
  final ApiClient api;
  final Widget child;
  @override
  State<AppUpdateBoundary> createState() => _AppUpdateBoundaryState();
}

class _AppUpdateBoundaryState extends State<AppUpdateBoundary> with WidgetsBindingObserver {
  late final AppUpdates updates = AppUpdates(widget.api);
  DateTime? checkedAt;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    check();
  }

  void check() {
    checkedAt = DateTime.now();
    updates.check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (checkedAt == null || DateTime.now().difference(checkedAt!).inMinutes >= 15)) {
      check();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    updates.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: updates,
    builder: (context, _) => Column(
      children: [
        if (updates.available)
          // Update notice in the AgroLens tonal style: a shape badge, the
          // version and a text action.
          Material(
            color: context.colors.secondaryContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                child: Row(
                  children: [
                    ShapeIcon(
                      icon: Icons.system_update_rounded,
                      shape: ExpressiveShape.sunny8,
                      size: 36,
                      fill: context.colors.primary,
                      foreground: context.colors.onPrimary,
                      iconScale: .5,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'SIMS ${updates.release!.version} tersedia.',
                        style: context.text.titleSmall?.copyWith(color: context.colors.onSecondaryContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => AppUpdatePage(api: widget.api))),
                      child: const Text('Lihat pembaruan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: updates.available, child: widget.child),
        ),
      ],
    ),
  );
}
