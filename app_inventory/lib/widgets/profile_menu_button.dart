import 'dart:io';

import 'package:flutter/material.dart';

import '../data/profile_store.dart';
import '../pages/admin_dashboard_page.dart';
import '../pages/change_password_page.dart';
import '../pages/edit_profile_page.dart';

class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileStore.instance.profile;
    return IconButton(
      key: const ValueKey('profile_menu_button'),
      tooltip: 'Profil',
      onPressed: () => _showProfileMenu(context),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFFEEF2FF),
        backgroundImage: profile.avatarPath == null
            ? null
            : FileImage(File(profile.avatarPath!)),
        child: profile.avatarPath == null
            ? Text(
                profile.initials,
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final profile = ProfileStore.instance.profile;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: const Color(0xFFEEF2FF),
                      backgroundImage: profile.avatarPath == null
                          ? null
                          : FileImage(File(profile.avatarPath!)),
                      child: profile.avatarPath == null
                          ? Text(
                              profile.initials,
                              style: const TextStyle(
                                color: Color(0xFF4F46E5),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${profile.roleLabel} • ${profile.email}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(color: Color(0xFFF1F5F9)),
                _MenuAction(
                  icon: Icons.person_outline,
                  label: 'Profil Saya',
                  onTap: () => _open(sheetContext, const EditProfilePage()),
                ),
                _MenuAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profil',
                  onTap: () => _open(sheetContext, const EditProfilePage()),
                ),
                _MenuAction(
                  icon: Icons.lock_reset_outlined,
                  label: 'Ubah Password',
                  onTap: () => _open(sheetContext, const ChangePasswordPage()),
                ),
                _MenuAction(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Mode Admin (Demo)',
                  onTap: () => _open(sheetContext, const AdminDashboardPage()),
                ),
                _MenuAction(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  destructive: true,
                  onTap: () {
                    ProfileStore.instance.clearSession();
                    Navigator.pushNamedAndRemoveUntil(
                      sheetContext,
                      '/',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      icon,
      color: destructive ? const Color(0xFFEF4444) : const Color(0xFF64748B),
    ),
    title: Text(
      label,
      style: TextStyle(
        color: destructive ? const Color(0xFFEF4444) : const Color(0xFF334155),
        fontWeight: FontWeight.w700,
      ),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    onTap: onTap,
  );
}
