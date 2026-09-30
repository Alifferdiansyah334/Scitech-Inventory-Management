import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void kirimOtp() {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan alamat email yang valid')),
      );
      return;
    }

    // Backend OTP kita sambungkan nanti.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Kode OTP akan dikirim ke $email')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 430),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LOGO
                  Row(
                    children: [
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: Image.asset(
                          'assets/images/Logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SIMS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF07142D),
                            ),
                          ),
                          Text(
                            'Sistem Inventori Manajemen Scitech',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7F8DA5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 38),

                  // TITLE
                  const Text(
                    'Reset Kata Sandi.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF07142D),
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Masukkan email terdaftar untuk menerima kode verifikasi OTP',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF75829A),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Alamat Email Terdaftar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF344054),
                    ),
                  ),

                  const SizedBox(height: 9),

                  // INPUT EMAIL
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'nama@email.com',
                      hintStyle: const TextStyle(color: Color(0xFF9AA6BA)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 17,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDDE3EC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDDE3EC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF5546E8),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : kirimOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5546E8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Kirim Kode OTP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // KEMBALI LOGIN
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '← Kembali ke login',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  const Divider(color: Color(0xFFEEF1F5)),

                  const SizedBox(height: 16),

                  const Center(
                    child: Text(
                      'Sistem Peminjaman & Inventori Internal Scitech',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFFA0AABA)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
