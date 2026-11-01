import 'package:flutter/material.dart';
import '../core/app_state.dart';
import 'auth_page.dart';
import 'workspace.dart';
import 'app_update_boundary.dart';

const navy = Color(0xFF152C49);
const indigo = Color(0xFF5546E8);
const canvas = Color(0xFFF4F7FB);

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
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: indigo),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    home: AppUpdateBoundary(
      api: widget.state.api,
      child: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          if (widget.state.restoring) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
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
