import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models.dart';
import '../../ui/motion.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

/// Jumlah (inside a group card): the limit, then a round stepper, 56 discs
/// for minus (tonal) and plus (primary) around the count, which counts to
/// its new value.
class QuantityRow extends StatelessWidget {
  const QuantityRow({
    required this.item,
    required this.quantity,
    required this.busy,
    required this.onChanged,
    super.key,
  });
  final InventoryItem item;
  final int quantity;
  final bool busy;
  final ValueChanged<int> onChanged;

  int get max => item.available;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    Widget step({
      required IconData icon,
      required String tooltip,
      required bool primary,
      required VoidCallback? onPressed,
    }) => IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(56),
        fixedSize: const Size.square(56),
        shape: const CircleBorder(),
        backgroundColor: primary ? scheme.primary : scheme.surfaceContainerLowest,
        foregroundColor: primary ? scheme.onPrimary : scheme.onSurface,
        disabledBackgroundColor: scheme.onSurface.withValues(alpha: .08),
        disabledForegroundColor: scheme.onSurface.withValues(alpha: .38),
      ),
      icon: Icon(icon, size: 26),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maksimal $max unit per pengajuan',
          style: context.text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: tabular),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            step(
              icon: Icons.remove_rounded,
              tooltip: 'Kurangi jumlah',
              primary: false,
              onPressed: busy || quantity <= 1 ? null : () => onChanged(quantity - 1),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: 'Jumlah $quantity unit',
                excludeSemantics: true,
                child: Center(
                  child: CountUp(
                    quantity,
                    style: context.text.headlineMedium?.copyWith(height: 1.1, fontFeatures: tabular),
                  ),
                ),
              ),
            ),
            step(
              icon: Icons.add_rounded,
              tooltip: 'Tambah jumlah',
              primary: true,
              onPressed: busy || quantity >= max ? null : () => onChanged(quantity + 1),
            ),
          ],
        ),
      ],
    );
  }
}

/// 'Kabari admin' in the AgroLens featured_toggle recipe: a tonal card whose
/// corners open from 22 to 28 and fill with the secondary container when on,
/// a 42 badge morphing sunny8 → cookie12 as it turns, the title and notes,
/// and the switch. Turning it on bursts shapes from the badge.
class NotifyToggleCard extends StatefulWidget {
  const NotifyToggleCard({
    required this.value,
    required this.hasContacts,
    required this.phone,
    required this.busy,
    required this.onChanged,
    super.key,
  });
  final bool value, hasContacts, busy;
  final String phone;
  final ValueChanged<bool> onChanged;

  @override
  State<NotifyToggleCard> createState() => _NotifyToggleCardState();
}

class _NotifyToggleCardState extends State<NotifyToggleCard> with SingleTickerProviderStateMixin {
  bool get _on => widget.value && widget.hasContacts;
  bool get _enabled => widget.hasContacts && !widget.busy;

  late final _sel = AnimationController.unbounded(vsync: this, value: _on ? 1 : 0);
  final _badgeKey = GlobalKey();

  @override
  void didUpdateWidget(NotifyToggleCard old) {
    super.didUpdateWidget(old);
    final was = old.value && old.hasContacts;
    if (was == _on) return;
    final target = _on ? 1.0 : 0.0;
    reducedMotion(context) ? _sel.value = target : springTo(_sel, target, AppSprings.bouncy);
  }

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    final badge = _badgeKey.currentContext;
    if (badge != null && !_on) {
      final scheme = context.colors;
      ShapeBurst.show(
        context,
        origin: ShapeBurst.centerOf(badge),
        count: 14,
        colors: [scheme.primary, scheme.tertiary, scheme.secondary, context.palette.hero],
      );
    }
    widget.onChanged(!_on);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final notes = [
      widget.hasContacts
          ? 'Pesan WhatsApp disiapkan setelah pengajuan terkirim.'
          : 'Kontak WhatsApp admin belum diatur. Pengajuan tetap dapat dikirim melalui aplikasi.',
      if (widget.phone.isNotEmpty) 'Nomor WhatsApp akun Anda: ${widget.phone}',
    ].join('\n');
    return MergeSemantics(
      child: PressSpring(
        enabled: _enabled,
        squash: .07,
        scale: .97,
        child: AnimatedBuilder(
          animation: _sel,
          builder: (context, _) {
            final t = _sel.value.clamp(0.0, 1.0);
            final radius = BorderRadius.circular(22 + 6 * t);
            final bg = Color.lerp(scheme.surfaceContainerLow, scheme.secondaryContainer, t)!;
            final fg = Color.lerp(scheme.onSurface, scheme.onSecondaryContainer, t)!;
            return Material(
              color: bg,
              shape: RoundedRectangleBorder(borderRadius: radius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: RoundedRectangleBorder(borderRadius: radius),
                onTap: _enabled ? _toggle : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox.square(
                        key: _badgeKey,
                        dimension: 42,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: Color.lerp(scheme.surfaceContainerHighest, scheme.primary, t),
                            shape: ExpressiveShapeBorder(
                              ExpressiveShape.sunny8,
                              morphTo: ExpressiveShape.cookie12,
                              morph: _sel.value.clamp(0, 1.25),
                              rotation: _sel.value * .8,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _on ? Icons.chat_rounded : Icons.chat_outlined,
                              color: Color.lerp(scheme.onSurfaceVariant, scheme.onPrimary, t),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kabari admin via WhatsApp', style: context.text.titleSmall?.copyWith(color: fg)),
                            Text(notes, style: context.text.bodySmall?.copyWith(color: fg.withValues(alpha: .8))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(value: _on, onChanged: _enabled ? widget.onChanged : null),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
