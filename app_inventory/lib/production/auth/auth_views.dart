part of '../auth_page.dart';

extension _AuthViews on _ConnectedAuthPageState {
  List<Widget> messages() => [
    if (error != null || widget.state.error != null)
      AuthMessage(text: error ?? widget.state.error!, error: true),
    if (notice != null) AuthMessage(text: notice!),
  ];

  Widget primary(String label) => PressSpring(
    enabled: !working,
    child: FilledButton(
      onPressed: working ? null : submit,
      child: Text(working ? 'Memproses...' : label),
    ),
  );

  Widget link(String label, VoidCallback onTap) => TextButton(
    onPressed: working ? null : onTap,
    child: Text(label, textAlign: TextAlign.center),
  );

  RememberToggle rememberToggle() => RememberToggle(
    value: remember,
    onChanged: working ? null : (value) => update(() => remember = value),
  );

  /// Login (OTP) and password sign-in share one sheet; the segmented thumb
  /// moves between them.
  Widget entryView() {
    final byPassword = mode == 'password';
    final still = reducedMotion(context);
    final duration = still ? Duration.zero : gentleCurve.duration;
    return AuthEntry(
      children: [
        const Text(
          'Masuk',
          style: TextStyle(
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          byPassword
              ? 'Pakai email dan kata sandi akunmu.'
              : 'Kode sekali pakai dikirim ke email kantormu.',
          style: const TextStyle(fontSize: 15, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        ...messages(),
        AuthSegmented(
          labels: const ['Kode OTP', 'Kata sandi'],
          index: byPassword ? 1 : 0,
          onChanged: working
              ? null
              : (i) => switchMode(i == 1 ? 'password' : 'login'),
        ),
        const SizedBox(height: 20),
        field(
          email,
          'Email kantor',
          hint: 'nama@scitech.id',
          icon: Icons.mail_outline,
        ),
        AnimatedSize(
          duration: duration,
          curve: gentleCurve,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: gentleCurve,
            switchOutCurve: Curves.easeOut,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: byPassword
                ? Column(
                    key: const ValueKey('password'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      field(
                        password,
                        'Kata sandi',
                        icon: Icons.lock_outline,
                        secret: true,
                        min: 6,
                      ),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          rememberToggle(),
                          link('Lupa kata sandi?', () => switchMode('forgot')),
                        ],
                      ),
                    ],
                  )
                : KeyedSubtree(
                    key: const ValueKey('otp'),
                    child: rememberToggle(),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        primary(byPassword ? 'Masuk' : 'Kirim kode OTP'),
        const SizedBox(height: 8),
        if (!byPassword)
          link('Masuk dengan kata sandi', () => switchMode('password')),
        link('Belum punya akun? Daftar', () => switchMode('register')),
      ],
    );
  }

  Widget stepView() {
    void back() => switchMode(mode == 'forgot' ? 'password' : 'login');
    final onBack = working ? null : back;
    final address = email.text.trim();
    return switch (mode) {
      'register' => AuthScreen(
        title: 'Daftar akun',
        subtitle: 'Untuk staf Scitech yang meminjam barang.',
        onBack: onBack,
        children: [
          ...messages(),
          field(name, 'Nama lengkap', hint: 'Sesuai identitas kantor', min: 2),
          field(email, 'Email kantor', hint: 'nama@scitech.id'),
          field(
            department,
            'Tim / divisi (opsional)',
            hint: 'Contoh: Tim Produksi',
            optional: true,
          ),
          field(
            phone,
            'Nomor telepon (opsional)',
            hint: '08xx xxxx xxxx',
            keyboard: TextInputType.phone,
            optional: true,
          ),
          field(
            password,
            'Kata sandi',
            icon: Icons.lock_outline,
            secret: true,
            min: 8,
          ),
          PasswordStrength(controller: password, rules: false),
          primary('Daftar dan verifikasi'),
          const SizedBox(height: 8),
          link('Sudah punya akun? Masuk', () => switchMode('login')),
        ],
      ),
      'forgot' => AuthScreen(
        title: 'Lupa kata sandi?',
        subtitle:
            'Masukkan email akunmu. Kode pemulihan dikirim ke email tersebut.',
        icon: Icons.lock_outline,
        onBack: onBack,
        children: [
          ...messages(),
          field(
            email,
            'Email kantor',
            hint: 'nama@scitech.id',
            icon: Icons.mail_outline,
            helper: 'Belum masuk? Periksa folder spam.',
          ),
          const SizedBox(height: 4),
          primary('Kirim kode pemulihan'),
          const SizedBox(height: 8),
          link('Kembali ke login', () => switchMode('login')),
        ],
      ),
      'code' => AuthScreen(
        title: switch (purpose) {
          'register' => 'Verifikasi email',
          'forgot_password' => 'Kode pemulihan',
          _ => 'Masukkan kode',
        },
        subtitle: 'Kode 6 digit dikirim ke',
        icon: Icons.mail_outline,
        onBack: onBack,
        children: [
          Transform.translate(
            offset: const Offset(0, -14),
            child: AuthEmailChip(email: address),
          ),
          const SizedBox(height: 6),
          ...messages(),
          OtpCodeField(
            controller: code,
            enabled: !working,
            onSubmitted: submit,
          ),
          OtpResend(cooldown: cooldown, onResend: working ? null : resend),
          if (purpose != 'forgot_password') rememberToggle(),
          const SizedBox(height: 12),
          primary('Verifikasi'),
        ],
      ),
      _ => AuthScreen(
        title: 'Kata sandi baru',
        subtitle: 'Email sudah terverifikasi.',
        onBack: onBack,
        children: [
          Transform.translate(
            offset: const Offset(0, -10),
            child: AuthEmailChip(email: address),
          ),
          const SizedBox(height: 6),
          ...messages(),
          field(
            password,
            'Kata sandi baru',
            icon: Icons.lock_outline,
            secret: true,
            min: 8,
          ),
          field(
            confirmation,
            'Ulangi kata sandi',
            icon: Icons.lock_outline,
            secret: true,
            min: 8,
          ),
          PasswordStrength(controller: password, confirmation: confirmation),
          primary('Simpan kata sandi'),
        ],
      ),
    };
  }
}
