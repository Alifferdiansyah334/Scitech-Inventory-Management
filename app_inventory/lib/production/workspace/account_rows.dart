part of 'account.dart';

/// Wallpaper colours switch; disabled until the platform offers them.
class _DynamicColorRow extends StatefulWidget {
  const _DynamicColorRow({required this.appearance});
  final AppearanceController appearance;

  @override
  State<_DynamicColorRow> createState() => _DynamicColorRowState();
}

class _DynamicColorRowState extends State<_DynamicColorRow> {
  /// Whether the platform offers wallpaper colours; null while checking.
  bool? available;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    bool result;
    try {
      result = await DynamicColorPlugin.getCorePalette() != null;
    } catch (_) {
      result = false;
    }
    if (mounted) setState(() => available = result);
  }

  @override
  Widget build(BuildContext context) {
    final appearance = widget.appearance;
    final can = available ?? false;
    return SwitchRow(
      icon: Icons.wallpaper_rounded,
      title: 'Warna dinamis',
      subtitle: available == false ? 'Butuh Android 12 atau lebih baru' : 'Ikuti wallpaper (Android 12+)',
      shape: ExpressiveShape.sunny8,
      value: appearance.dynamicColor && can,
      onChanged: can ? appearance.setDynamicColor : null,
    );
  }
}

/// Avatar in its frame, name, email and team, the role pill and the way to
/// edit them.
class _Profile extends StatelessWidget {
  const _Profile({required this.user, required this.avatar, required this.onEdit});
  final Profile user;
  final AvatarChoice avatar;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final picture = ProfileAvatar(
      preset: avatar.presetSpec,
      photo: avatar.photo,
      frame: avatar.frame,
      size: 72,
      semanticLabel: 'Foto profil ${user.name}',
    );
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(user.name, style: text.headlineSmall?.copyWith(color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(user.email, style: muted),
        if (user.department.isNotEmpty) Text(user.department, style: muted),
        if (user.phone.isNotEmpty) Text(user.phone, style: muted?.copyWith(fontFeatures: tabular)),
        const SizedBox(height: 8),
        StatusPill(user.isAdmin ? 'Admin' : 'Peminjam', tone: Tone.info, dense: true),
      ],
    );
    final stacked = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stacked) ...[
          picture,
          const SizedBox(height: AppSpace.md),
          identity,
        ] else
          Row(
            children: [
              picture,
              const SizedBox(width: 14),
              Expanded(child: identity),
            ],
          ),
        const SizedBox(height: AppSpace.lg),
        PillAction(
          label: 'Edit profil',
          icon: Icons.edit_rounded,
          shape: ExpressiveShape.cookie9,
          tonal: true,
          onPressed: onEdit,
        ),
      ],
    );
  }
}
