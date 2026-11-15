import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../ui/button_feedback.dart';
import '../core/password_policy.dart';
import '../ui/components.dart';
import '../ui/physics.dart';
import '../ui/progress.dart';
import '../ui/shapes.dart';
import '../ui/springs.dart';
import '../ui/theme.dart';

/// Password strength in the AgroLens confidence style: a wavy meter (error
/// while the policy fails, ok once it passes) with the strength in a status
/// pill, plus either a compact hint naming the missing rules or a collapsed
/// rules checklist computed by [PasswordPolicy]. Pass [confirmation] to add
/// a "both passwords match" rule.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({required this.controller, this.confirmation, this.rules = true, super.key});
  final TextEditingController controller;
  final TextEditingController? confirmation;
  final bool rules;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, ?confirmation]),
    builder: (context, child) {
      final scheme = context.colors;
      final text = controller.text;
      final policy = PasswordPolicy(text);
      final filled = text.isEmpty
          ? 0
          : !policy.valid
          ? (policy.score >= 3 ? 2 : 1)
          : policy.strength == 'Sedang'
          ? 3
          : 4;
      final tone = text.isEmpty
          ? Tone.neutral
          : !policy.valid
          ? Tone.bad
          : policy.strength == 'Sedang'
          ? Tone.waiting
          : Tone.ok;
      final requirements = <(bool, String)>[
        (policy.longEnough, 'Minimal 8 karakter'),
        (policy.uppercase, 'Huruf besar (A–Z)'),
        (policy.lowercase, 'Huruf kecil (a–z)'),
        (policy.number, 'Angka (0–9)'),
        (policy.symbol, 'Simbol (!@# dan lainnya)'),
        if (confirmation case final other?) (text.isNotEmpty && other.text == text, 'Kedua kata sandi sama'),
      ];
      final missing = [
        if (!policy.longEnough) 'minimal 8 karakter',
        if (!policy.uppercase) 'huruf besar',
        if (!policy.lowercase) 'huruf kecil',
        if (!policy.number) 'angka',
        if (!policy.symbol) 'simbol',
      ];
      final duration = reducedMotion(context) ? Duration.zero : fastSpatialCurve.duration;
      final hint = context.text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text('Kekuatan kata sandi', style: context.text.titleSmall),
                        if (text.isNotEmpty)
                          Semantics(
                            label: 'Kekuatan kata sandi: ${policy.strength}',
                            excludeSemantics: true,
                            child: StatusPill(policy.strength, tone: tone, dense: true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: filled / 4),
                      duration: duration,
                      curve: fastSpatialCurve,
                      builder: (context, value, _) => WavyLinearProgress(
                        value: value,
                        color: switch (tone) {
                          Tone.ok => toneColors(Tone.ok).fg,
                          Tone.waiting => scheme.tertiary,
                          _ => scheme.error,
                        },
                        trackColor: scheme.surfaceContainerHighest,
                        semanticsLabel: 'Kekuatan kata sandi',
                      ),
                    ),
                    if (!rules && text.isNotEmpty && missing.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Tambahkan ${missing.join(', ')}.', style: hint),
                      ),
                    if (!rules && text.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Gunakan 8–128 karakter dengan huruf besar, huruf kecil, '
                          'angka, dan simbol.',
                          style: hint,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (rules) _RulesPanel(requirements: requirements),
          ],
        ),
      );
    },
  );
}

/// The rules checklist folded behind one header row: the met count stays
/// visible, a tap squashes the row, gives a light haptic, flips the chevron
/// and unfolds the rules on a bouncy spring.
class _RulesPanel extends StatefulWidget {
  const _RulesPanel({required this.requirements});
  final List<(bool, String)> requirements;

  @override
  State<_RulesPanel> createState() => _RulesPanelState();
}

class _RulesPanelState extends State<_RulesPanel> with SingleTickerProviderStateMixin {
  late final _open = AnimationController.unbounded(vsync: this);
  bool _expanded = false;

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    final target = _expanded ? 1.0 : 0.0;
    reducedMotion(context) ? _open.value = target : springTo(_open, target, AppSprings.bouncy);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final total = widget.requirements.length;
    final met = widget.requirements.where((r) => r.$1).length;
    final all = met == total;
    final ok = toneColors(Tone.ok);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AnimatedBuilder(
        animation: _open,
        builder: (context, _) {
          final v = _open.value;
          final t = v.clamp(0.0, 1.0);
          final radius = BorderRadius.circular(24 - 6 * t);
          return Material(
            color: Color.lerp(scheme.surfaceContainerLow, scheme.surfaceContainer, t),
            shape: RoundedRectangleBorder(borderRadius: radius),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  label: 'Syarat kata sandi, $met dari $total terpenuhi',
                  hint: _expanded ? 'Sembunyikan syarat' : 'Tampilkan syarat',
                  excludeSemantics: true,
                  child: PressSpring(
                    scale: .98,
                    squash: .03,
                    child: InkWell(
                      onTap: tactileTap(_toggle),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                          child: Row(
                            children: [
                              ShapeIcon(
                                icon: all ? Icons.check_rounded : Icons.rule_rounded,
                                shape: all ? ExpressiveShape.cookie12 : ExpressiveShape.sunny8,
                                size: 34,
                                fill: all ? ok.bg : scheme.secondaryContainer,
                                foreground: all ? ok.fg : scheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Syarat kata sandi', style: context.text.titleSmall)),
                              StatusPill('$met/$total', tone: all ? Tone.ok : Tone.neutral, dense: true),
                              const SizedBox(width: 4),
                              Transform.rotate(
                                angle: v * math.pi,
                                child: Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: t,
                    child: ExcludeSemantics(
                      excluding: !_expanded,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [for (final (met, label) in widget.requirements) _RuleRow(met: met, label: label)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One requirement: a shape that pops into a check once met; the text also
/// says "(belum)" while it is not.
class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.met, required this.label});
  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final ok = toneColors(Tone.ok);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            met
                ? PopIn(
                    key: const ValueKey('met'),
                    child: ShapeIcon(
                      icon: Icons.check_rounded,
                      shape: ExpressiveShape.cookie9,
                      size: 26,
                      fill: ok.bg,
                      foreground: ok.fg,
                      iconScale: .6,
                    ),
                  )
                : SizedBox.square(
                    key: const ValueKey('open'),
                    dimension: 26,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: const ExpressiveShapeBorder(ExpressiveShape.sunny8),
                      ),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                met ? label : '$label (belum)',
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: met ? FontWeight.w600 : null,
                  color: met ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
