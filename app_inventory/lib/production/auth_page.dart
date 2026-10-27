import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/password_policy.dart';
import 'app.dart';
import 'password_strength.dart';

class ConnectedAuthPage extends StatefulWidget {
  const ConnectedAuthPage({required this.state, super.key});
  final AppState state;
  @override
  State<ConnectedAuthPage> createState() => _ConnectedAuthPageState();
}

class _ConnectedAuthPageState extends State<ConnectedAuthPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  final department = TextEditingController(),
      phone = TextEditingController(),
      code = TextEditingController();
  final confirmation = TextEditingController();
  String mode = 'login', purpose = 'login';
  String? error, notice;
  bool working = false, remember = true, obscure = true;
  int cooldown = 0;
  Timer? timer;
  @override
  void dispose() {
    timer?.cancel();
    for (final c in [
      email,
      password,
      name,
      department,
      phone,
      code,
      confirmation,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void countdown() {
    timer?.cancel();
    cooldown = 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        cooldown--;
        if (cooldown == 0) t.cancel();
      });
    });
  }

  void switchMode(String value) => setState(() {
    mode = value;
    error = null;
    notice = null;
    code.clear();
    password.clear();
    confirmation.clear();
  });
  Future<void> submit() async {
    if (working || !form.currentState!.validate()) return;
    setState(() {
      working = true;
      error = null;
      notice = null;
    });
    final address = email.text.trim().toLowerCase();
    try {
      switch (mode) {
        case 'login':
        case 'forgot':
          purpose = mode == 'forgot' ? 'forgot_password' : 'login';
          await widget.state.sendCode(address, purpose);
          mode = 'code';
          countdown();
          notice =
              'Jika akun tersedia, kode dikirim ke email Anda. Periksa juga folder spam.';
        case 'register':
          await widget.state.registerAccount({
            'email': address,
            'password': password.text,
            'full_name': name.text.trim(),
            'department': department.text.trim(),
            'phone': phone.text.trim(),
          });
          purpose = 'register';
          mode = 'code';
          countdown();
          notice = 'Masukkan kode dari email untuk mengaktifkan akun.';
        case 'password':
          await widget.state.authenticate({
            'email': address,
            'password': password.text,
          }, remember: remember);
        case 'code':
          if (purpose == 'forgot_password') {
            await widget.state.api.request(
              'api/mobile/auth/verify-otp',
              method: 'POST',
              authenticated: false,
              data: {'email': address, 'otp': code.text, 'purpose': purpose},
            );
            mode = 'reset';
            password.clear();
            confirmation.clear();
          } else {
            await widget.state.authenticateOtp(
              address,
              code.text,
              purpose,
              remember: remember,
            );
          }
        case 'reset':
          if (password.text != confirmation.text) {
            throw const FormatException('Konfirmasi kata sandi tidak sama.');
          }
          await widget.state.api.request(
            'api/mobile/auth/reset-password',
            method: 'POST',
            authenticated: false,
            data: {
              'email': address,
              'otp': code.text,
              'newPassword': password.text,
              'confirmPassword': confirmation.text,
            },
          );
          mode = 'password';
          password.clear();
          code.clear();
          notice = 'Kata sandi berhasil diubah. Silakan masuk.';
      }
    } catch (e) {
      error = e is FormatException ? e.message : e.toString();
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool secret = false,
    bool optional = false,
    bool numeric = false,
    int min = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !working,
      obscureText: secret && obscure,
      readOnly: controller == email && const ['code', 'reset'].contains(mode),
      keyboardType: numeric
          ? TextInputType.number
          : controller == email
          ? TextInputType.emailAddress
          : TextInputType.text,
      autofillHints: controller == email
          ? [AutofillHints.email]
          : secret
          ? [AutofillHints.password]
          : null,
      maxLength: numeric ? 6 : null,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: secret
            ? IconButton(
                tooltip: obscure
                    ? 'Tampilkan kata sandi'
                    : 'Sembunyikan kata sandi',
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
      validator: (value) {
        if (controller == password &&
            const ['register', 'reset'].contains(mode)) {
          return PasswordPolicy(value ?? '').error;
        }
        if (optional && (value?.trim().isEmpty ?? true)) return null;
        if ((value?.trim().length ?? 0) < min) {
          return 'Isi minimal $min karakter.';
        }
        if (controller == email &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())) {
          return 'Masukkan email yang valid.';
        }
        if (numeric && !RegExp(r'^\d{6}$').hasMatch(value!)) {
          return 'Masukkan 6 digit kode.';
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) {
    final title = {
      'login': 'Masuk ke SIMS',
      'password': 'Masuk dengan kata sandi',
      'register': 'Buat akun peminjam',
      'forgot': 'Pulihkan kata sandi',
      'code': 'Verifikasi email',
      'reset': 'Buat kata sandi baru',
    }[mode]!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                color: Colors.white,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/Logo.png',
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'SIMS Scitech',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Inventaris dan peminjaman internal Scitech.',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 24),
                        if (error != null || widget.state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              error ?? widget.state.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        if (notice != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              notice!,
                              style: const TextStyle(color: Color(0xFF087F72)),
                            ),
                          ),
                        if (mode == 'register')
                          field(name, 'Nama lengkap', min: 2),
                        field(email, 'Alamat email'),
                        if (mode == 'register') ...[
                          field(department, 'Tim / divisi', optional: true),
                          field(phone, 'Nomor telepon', optional: true),
                        ],
                        if (const [
                          'register',
                          'password',
                          'reset',
                        ].contains(mode))
                          field(
                            password,
                            mode == 'reset' ? 'Kata sandi baru' : 'Kata sandi',
                            secret: true,
                            min: mode == 'password' ? 6 : 8,
                          ),
                        if (const ['register', 'reset'].contains(mode))
                          PasswordStrength(controller: password),
                        if (mode == 'reset')
                          field(
                            confirmation,
                            'Konfirmasi kata sandi',
                            secret: true,
                            min: 8,
                          ),
                        if (mode == 'code')
                          field(code, 'Kode OTP', numeric: true, min: 6),
                        if (const ['login', 'password', 'code'].contains(mode))
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Ingat saya di perangkat ini'),
                            value: remember,
                            onChanged: working
                                ? null
                                : (value) =>
                                      setState(() => remember = value ?? false),
                          ),
                        FilledButton(
                          onPressed: working ? null : submit,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              working
                                  ? 'Memproses...'
                                  : {
                                      'login': 'Kirim kode OTP',
                                      'password': 'Masuk',
                                      'register': 'Daftar dan verifikasi',
                                      'forgot': 'Kirim kode pemulihan',
                                      'code': 'Verifikasi',
                                      'reset': 'Simpan kata sandi',
                                    }[mode]!,
                            ),
                          ),
                        ),
                        if (mode == 'code')
                          TextButton(
                            onPressed: working || cooldown > 0
                                ? null
                                : () async {
                                    setState(() => working = true);
                                    try {
                                      await widget.state.sendCode(
                                        email.text.trim(),
                                        purpose,
                                      );
                                      countdown();
                                      notice =
                                          'Kode baru telah diminta. Periksa email Anda.';
                                    } catch (e) {
                                      error = e.toString();
                                    } finally {
                                      if (mounted) {
                                        setState(() => working = false);
                                      }
                                    }
                                  },
                            child: Text(
                              cooldown > 0
                                  ? 'Kirim ulang dalam ${cooldown}s'
                                  : 'Kirim ulang kode',
                            ),
                          ),
                        if (mode == 'login') ...[
                          TextButton(
                            onPressed: working
                                ? null
                                : () => switchMode('password'),
                            child: const Text('Masuk dengan kata sandi'),
                          ),
                          TextButton(
                            onPressed: working
                                ? null
                                : () => switchMode('register'),
                            child: const Text('Belum punya akun? Daftar'),
                          ),
                        ],
                        if (mode == 'password')
                          TextButton(
                            onPressed: working
                                ? null
                                : () => switchMode('forgot'),
                            child: const Text('Lupa kata sandi?'),
                          ),
                        if (mode != 'login')
                          TextButton(
                            onPressed: working
                                ? null
                                : () => switchMode('login'),
                            child: const Text('Kembali ke login OTP'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
