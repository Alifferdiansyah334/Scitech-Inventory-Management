import 'package:flutter/material.dart';
import '../../ui/button_feedback.dart';
import '../../core/api.dart';
import '../../core/appearance.dart';
import '../../ui/components.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../app_update_page.dart';

/// A white row with a shaped icon, title, subtitle and a switch; tapping
/// anywhere on the row toggles it and the row reads as one control. For use
/// inside a [GroupCard].
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.shape = ExpressiveShape.cookie9,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;

  /// `null` disables the switch.
  final ValueChanged<bool>? onChanged;
  final ExpressiveShape shape;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final radius = BorderRadius.circular(20);
    return MergeSemantics(
      child: PressSpring(
        enabled: enabled,
        scale: .98,
        squash: .04,
        child: Material(
          color: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: tactileTap(enabled ? () => onChanged!(!value) : null),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  children: [
                    ShapeIcon(
                      icon: icon,
                      shape: shape,
                      size: 40,
                      fill: enabled ? AppColors.secondary : AppColors.disabled,
                      foreground: enabled ? AppColors.onSecondary : AppColors.onDisabled,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(color: enabled ? AppColors.ink : AppColors.muted),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty)
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Switch(value: value, onChanged: onChanged),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 'Pengaturan aplikasi' (AgroLens settings groups): device-only
/// preferences that exist in the app, one group card per task: text size
/// and reduced motion, the WhatsApp default of the request form, then app
/// updates as a link row.
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({required this.api, this.showLoanPreferences = true, super.key});
  final ApiClient api;

  /// Borrowers see the request-form defaults; admins do not submit requests.
  final bool showLoanPreferences;

  static const _minScale = .85, _maxScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.of(context);
    final text = Theme.of(context).textTheme;
    final scale = appearance.textScale.clamp(_minScale, _maxScale).toDouble();
    final percent = '${(scale * 100).round()}%';
    Widget letter(TextStyle? style) => ExcludeSemantics(
      child: Text('A', style: style?.copyWith(color: AppColors.muted)),
    );
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan aplikasi')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              GroupCard(
                title: 'Ukuran teks',
                icon: Icons.text_fields_rounded,
                shape: ExpressiveShape.arch,
                value: percent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Dikalikan dengan ukuran teks sistem.',
                      style: text.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                    Row(
                      children: [
                        letter(text.labelSmall),
                        Expanded(
                          child: Slider(
                            value: scale,
                            min: _minScale,
                            max: _maxScale,
                            divisions: 9,
                            label: percent,
                            semanticFormatterCallback: (v) => 'Ukuran teks ${(v * 100).round()} persen',
                            onChanged: (v) {
                              final rounded = (v * 100).round() / 100;
                              if (rounded != appearance.textScale) appearance.setTextScale(rounded);
                            },
                          ),
                        ),
                        letter(text.titleLarge),
                      ],
                    ),
                  ],
                ),
              ),
              gap,
              GroupCard(
                title: 'Gerak',
                icon: Icons.animation_rounded,
                shape: ExpressiveShape.pentagon,
                value: appearance.reduceMotion ? 'Dikurangi' : 'Penuh',
                child: SwitchRow(
                  icon: Icons.motion_photos_off_outlined,
                  title: 'Kurangi gerak',
                  subtitle: 'Tanpa pantulan dan geseran',
                  shape: ExpressiveShape.pentagon,
                  value: appearance.reduceMotion,
                  onChanged: appearance.setReduceMotion,
                ),
              ),
              if (showLoanPreferences) ...[
                gap,
                GroupCard(
                  title: 'Peminjaman',
                  icon: Icons.assignment_outlined,
                  shape: ExpressiveShape.sunny8,
                  value: appearance.whatsappByDefault ? 'WhatsApp aktif' : 'WhatsApp mati',
                  child: SwitchRow(
                    icon: Icons.chat_outlined,
                    title: 'Pesan WhatsApp otomatis',
                    subtitle: 'Mengaktifkan pilihan kirim WhatsApp ke admin di formulir pengajuan',
                    shape: ExpressiveShape.cookie12,
                    value: appearance.whatsappByDefault,
                    onChanged: appearance.setWhatsappByDefault,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              LinkGroup(
                children: [
                  LinkTile(
                    icon: Icons.download_rounded,
                    shape: ExpressiveShape.gem,
                    title: 'Pembaruan aplikasi',
                    subtitle: 'Periksa dan pasang versi terbaru',
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AppUpdatePage(api: api))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
