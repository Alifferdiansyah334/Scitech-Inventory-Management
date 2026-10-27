import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/app_updates.dart';
import 'app_update_page.dart';

class AppUpdateBoundary extends StatefulWidget {
  const AppUpdateBoundary({required this.api, required this.child, super.key});
  final ApiClient api;
  final Widget child;
  @override
  State<AppUpdateBoundary> createState() => _AppUpdateBoundaryState();
}

class _AppUpdateBoundaryState extends State<AppUpdateBoundary>
    with WidgetsBindingObserver {
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
        (checkedAt == null ||
            DateTime.now().difference(checkedAt!).inMinutes >= 15)) {
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
          SafeArea(
            bottom: false,
            child: Material(
              color: const Color(0xFFEEF0FF),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.system_update, color: Color(0xFF5546E8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'SIMS ${updates.release!.version} tersedia.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AppUpdatePage(api: widget.api),
                        ),
                      ),
                      child: const Text('Lihat pembaruan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    ),
  );
}
