import 'package:flutter/material.dart';
import '../../ui/motion.dart';
import '../../core/brand.dart';
import '../../ui/physics.dart';
import '../../ui/theme.dart';
import '../workspace/chrome.dart';

/// Greeting for the time of day, as on AgroLens' home.
String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 18) return 'Selamat sore';
  return 'Selamat malam';
}

/// Home header (AgroLens home_tab, padding 20/12/12/4): the logo 38 in the
/// primary colour, which can be tugged on a spring, the greeting
/// (bodyMedium) over the app name (titleLarge), and the tonal round actions
/// at the end of the same row ([actions], usually
/// [WorkspaceChrome.actions]).
class HomeHeader extends StatelessWidget {
  const HomeHeader({this.title = appName, this.subtitle, this.actions, super.key});
  final String title;
  final String? subtitle;

  /// Defaults to the shell's header actions.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final buttons = actions ?? WorkspaceChrome.maybeOf(context)?.actions ?? const <Widget>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 12, 4),
      child: Row(
        children: [
          SpringDraggable(
            reach: 50,
            child: Bob(
              distance: 0,
              turn: .14,
              alignment: Alignment.bottomCenter,
              child: WhiteLogo(size: 38, color: context.colors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle ?? greeting(),
                  style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                Semantics(header: true, child: Text(title, style: context.text.titleLarge?.copyWith(height: 1.1))),
              ],
            ),
          ),
          for (final (i, button) in buttons.indexed) ...[if (i > 0) const SizedBox(width: 4), button],
        ],
      ),
    );
  }
}
