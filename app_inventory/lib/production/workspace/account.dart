import 'package:flutter/material.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../app_update_page.dart';
import '../catalog/team_loan_tile.dart';
import '../forms.dart';
import 'actions.dart';
import 'chrome.dart';

/// 'Akun': profile, profile edit, password change and app updates.
class AccountSection extends StatelessWidget {
  const AccountSection({required this.actions, super.key});
  final WorkspaceActions actions;

  Future<void> editProfile(BuildContext context) async {
    final user = actions.app.profile!;
    final values = await promptForm(context, 'Ubah profil', [
      InputSpec(
        'full_name',
        'Nama lengkap',
        initial: user.name,
        min: 2,
        max: 120,
      ),
      InputSpec(
        'department',
        'Tim / divisi',
        initial: user.department,
        optional: true,
        max: 120,
      ),
      InputSpec(
        'phone',
        'Nomor telepon',
        initial: user.phone,
        optional: true,
        max: 30,
      ),
    ]);
    if (values != null && context.mounted) {
      await actions.perform(() => actions.app.updateProfile(values));
    }
  }

  Future<void> changePassword(BuildContext context) async {
    final values = await promptForm(context, 'Ubah kata sandi', [
      const InputSpec('currentPassword', 'Kata sandi saat ini', secret: true),
      const InputSpec(
        'newPassword',
        'Kata sandi baru',
        secret: true,
        min: 8,
        max: 128,
        validatePassword: true,
      ),
      const InputSpec(
        'confirm',
        'Konfirmasi kata sandi baru',
        secret: true,
        min: 8,
      ),
    ]);
    if (values == null || !context.mounted) return;
    if (values['newPassword'] != values['confirm']) {
      actions.message('Konfirmasi kata sandi tidak sama.');
      return;
    }
    await actions.perform(() async {
      await actions.app.api.request(
        'api/mobile/auth/password',
        method: 'POST',
        data: {
          'currentPassword': values['currentPassword'],
          'newPassword': values['newPassword'],
        },
      );
      await actions.app.signOut(remote: false);
    }, success: 'Kata sandi diubah. Silakan masuk kembali.');
  }

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final user = app.profile!;
    final locked = actions.locked;
    final entries = [
      (
        Icons.edit_outlined,
        'Ubah profil',
        'Nama, tim, dan nomor telepon',
        () => editProfile(context),
      ),
      (
        Icons.lock_outline,
        'Ubah kata sandi',
        'Anda akan diminta masuk kembali',
        () => changePassword(context),
      ),
      (
        Icons.system_update_outlined,
        'Pembaruan aplikasi',
        'Periksa dan pasang versi terbaru',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => AppUpdatePage(api: app.api)),
        ),
      ),
    ];
    return SectionLayout(
      title: 'Akun',
      children: [
        SpringReveal(
          child: SurfaceCard(
            padding: const EdgeInsets.all(22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonAvatar(user.name, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 10),
                      StatusPill(
                        app.isAdmin ? 'Administrator' : 'Peminjam',
                        tone: Tone.info,
                      ),
                      if (user.department.isNotEmpty ||
                          user.phone.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        for (final line in [user.department, user.phone])
                          if (line.isNotEmpty)
                            Text(line, style: const TextStyle(fontSize: 14)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SpringReveal(
              index: i + 1,
              child: SurfaceCard(
                padding: const EdgeInsets.all(14),
                onTap: locked ? null : entries[i].$4,
                child: Row(
                  children: [
                    IconTile(entries[i].$1, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entries[i].$2,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: locked ? AppColors.muted : AppColors.ink,
                            ),
                          ),
                          Text(
                            entries[i].$3,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
