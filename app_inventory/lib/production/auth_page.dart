import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/password_policy.dart';
import '../ui/springs.dart';
import '../ui/tokens.dart';
import 'auth/auth_entry.dart';
import 'auth/auth_parts.dart';
import 'auth/otp_input.dart';
import 'password_strength.dart';

part 'auth/auth_views.dart';

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

  void update(VoidCallback change) => setState(change);

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

  Future<void> resend() async {
    setState(() => working = true);
    try {
      await widget.state.sendCode(email.text.trim(), purpose);
      countdown();
      notice = 'Kode baru telah diminta. Periksa email Anda.';
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    String? hint,
    IconData? icon,
    String? helper,
    bool secret = false,
    bool optional = false,
    TextInputType? keyboard,
    int min = 1,
  }) => AuthFieldLabel(
    label: label,
    child: TextFormField(
      controller: controller,
      enabled: !working,
      obscureText: secret && obscure,
      keyboardType:
          keyboard ??
          (controller == email
              ? TextInputType.emailAddress
              : TextInputType.text),
      autofillHints: controller == email
          ? [AutofillHints.email]
          : secret
          ? [AutofillHints.password]
          : null,
      decoration: InputDecoration(
        hintText: hint,
        helperText: helper,
        prefixIcon: icon == null ? null : Icon(icon, size: 22),
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
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final entry = mode == 'login' || mode == 'password';
    final still = reducedMotion(context);
    return Scaffold(
      backgroundColor: entry ? AppColors.navy : AppColors.surface,
      body: Form(
        key: form,
        child: AnimatedSwitcher(
          duration: still ? Duration.zero : gentleCurve.duration,
          reverseDuration: still
              ? Duration.zero
              : const Duration(milliseconds: 180),
          switchInCurve: gentleCurve,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .03),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, ?current],
          ),
          child: KeyedSubtree(
            key: ValueKey(entry ? 'entry' : mode),
            child: entry ? entryView() : stepView(),
          ),
        ),
      ),
    );
  }
}
