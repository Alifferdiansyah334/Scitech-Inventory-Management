import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/controls.dart';
import '../../ui/shapes.dart';
import '../../ui/tokens.dart';
import '../forms.dart';
import 'actions.dart';
import 'admin_rows.dart';
import 'chrome.dart';

/// Filter key, label, chip icon and shape, and which accounts it keeps.
final _filters = <(String, String, IconData, ExpressiveShape, bool Function(Profile))>[
  ('admin', 'Admin', Icons.admin_panel_settings_outlined, ExpressiveShape.gem, (u) => u.isAdmin),
  ('client', 'Peminjam', Icons.person_outline, ExpressiveShape.cookie9, (u) => !u.isAdmin),
  ('inactive', 'Nonaktif', Icons.block_rounded, ExpressiveShape.burst, (u) => !u.active),
];

/// Admin 'Pengguna' after AgroLens' 'Kelola artikel' (search and role chips
/// on top): one white row per account with role and state pills and shaped
/// actions to activate/deactivate and change the role.
class UsersSection extends StatefulWidget {
  const UsersSection({required this.actions, super.key});
  final WorkspaceActions actions;

  @override
  State<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  final query = TextEditingController();
  String search = '';

  /// Filter key; null shows every account.
  String? filter;

  WorkspaceActions get actions => widget.actions;

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> _patch(
    Profile user,
    String title,
    String message,
    Json data, {
    required IconData icon,
    bool danger = false,
  }) async {
    if (await confirmAction(context, title, message, icon: icon, danger: danger)) {
      await actions.perform(
        () => actions.app.mutate('api/admin/users/${user.id}', method: 'PATCH', data: data).then((_) {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = actions.app.users;
    final admins = users.where((u) => u.isAdmin).length;
    final inactive = users.where((u) => !u.active).length;
    final needle = search.trim().toLowerCase();
    final test = _filters.where((f) => f.$1 == filter).firstOrNull?.$5;
    final rows = users
        .where(
          (u) => (test == null || test(u)) && '${u.name} ${u.email} ${u.department}'.toLowerCase().contains(needle),
        )
        .toList();
    return SectionLayout(
      title: 'Pengguna',
      extra: sectionSummary(context, '${users.length} akun · $admins admin · $inactive nonaktif'),
      children: [
        AdminListHeader(
          search: ExpressiveSearchBar(
            controller: query,
            hintText: 'Cari nama, email, atau tim',
            onChanged: (value) => setState(() => search = value),
            onClear: () {
              query.clear();
              setState(() => search = '');
            },
          ),
          chips: users.isEmpty
              ? null
              : ChipStrip(
                  children: [
                    ExpressiveFilterChip(
                      label: 'Semua ${users.length}',
                      icon: Icons.group_outlined,
                      selected: filter == null,
                      onSelected: () => setState(() => filter = null),
                    ),
                    for (final (key, label, icon, shape, keep) in _filters)
                      ExpressiveFilterChip(
                        label: '$label ${users.where(keep).length}',
                        icon: icon,
                        shape: shape,
                        selected: filter == key,
                        onSelected: () => setState(() => filter = filter == key ? null : key),
                      ),
                  ],
                ),
          caption: rows.length == users.length ? 'Semua akun' : '${rows.length} dari ${users.length} akun',
        ),
        if (users.isEmpty)
          const AdminEmpty(
            title: 'Belum ada pengguna',
            message: 'Belum ada pengguna. Akun muncul di sini setelah mendaftar.',
            icon: Icons.group_outlined,
          )
        else if (rows.isEmpty)
          AdminEmpty(
            title: 'Tidak ada yang cocok',
            message: 'Tidak ada akun yang cocok dengan pencarian atau filter ini.',
            icon: Icons.search_off_rounded,
            action: OutlinedButton(
              onPressed: () {
                query.clear();
                setState(() {
                  search = '';
                  filter = null;
                });
              },
              child: const Text('Hapus filter'),
            ),
          )
        else
          AdminGrid(
            children: [for (final user in rows) KeyedSubtree(key: ValueKey(user.id), child: _row(user))],
          ),
      ],
    );
  }

  bool _self(Profile user) => user.id == actions.app.profile!.id;

  StatusPill _role(Profile user) =>
      StatusPill(user.isAdmin ? 'Admin' : 'Peminjam', tone: user.isAdmin ? Tone.info : Tone.neutral, dense: true);

  StatusPill _state(Profile user) =>
      StatusPill(user.active ? 'Aktif' : 'Nonaktif', tone: user.active ? Tone.ok : Tone.bad, dense: true);

  /// Activate/deactivate and role toggle; never offered on your own account.
  List<Widget> _actions(Profile user) {
    if (_self(user)) return const [];
    final locked = actions.locked;
    return [
      ShapeAction(
        icon: user.active ? Icons.block_rounded : Icons.check_circle_outline_rounded,
        tooltip: user.active ? 'Nonaktifkan' : 'Aktifkan',
        shape: user.active ? ExpressiveShape.burst : ExpressiveShape.flower8,
        danger: user.active,
        fill: user.active ? null : AppColors.okContainer,
        foreground: user.active ? null : AppColors.onOkContainer,
        onPressed: locked
            ? null
            : () => _patch(
                user,
                'Ubah status akun?',
                user.active
                    ? 'Pengguna ini tidak akan dapat mengakses layanan.'
                    : 'Pengguna ini akan dapat mengakses layanan kembali.',
                {'is_active': !user.active},
                icon: user.active ? Icons.block : Icons.check_circle_outline,
                danger: user.active,
              ),
      ),
      ShapeAction(
        icon: user.isAdmin ? Icons.person_outline_rounded : Icons.admin_panel_settings_outlined,
        tooltip: user.isAdmin ? 'Jadikan peminjam' : 'Jadikan admin',
        shape: ExpressiveShape.gem,
        onPressed: locked
            ? null
            : () => _patch(
                user,
                'Ubah hak akses?',
                user.isAdmin
                    ? 'Hak administrasi akun ini akan dicabut.'
                    : 'Akun ini akan dapat mengelola inventaris dan pengguna.',
                {'role': user.isAdmin ? 'client' : 'admin'},
                icon: Icons.admin_panel_settings_outlined,
              ),
      ),
    ];
  }

  /// 'Kelola' row: shaped initials, name, email and team, role and state
  /// pills; the account actions at the end.
  Widget _row(Profile user) => ManageRow(
    leading: InitialsAvatar(user.name, size: 60),
    title: _self(user) ? '${user.name} (Anda)' : user.name,
    meta: user.department.isNotEmpty ? '${user.email} · ${user.department}' : user.email,
    pills: [_role(user), _state(user)],
    actions: _actions(user),
  );
}
