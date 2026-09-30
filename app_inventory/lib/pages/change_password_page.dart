import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void updatePassword() {
    if (currentController.text.isEmpty || newController.text.length < 8) {
      _showMessage(
        'Password baru minimal 8 karakter dan password saat ini wajib diisi.',
      );
      return;
    }
    if (newController.text != confirmController.text) {
      _showMessage('Konfirmasi password baru tidak sesuai.');
      return;
    }

    _showMessage(
      'Perubahan password belum dikirim karena API password Flutter belum tersedia.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ubah Password'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Keamanan Akun.',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Perbarui password untuk menjaga keamanan akun Anda.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          _PasswordField(
            label: 'PASSWORD SAAT INI',
            controller: currentController,
            obscureText: hideCurrent,
            onToggle: () => setState(() => hideCurrent = !hideCurrent),
          ),
          const SizedBox(height: 18),
          _PasswordField(
            label: 'PASSWORD BARU',
            controller: newController,
            obscureText: hideNew,
            onToggle: () => setState(() => hideNew = !hideNew),
          ),
          const SizedBox(height: 18),
          _PasswordField(
            label: 'KONFIRMASI PASSWORD BARU',
            controller: confirmController,
            obscureText: hideConfirm,
            onToggle: () => setState(() => hideConfirm = !hideConfirm),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: updatePassword,
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('Update Password'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Website saat ini hanya menyediakan reset password melalui OTP lupa password. Integrasi update password langsung membutuhkan endpoint/session Flutter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscureText,
    required this.onToggle,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
          ),
        ),
      ),
    ],
  );
}
