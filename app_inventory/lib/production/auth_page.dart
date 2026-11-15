import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/password_policy.dart';
import '../ui/controls.dart';
import '../ui/physics.dart';
import '../ui/shapes.dart';
import '../ui/theme.dart';
import 'auth/auth_entry.dart';
import 'auth/auth_hero.dart';
import 'auth/auth_parts.dart';
import 'auth/auth_stages.dart';
import 'auth/otp_input.dart';
import 'password_strength.dart';

part 'auth/auth_views.dart';

part 'auth/auth_views_steps.dart';

class ConnectedAuthPage extends StatefulWidget {
  const ConnectedAuthPage({required this.state, super.key});
  final AppState state;
  @override
  State<ConnectedAuthPage> createState() => _ConnectedAuthPageState();
}

class _ConnectedAuthPageState extends State<ConnectedAuthPage> {
  final form = GlobalKey<FormState>();
  final actionKey = GlobalKey();
  final email = TextEditingController(), password = TextEditingController(), name = TextEditingController();
  final phone = TextEditingController(), code = TextEditingController();
  final confirmation = TextEditingController();
  String mode = 'login', purpose = 'login';
  String? error, notice;
  bool working = false, remember = true, obscure = true;
  int cooldown = 0;
  Timer? timer;
  @override
  void dispose() {
    timer?.cancel();
    for (final c in [email, password, name, phone, code, confirmation]) {
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

  /// Success after a request: a firm tap and shapes thrown from the pill.
  void celebrate() {
    HapticFeedback.mediumImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final origin = actionKey.currentContext;
      if (!mounted || origin == null) return;
      final scheme = context.colors;
      ShapeBurst.show(
        context,
        origin: ShapeBurst.centerOf(origin),
        colors: [scheme.primary, scheme.secondary, scheme.tertiary, context.palette.hero],
      );
    });
  }

  Future<void> submit() async {
    if (working) return;
    if (!form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      working = true;
      error = null;
      notice = null;
    });
    final address = email.text.trim().toLowerCase();
    try {
      switch (mode) {
        case 'login':
          await widget.state.authenticate({'email': address, 'password': password.text}, remember: remember);
        case 'forgot':
          purpose = 'forgot_password';
          await widget.state.sendCode(address, purpose);
          mode = 'code';
          countdown();
          notice = 'Jika akun tersedia, kode dikirim ke email Anda. Periksa juga folder spam.';
          celebrate();
        case 'register':
          await widget.state.registerAccount({
            'email': address,
            'password': password.text,
            'full_name': name.text.trim(),
            'phone': phone.text.trim(),
          });
          purpose = 'register';
          mode = 'code';
          countdown();
          notice = 'Masukkan kode dari email untuk mengaktifkan akun.';
          celebrate();
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
            await widget.state.authenticateOtp(address, code.text, purpose, remember: remember);
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
          mode = 'login';
          password.clear();
          code.clear();
          notice = 'Kata sandi berhasil diubah. Silakan masuk.';
          celebrate();
      }
    } catch (e) {
      error = e is FormatException ? e.message : e.toString();
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> resend() async {
    if (working || cooldown > 0) return;
    setState(() {
      working = true;
      error = null;
      notice = null;
    });
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

  /// Compact auth field; [last] submits the step from the keyboard.
  Widget field(
    TextEditingController controller,
    String label, {
    required IconData icon,
    ExpressiveShape shape = ExpressiveShape.cookie9,
    String? hint,
    bool secret = false,
    bool optional = false,
    bool last = false,
    TextInputType? keyboard,
    int min = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ExpressiveTextField(
      controller: controller,
      label: label,
      icon: icon,
      shape: shape,
      hint: hint,
      enabled: !working,
      obscureText: secret && obscure,
      capitalization: controller == name ? TextCapitalization.words : TextCapitalization.none,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => submit() : null,
      keyboardType: keyboard ?? (controller == email ? TextInputType.emailAddress : TextInputType.text),
      autofillHints: controller == email
          ? const [AutofillHints.email]
          : secret
          ? [
              const ['register', 'reset'].contains(mode) ? AutofillHints.newPassword : AutofillHints.password,
            ]
          : controller == name
          ? const [AutofillHints.name]
          : controller == phone
          ? const [AutofillHints.telephoneNumber]
          : null,
      trailing: secret
          ? IconButton(
              tooltip: obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
              isSelected: !obscure,
              onPressed: working ? null : () => setState(() => obscure = !obscure),
              icon: const Icon(Icons.visibility_outlined),
              selectedIcon: const Icon(Icons.visibility_off_outlined),
            )
          : null,
      validator: (value) {
        if (controller == password && const ['register', 'reset'].contains(mode)) {
          return PasswordPolicy(value ?? '').error;
        }
        final text = value?.trim() ?? '';
        if (optional && text.isEmpty) return null;
        if (text.isEmpty) {
          return controller == email ? 'Masukkan email kantor Anda.' : 'Wajib diisi.';
        }
        if (text.length < min) return 'Isi minimal $min karakter.';
        if (controller == email && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())) {
          return 'Masukkan email yang valid.';
        }
        return null;
      },
    ),
  );

  /// Where system back goes from the current step; null on the sign-in
  /// entry, which leaves the app.
  String? get backTarget => switch (mode) {
    'register' || 'forgot' => 'login',
    'code' => purpose == 'forgot_password' ? 'forgot' : 'register',
    'reset' => 'forgot',
    _ => null,
  };

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: backTarget == null,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !working && backTarget != null) switchMode(backTarget!);
    },
    child: Form(
      key: form,
      child: AuthFrame(step: currentStep()),
    ),
  );
}
