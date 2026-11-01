import 'package:flutter/material.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

/// Header pieces shared by every section, provided by the workspace shell.
class WorkspaceChrome extends InheritedWidget {
  const WorkspaceChrome({
    required this.wide,
    required this.actions,
    required super.child,
    this.leading,
    this.notice,
    super.key,
  });
  final bool wide;
  final List<Widget> actions;
  final Widget? leading, notice;

  static WorkspaceChrome? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkspaceChrome>();

  @override
  bool updateShouldNotify(WorkspaceChrome old) =>
      wide != old.wide ||
      actions != old.actions ||
      leading != old.leading ||
      notice != old.notice;
}

/// White-tinted Scitech logo for navy surfaces.
class WhiteLogo extends StatelessWidget {
  const WhiteLogo({this.size = 28, super.key});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: Image.asset('assets/images/Logo.png', width: size, height: size),
    ),
  );
}

/// One section page: navy header (title, chrome actions, optional [extra]),
/// an optional card overlapping the header, the shell notice and [children].
class SectionLayout extends StatelessWidget {
  const SectionLayout({
    required this.title,
    this.extra,
    this.overlap,
    this.children = const [],
    super.key,
  });
  final String title;
  final Widget? extra, overlap;
  final List<Widget> children;

  static const _overlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final chrome = WorkspaceChrome.maybeOf(context);
    final wide = chrome?.wide ?? false;
    final top = wide ? 20.0 : MediaQuery.paddingOf(context).top + 12;
    final header = BrandHeader(
      padding: EdgeInsets.fromLTRB(wide ? 28 : 20, top, wide ? 28 : 20, 28),
      overlap: overlap == null ? 0 : _overlap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (chrome?.leading != null) ...[
                chrome!.leading!,
                const SizedBox(width: 12),
              ],
              if (!wide) const WhiteLogo(),
              const Spacer(),
              for (final action in chrome?.actions ?? const <Widget>[])
                Padding(padding: const EdgeInsets.only(left: 8), child: action),
            ],
          ),
          SizedBox(height: wide ? 4 : 16),
          Semantics(
            header: true,
            child: Text(
              title,
              style: TextStyle(
                fontSize: wide ? 32 : 28,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          if (extra != null) ...[const SizedBox(height: 16), extra!],
        ],
      ),
    );
    final side = wide ? 0.0 : 16.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide)
          ClipRRect(borderRadius: BorderRadius.circular(32), child: header)
        else
          header,
        if (overlap != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: side + 4),
            child: Transform.translate(
              offset: const Offset(0, -_overlap),
              child: overlap,
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(side, overlap == null ? 20 : 0, side, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (chrome?.notice != null) ...[
                chrome!.notice!,
                const SizedBox(height: 16),
              ],
              ...children,
            ],
          ),
        ),
      ],
    );
  }
}

/// Labelled 'Menu' button that opens the admin drawer on phones.
class MenuPill extends StatelessWidget {
  const MenuPill({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => PressSpring(
    child: Material(
      color: AppColors.navy2,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.view_agenda_outlined, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Refresh failure: says what happened, keeps showing the last data.
class RefreshErrorCard extends StatelessWidget {
  const RefreshErrorCard({
    required this.message,
    required this.onRetry,
    this.updatedAt,
    super.key,
  });
  final String message;
  final String? updatedAt;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.badSoft,
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IconTile(
          Icons.refresh_rounded,
          size: 40,
          background: AppColors.surface,
          foreground: AppColors.bad,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data belum bisa diperbarui',
                style: TextStyle(
                  color: AppColors.bad,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                updatedAt == null
                    ? message
                    : '$message Data di bawah dari pembaruan $updatedAt.',
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.ink,
                  ),
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

/// Tonal action button (navySoft); [danger] uses the bad tone.
Widget tonalAction(
  String label,
  IconData icon,
  VoidCallback? onPressed, {
  bool danger = false,
}) => OutlinedButton.icon(
  style: danger
      ? OutlinedButton.styleFrom(
          backgroundColor: AppColors.badSoft,
          foregroundColor: AppColors.bad,
        )
      : null,
  onPressed: onPressed,
  icon: Icon(icon, size: 18),
  label: Text(label),
);
