import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../catalog/team_loan_tile.dart';
import '../forms.dart';
import 'actions.dart';
import 'chrome.dart';

/// Admin 'Pengguna': activate/deactivate accounts and change roles.
class UsersSection extends StatelessWidget {
  const UsersSection({required this.actions, super.key});
  final WorkspaceActions actions;

  Future<void> _patch(
    BuildContext context,
    Profile user,
    String title,
    String message,
    Json data,
  ) async {
    if (await confirmAction(context, title, message)) {
      await actions.perform(
        () => actions.app
            .mutate('api/admin/users/${user.id}', method: 'PATCH', data: data)
            .then((_) {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = actions.app.users;
    final admins = users.where((u) => u.isAdmin).length;
    final inactive = users.where((u) => !u.active).length;
    return SectionLayout(
      title: 'Pengguna',
      extra: Text(
        '${users.length} akun · $admins admin · $inactive nonaktif',
        style: const TextStyle(color: AppColors.navyMuted, fontSize: 14),
      ),
      children: [
        if (users.isEmpty)
          const StateMessage(
            title: 'Belum ada pengguna',
            message: 'Belum ada pengguna.',
            icon: Icons.group_outlined,
          ),
        for (var i = 0; i < users.length; i++)
          Padding(
            key: ValueKey(users[i].id),
            padding: const EdgeInsets.only(bottom: 12),
            child: SpringReveal(index: i, child: _card(context, users[i])),
          ),
      ],
    );
  }

  Widget _card(BuildContext context, Profile user) {
    final self = user.id == actions.app.profile!.id;
    final locked = actions.locked;
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonAvatar(user.name, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      self ? '${user.name} (Anda)' : user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    if (user.department.isNotEmpty)
                      Text(
                        user.department,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        StatusPill(
                          user.isAdmin ? 'Admin' : 'Peminjam',
                          tone: user.isAdmin ? Tone.info : Tone.neutral,
                        ),
                        StatusPill(
                          user.active ? 'Aktif' : 'Nonaktif',
                          tone: user.active ? Tone.ok : Tone.bad,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!self) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                tonalAction(
                  user.active ? 'Nonaktifkan' : 'Aktifkan',
                  user.active ? Icons.block : Icons.check_circle_outline,
                  locked
                      ? null
                      : () => _patch(
                          context,
                          user,
                          'Ubah status akun?',
                          user.active
                              ? 'Pengguna ini tidak akan dapat mengakses layanan.'
                              : 'Pengguna ini akan dapat mengakses layanan kembali.',
                          {'is_active': !user.active},
                        ),
                  danger: user.active,
                ),
                tonalAction(
                  user.isAdmin ? 'Jadikan peminjam' : 'Jadikan admin',
                  Icons.admin_panel_settings_outlined,
                  locked
                      ? null
                      : () => _patch(
                          context,
                          user,
                          'Ubah hak akses?',
                          user.isAdmin
                              ? 'Hak administrasi akun ini akan dicabut.'
                              : 'Akun ini akan dapat mengelola inventaris dan pengguna.',
                          {'role': user.isAdmin ? 'client' : 'admin'},
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
