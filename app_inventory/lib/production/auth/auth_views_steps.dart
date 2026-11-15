part of '../auth_page.dart';

extension _AuthViewsSteps on _ConnectedAuthPageState {
  Widget _recoveryGuide(int current) {
    const steps = [
      ('Email', ExpressiveShape.sunny8),
      ('Kode', ExpressiveShape.flower8),
      ('Sandi', ExpressiveShape.softBurst),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(color: context.colors.surfaceContainerLow, borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            for (final (i, (label, shape)) in steps.indexed)
              Semantics(
                label:
                    'Langkah ${i + 1}: $label${i == current
                        ? ', saat ini'
                        : i < current
                        ? ', selesai'
                        : ''}',
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShapeIcon(
                      icon: i < current
                          ? Icons.check_rounded
                          : i == current
                          ? Icons.edit_rounded
                          : Icons.circle_outlined,
                      shape: shape,
                      size: 28,
                      fill: i <= current ? context.colors.primary : context.colors.surfaceContainerHighest,
                      foreground: i <= current ? context.colors.onPrimary : context.colors.onSurfaceVariant,
                      iconScale: .5,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: context.text.labelMedium?.copyWith(
                        color: i == current ? context.colors.primary : context.colors.onSurfaceVariant,
                        fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Six-digit verification code for new registration or password recovery.
  AuthStep codeStep() {
    final forgot = purpose == 'forgot_password';
    return AuthStep(
      id: 'code-$purpose',
      stage: 2,
      flow: forgot ? const [1, 2, 3] : const [1, 2],
      index: 1,
      chip: forgot ? 'Lupa sandi' : 'Daftar',
      chipIcon: Icons.pin_outlined,
      onBack: () => switchMode(forgot ? 'forgot' : 'register'),
      top: forgot ? link('Batal', () => switchMode('login')) : link('Masuk', () => switchMode('login')),
      title: forgot ? 'Kode pemulihan' : 'Verifikasi email',
      body: 'Masukkan 6 digit dari email Anda untuk melanjutkan.',
      art: ListenableBuilder(
        listenable: code,
        builder: (context, _) => AuthEnvelopeArt(filled: code.text.length),
      ),
      children: fields([
        if (forgot) ...[_recoveryGuide(1), const SizedBox(height: 18)],
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            email.text.trim(),
            textAlign: TextAlign.center,
            style: context.text.titleSmall?.copyWith(color: context.colors.primary),
          ),
        ),
        OtpCodeField(controller: code, enabled: !working, onSubmitted: submit),
        OtpResend(
          cooldown: cooldown,
          onResend: working ? null : resend,
          onChangeEmail: working
              ? null
              : () => switchMode(switch (purpose) {
                  'forgot_password' => 'forgot',
                  'register' => 'register',
                  _ => 'login',
                }),
        ),
        if (!forgot) rememberToggle(),
      ]),
      action: action('Verifikasi', icon: Icons.check_rounded),
    );
  }

  AuthStep resetStep() {
    final both = Listenable.merge([password, confirmation]);
    bool ready() => PasswordPolicy(password.text).valid && confirmation.text == password.text;
    return AuthStep(
      id: 'reset',
      stage: 3,
      flow: const [1, 2, 3],
      index: 2,
      chip: 'Lupa sandi',
      chipIcon: Icons.lock_reset_rounded,
      top: link('Batal', () => switchMode('login')),
      onBack: () => switchMode('forgot'),
      title: 'Sandi baru',
      body: 'Email ${email.text.trim()} sudah terverifikasi. Buat kata sandi baru.',
      art: ListenableBuilder(
        listenable: both,
        builder: (context, _) => AuthLockArt(locked: ready()),
      ),
      children: fields([
        _recoveryGuide(2),
        const SizedBox(height: 18),
        field(
          password,
          'Kata sandi baru',
          icon: Icons.lock_outline,
          shape: ExpressiveShape.pentagon,
          secret: true,
          min: 8,
        ),
        field(
          confirmation,
          'Ulangi kata sandi',
          icon: Icons.lock_reset_rounded,
          shape: ExpressiveShape.softBurst,
          secret: true,
          min: 8,
          last: true,
        ),
        PasswordStrength(controller: password, confirmation: confirmation),
      ]),
      action: ListenableBuilder(
        listenable: both,
        builder: (context, _) => action('Simpan kata sandi', icon: Icons.check_rounded, enabled: ready()),
      ),
    );
  }
}
