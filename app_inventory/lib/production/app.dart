import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../ui/theme.dart';
import '../ui/tokens.dart';
import 'auth_page.dart';
import 'workspace.dart';
import 'app_update_boundary.dart';

class ConnectedScitechApp extends StatefulWidget {
  const ConnectedScitechApp({required this.state, super.key});
  final AppState state;
  @override
  State<ConnectedScitechApp> createState() => _ConnectedScitechAppState();
}

class _ConnectedScitechAppState extends State<ConnectedScitechApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  String? previousIdentity;
  void identityChanged() {
    final profile = widget.state.profile;
    final identity = profile == null ? null : '${profile.id}:${profile.role}';
    if (identity != previousIdentity) {
      previousIdentity = identity;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.state.addListener(identityChanged);
    widget.state.restore();
  }

  @override
  void dispose() {
    widget.state.removeListener(identityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigatorKey,
    title: 'SIMS Scitech',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: AppUpdateBoundary(
      api: widget.state.api,
      child: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          if (widget.state.restoring) return const _RestoringScreen();
          if (widget.state.profile == null) {
            return ConnectedAuthPage(state: widget.state);
          }
          return ConnectedWorkspace(
            state: widget.state,
            key: ValueKey(widget.state.profile!.id),
          );
        },
      ),
    ),
  );
}

/// Shown while the stored session is checked; matches the web splash.
class _RestoringScreen extends StatelessWidget {
  const _RestoringScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            child: Image.asset('assets/images/Logo.png', height: 72),
          ),
          const SizedBox(height: 20),
          const Text(
            'Inventaris Scitech',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              minHeight: 3,
              color: Colors.white,
              backgroundColor: AppColors.navy2,
            ),
          ),
        ],
      ),
    ),
  );
}
