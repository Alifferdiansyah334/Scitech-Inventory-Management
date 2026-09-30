import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import '../data/profile_store.dart';
import 'admin_navigation.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    return AdminScaffold(
      title: 'Profil Admin',
      selectedIndex: 5,
      bodyBuilder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          AdminCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Text(
                    _initials(store.adminName),
                    style: const TextStyle(
                      color: adminIndigo,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  store.adminName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: adminNavy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  store.adminEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: adminMuted),
                ),
                const SizedBox(height: 12),
                const AdminStatusChip('Administrator'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: adminIndigo),
                  title: const Text('Edit Profil'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editProfile(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.lock_reset_outlined,
                    color: adminIndigo,
                  ),
                  title: const Text('Ubah Password'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _changePassword(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Color(0xFFDC2626)),
                  ),
                  onTap: () {
                    ProfileStore.instance.clearSession();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final store = AdminStore.instance;
    final name = TextEditingController(text: store.adminName);
    final email = TextEditingController(text: store.adminEmail);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: adminInput('Nama admin')),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: adminInput('Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    final nameValue = name.text.trim();
    final emailValue = email.text.trim();
    name.dispose();
    email.dispose();
    if (saved != true) return;
    if (nameValue.isEmpty || !emailValue.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama dan email yang valid.')),
      );
      return;
    }
    store.updateAdminProfile(name: nameValue, email: emailValue);
  }

  Future<void> _changePassword(BuildContext context) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: password,
              obscureText: true,
              decoration: adminInput('Password baru'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmation,
              obscureText: true,
              decoration: adminInput('Konfirmasi password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    final passwordValue = password.text;
    final confirmationValue = confirmation.text;
    password.dispose();
    confirmation.dispose();
    if (saved != true) return;
    if (passwordValue.length < 6 || passwordValue != confirmationValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 6 karakter dan harus sama.'),
        ),
      );
      return;
    }
    AdminStore.instance.adminPassword = passwordValue;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password diperbarui untuk sesi lokal ini.'),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'A';
    return parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
