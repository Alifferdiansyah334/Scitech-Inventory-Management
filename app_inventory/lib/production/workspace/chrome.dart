import 'package:flutter/material.dart';
import '../../ui/components.dart';
import '../../ui/motion.dart';
import '../../ui/widgets.dart';
import '../../ui/tokens.dart';

part 'chrome_buttons.dart';

/// Header pieces shared by every section, provided by the workspace shell.
class WorkspaceChrome extends InheritedWidget {
  const WorkspaceChrome({
    required this.wide,
    required this.actions,
    required super.child,
    this.notice,
    this.label,
    super.key,
  });
  final bool wide;
  final List<Widget> actions;
  final Widget? notice;

  /// Context line above the page title, e.g. 'Admin · SIMS'.
  final String? label;

  static WorkspaceChrome? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkspaceChrome>();

  @override
  bool updateShouldNotify(WorkspaceChrome old) =>
      wide != old.wide || actions != old.actions || notice != old.notice || label != old.label;
}

/// SIMS mark (Kit Case) tinted with one colour; defaults to the hero's
/// foreground. The white master keeps the prompt face as a cut-out, so any
/// tint reads like the one-colour logo.
class WhiteLogo extends StatelessWidget {
  const WhiteLogo({this.size = 28, this.color, super.key});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ColorFiltered(
      colorFilter: ColorFilter.mode(color ?? AppColors.onHero, BlendMode.srcIn),
      child: Image.asset('assets/brand/sims-symbol-white.png', width: size, height: size),
    ),
  );
}

/// True when the workspace shows the wide (rail) layout.
bool chromeWide(BuildContext context) => WorkspaceChrome.maybeOf(context)?.wide ?? false;

/// Page frame of a section. Phones: a heavy title on the tonal canvas with
/// tonal action discs at the end; one hero card belongs in the content.
/// Wide: a rounded pane on the container background, with an optional
/// [aside] pane beside it (list-detail).
class SectionLayout extends StatelessWidget {
  const SectionLayout({
    required this.title,
    this.extra,
    this.overlap,
    this.children = const [],
    this.phoneTitle,
    this.titleTrailing,
    this.aside,
    super.key,
  });
  final String title;
  final Widget? extra, overlap;
  final List<Widget> children;

  /// Shorter title for phones; [title] when null.
  final String? phoneTitle;

  /// Widget beside the phone title (e.g. a count shape on the hero).
  final Widget? titleTrailing;

  /// Second pane on wide layouts (detail of the selected record).
  final Widget? aside;

  static const maxContentWidth = 1160.0;

  @override
  Widget build(BuildContext context) {
    final chrome = WorkspaceChrome.maybeOf(context);
    return (chrome?.wide ?? false) ? _wide(context, chrome!) : _phone(context, chrome);
  }

  List<Widget> _body(WorkspaceChrome? chrome) => [
    if (chrome?.notice != null) ...[chrome!.notice!, const SizedBox(height: AppSpace.lg)],
    // Sections spring into place one after another (AgroLens Reveal),
    // and later ones as they are scrolled into view.
    for (final (i, child) in children.indexed) child is SizedBox ? child : Reveal(index: i < 6 ? i : 6, child: child),
  ];

  /// Page title (headlineMedium, as AgroLens Pustaka/Riwayat) whose words
  /// spring up one after another when the page opens.
  Widget _title(BuildContext context, String text) => Semantics(
    header: true,
    child: WordReveal(text, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.ink)),
  );

  Widget _actions(List<Widget> actions) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final action in actions)
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpace.xs),
          child: action,
        ),
    ],
  );

  /// AgroLens page header (history_tab/library_tab): headlineMedium title,
  /// its subtitle 2 below, and at most one pill action ([titleTrailing]) at
  /// the end of the same row. Header icon discs belong to home headers only
  /// (read [WorkspaceChrome.actions]).
  Widget _phone(BuildContext context, WorkspaceChrome? chrome) {
    final top = MediaQuery.paddingOf(context).top;
    final heading = phoneTitle ?? title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, top + 18, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(context, heading),
                    if (extra != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle.merge(
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.muted),
                        child: extra!,
                      ),
                    ],
                  ],
                ),
              ),
              if (titleTrailing != null) ...[
                const SizedBox(width: AppSpace.sm),
                // A long label at large text sizes gets at most 45% of the row.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .45),
                  child: titleTrailing!,
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (overlap != null) ...[overlap!, const SizedBox(height: AppSpace.xl)],
              ..._body(chrome),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wide(BuildContext context, WorkspaceChrome chrome) {
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(child: _title(context, title)),
              _actions(chrome.actions),
            ],
          ),
        ),
        if (extra != null) ...[
          const SizedBox(height: AppSpace.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: AppColors.muted, fontSize: 14),
              child: extra!,
            ),
          ),
        ],
        if (overlap != null) ...[const SizedBox(height: 20), overlap!],
        const SizedBox(height: 20),
        ..._body(chrome),
      ],
    );
    final list = WorkspacePane(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: main,
        ),
      ),
    );
    if (aside == null) return list;
    return LayoutBuilder(
      builder: (context, box) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: list),
          const SizedBox(width: AppSpace.xl),
          SizedBox(
            width: box.maxWidth >= 1200 ? 460 : 400,
            child: WorkspacePane(padding: EdgeInsets.zero, child: aside!),
          ),
        ],
      ),
    );
  }
}

/// Rounded pane on the container background (wide layouts).
class WorkspacePane extends StatelessWidget {
  const WorkspacePane({required this.child, this.padding = EdgeInsets.zero, super.key});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.page,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xxl)),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

/// Refresh failure: says what happened, keeps showing the last data.
class RefreshErrorCard extends StatelessWidget {
  const RefreshErrorCard({required this.message, required this.onRetry, this.updatedAt, super.key});
  final String message;
  final String? updatedAt;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
    decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(AppRadii.xl)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(Icons.refresh_rounded, size: 40, background: AppColors.card, foreground: AppColors.error),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data belum bisa diperbarui',
                style: TextStyle(color: AppColors.onErrorContainer, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                updatedAt == null ? message : '$message Data di bawah dari pembaruan $updatedAt.',
                style: TextStyle(fontSize: 13, color: AppColors.onErrorContainer),
              ),
              const SizedBox(height: AppSpace.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  style: TextButton.styleFrom(backgroundColor: AppColors.card, foregroundColor: AppColors.ink),
                  onPressed: onRetry,
                  child: const Text('Coba lagi'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
