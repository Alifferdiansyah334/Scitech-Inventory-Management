import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import '../ui/springs.dart';
import '../ui/android_keyboard_insets.dart';
import '../core/brand.dart';
import 'brand_splash.dart';
import '../core/app_state.dart';
import '../core/appearance.dart';
import '../ui/physics.dart';
import '../ui/theme.dart';
import '../ui/tokens.dart';
import 'auth_page.dart';
import 'workspace.dart';
import 'app_update_boundary.dart';

class ConnectedScitechApp extends StatefulWidget {
  const ConnectedScitechApp({required this.state, this.appearance, super.key});
  final AppState state;

  /// Persisted theme and accessibility preferences; tests use an in-memory one.
  final AppearanceController? appearance;
  @override
  State<ConnectedScitechApp> createState() => _ConnectedScitechAppState();
}

class _ConnectedScitechAppState extends State<ConnectedScitechApp> with WidgetsBindingObserver {
  final navigatorKey = GlobalKey<NavigatorState>();
  late final AppearanceController appearance = widget.appearance ?? AppearanceController.memory();
  String? previousIdentity;

  /// True until the brand splash has played once.
  bool splashing = true;
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
    WidgetsBinding.instance.addObserver(this);
    widget.state.addListener(identityChanged);
    widget.state.restore();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.state.removeListener(identityChanged);
    super.dispose();
  }

  /// Palette colours are read through [AppColors], so widgets that would not
  /// otherwise rebuild (const subtrees) are marked dirty after a change.
  void _rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    if (mounted) (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) => DynamicColorBuilder(
    builder: (wallpaperLight, _) => ListenableBuilder(
      listenable: appearance,
      builder: (context, _) {
        final palette = appearance.resolve(
          platform: View.of(context).platformDispatcher.platformBrightness,
          wallpaper: wallpaperLight?.primary,
        );
        if (!palette.sameAs(AppPalette.current)) {
          AppPalette.current = palette;
          WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildAll());
        }
        return AppearanceScope(
          controller: appearance,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: appName,
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(
              palette,
              still: appearance.reduceMotion || (MediaQuery.maybeDisableAnimationsOf(context) ?? false),
            ),
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(mq.textScaler.scale(14) / 14 * appearance.textScale),
                  disableAnimations: mq.disableAnimations || appearance.reduceMotion,
                ),
                child: AndroidKeyboardInsets(child: TapOrigin.track(child: child!)),
              );
            },
            home: AppUpdateBoundary(
              api: widget.state.api,
              child: AnimatedBuilder(
                animation: widget.state,
                builder: (context, _) {
                  final Widget page;
                  if (splashing || widget.state.restoring) {
                    page = BrandSplash(
                      key: const ValueKey('splash'),
                      busy: !splashing,
                      onDone: () => setState(() => splashing = false),
                    );
                  } else if (widget.state.profile == null) {
                    page = ConnectedAuthPage(state: widget.state);
                  } else {
                    page = ConnectedWorkspace(state: widget.state, key: ValueKey(widget.state.profile!.id));
                  }
                  // The splash fades into the first screen (AgroLens).
                  return AnimatedSwitcher(
                    duration: reducedMotion(context) ? Duration.zero : const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOut,
                    child: page,
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}
