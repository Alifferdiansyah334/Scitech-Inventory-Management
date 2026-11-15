import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import '../../core/appearance.dart';
import '../../models.dart';
import '../../ui/avatars.dart';
import '../../ui/components.dart';
import '../../ui/controls.dart';
import '../../ui/motion.dart';
import '../../ui/shapes.dart';
import '../../ui/tokens.dart';
import '../forms.dart';
import 'actions.dart';
import 'app_settings.dart';
import 'chrome.dart';
import 'profile_edit.dart';
import 'scheme_picker.dart';

part 'account_rows.dart';

String _modeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Otomatis',
  ThemeMode.light => 'Terang',
  ThemeMode.dark => 'Gelap',
};

const _contrastLabels = {
  ContrastLevel.standard: 'Standar',
  ContrastLevel.medium: 'Sedang',
  ContrastLevel.high: 'Tinggi',
};

/// Room for a vertical segment's label and subtitle under enlarged text.
double _segmentHeight(BuildContext context) =>
    116 + 32 * (MediaQuery.textScalerOf(context).scale(14) / 14 - 1).clamp(0.0, 2.0);

/// 'Akun' (AgroLens settings tab, §13): the profile, colour palette, theme
/// and contrast as group cards, then connected rows to the app settings
/// and sign-out, and the logo with the privacy line.
class AccountSection extends StatelessWidget {
  const AccountSection({required this.actions, super.key});
  final WorkspaceActions actions;

  Future<void> signOut(BuildContext context) async {
    if (await confirmAction(context, 'Keluar dari akun?', 'Sesi pada perangkat ini akan diakhiri.')) {
      await actions.perform(() => actions.app.signOut(), success: 'Anda sudah keluar.');
    }
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void editProfile(BuildContext context) => _open(context, ProfileEditPage(actions: actions));

  void openSettings(BuildContext context) =>
      _open(context, AppSettingsPage(api: actions.app.api, showLoanPreferences: !actions.app.isAdmin));

  @override
  Widget build(BuildContext context) {
    final user = actions.app.profile!;
    final locked = actions.locked;
    final appearance = AppearanceScope.of(context);
    // Wallpaper colours are in use only when the platform supplied them.
    final dynamicOn = appearance.dynamicColor && AppPalette.current.seed != appearance.scheme.seed;

    final profile = GroupCard(
      title: 'Profil',
      icon: Icons.person_outline_rounded,
      shape: ExpressiveShape.cookie9,
      child: _Profile(
        user: user,
        avatar: appearance.avatarFor(user.id),
        onEdit: locked ? null : () => editProfile(context),
      ),
    );
    final palette = GroupCard(
      title: 'Palet warna',
      icon: Icons.palette_outlined,
      shape: ExpressiveShape.flower8,
      value: dynamicOn ? 'Warna dinamis' : appearance.scheme.label,
      child: SchemeGrid(selected: dynamicOn ? null : appearance.scheme, onChanged: appearance.setScheme),
    );
    final theme = GroupCard(
      title: 'Tema',
      icon: Icons.contrast_rounded,
      shape: ExpressiveShape.sunny8,
      value: _modeLabel(appearance.mode),
      child: ExpressiveButtonGroup<ThemeMode>(
        vertical: true,
        height: _segmentHeight(context),
        selected: appearance.mode,
        onChanged: appearance.setMode,
        segments: const [
          ExpressiveSegment(
            value: ThemeMode.system,
            label: 'Otomatis',
            subtitle: 'Ikuti HP',
            icon: Icons.brightness_auto_rounded,
            shape: ExpressiveShape.clover4,
            accent: Color(0xFF26A69A),
          ),
          ExpressiveSegment(
            value: ThemeMode.light,
            label: 'Terang',
            subtitle: 'Mode cerah',
            icon: Icons.wb_sunny_rounded,
            shape: ExpressiveShape.sunny8,
            accent: Color(0xFFF5B700),
          ),
          ExpressiveSegment(
            value: ThemeMode.dark,
            label: 'Gelap',
            subtitle: 'Mode redup',
            icon: Icons.dark_mode_rounded,
            shape: ExpressiveShape.cookie12,
            accent: Color(0xFF8E6CEF),
          ),
        ],
      ),
    );
    final contrast = GroupCard(
      title: 'Kontras',
      icon: Icons.tonality_rounded,
      shape: ExpressiveShape.gem,
      value: _contrastLabels[appearance.contrast],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpressiveButtonGroup<ContrastLevel>(
            vertical: true,
            height: _segmentHeight(context),
            selected: appearance.contrast,
            onChanged: appearance.setContrast,
            segments: const [
              ExpressiveSegment(
                value: ContrastLevel.standard,
                label: 'Standar',
                subtitle: 'Bawaan',
                icon: Icons.contrast_rounded,
                shape: ExpressiveShape.cookie9,
              ),
              ExpressiveSegment(
                value: ContrastLevel.medium,
                label: 'Sedang',
                subtitle: 'Lebih tegas',
                icon: Icons.tonality_rounded,
                shape: ExpressiveShape.pentagon,
              ),
              ExpressiveSegment(
                value: ContrastLevel.high,
                label: 'Tinggi',
                subtitle: 'Paling jelas',
                icon: Icons.filter_b_and_w_rounded,
                shape: ExpressiveShape.burst,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DynamicColorRow(appearance: appearance),
        ],
      ),
    );
    final links = LinkGroup(
      children: [
        LinkTile(
          icon: Icons.tune_rounded,
          shape: ExpressiveShape.flower8,
          title: 'Pengaturan aplikasi',
          subtitle: 'Ukuran teks, gerak, WhatsApp, dan pembaruan',
          onTap: () => openSettings(context),
        ),
        LinkTile(
          icon: Icons.logout_rounded,
          shape: ExpressiveShape.burst,
          title: 'Keluar',
          subtitle: 'Akhiri sesi di perangkat ini',
          danger: true,
          onTap: locked ? null : () => signOut(context),
        ),
      ],
    );
    final footer = Row(
      children: [
        Bob(
          distance: 0,
          turn: .14,
          alignment: Alignment.bottomCenter,
          child: WhiteLogo(size: 28, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Data pinjaman tersimpan di server Scitech. Foto profil dan tampilan hanya di perangkat ini.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );

    const gap = SizedBox(height: 12);
    return SectionLayout(
      title: 'Akun',
      children: [
        if (chromeWide(context))
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(children: [profile, gap, palette])),
              const SizedBox(width: AppSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [theme, gap, contrast, const SizedBox(height: 24), links],
                ),
              ),
            ],
          )
        else ...[
          profile,
          gap,
          palette,
          gap,
          theme,
          gap,
          contrast,
          const SizedBox(height: 24),
          links,
        ],
        const SizedBox(height: 28),
        footer,
      ],
    );
  }
}
