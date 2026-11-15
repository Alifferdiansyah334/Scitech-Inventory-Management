part of '../auth_page.dart';

extension _AuthViews on _ConnectedAuthPageState {
  List<Widget> messages() => [
    if (error != null || widget.state.error != null) AuthMessage(text: error ?? widget.state.error!, error: true),
    if (notice != null) AuthMessage(text: notice!),
  ];

  /// Shared Material button feedback stays active for every auth action.
  Widget action(String label, {IconData icon = Icons.arrow_forward_rounded, bool enabled = true}) => FilledButton(
    key: actionKey,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(60),
      padding: const EdgeInsets.fromLTRB(24, 10, 12, 10),
    ),
    onPressed: working || !enabled ? null : submit,
    child: Row(
      children: [
        Expanded(child: Text(working ? 'Memproses...' : label, textAlign: TextAlign.center)),
        const SizedBox(width: 12),
        if (working)
          const SizedBox.square(dimension: 36, child: ExpressiveLoadingIndicator(size: 28))
        else
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: context.colors.onPrimary.withValues(alpha: .15), shape: BoxShape.circle),
            child: Icon(icon, size: 22),
          ),
      ],
    ),
  );

  Widget link(String label, VoidCallback onTap) => TextButton(
    onPressed: working ? null : onTap,
    child: Text(label, textAlign: TextAlign.center),
  );

  /// "Belum punya akun? Daftar" under the primary button: a quiet question
  /// and the action in the button colour.
  Widget footer(String question, String label, VoidCallback onTap) => TextButton(
    onPressed: working ? null : onTap,
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$question ',
            style: TextStyle(color: context.colors.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
          TextSpan(text: label),
        ],
      ),
      textAlign: TextAlign.center,
    ),
  );

  RememberToggle rememberToggle() =>
      RememberToggle(value: remember, onChanged: working ? null : (value) => update(() => remember = value));

  /// Fields of one mode; the key drops field state (errors) when it changes.
  List<Widget> fields(List<Widget> children) => [
    KeyedSubtree(
      key: ValueKey(mode),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...messages(), ...children]),
    ),
  ];

  Widget info(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
        ),
      ],
    ),
  );

  AuthStep currentStep() => switch (mode) {
    'login' => entryStep(),
    'register' => registerStep(),
    'forgot' => forgotStep(),
    'code' => codeStep(),
    _ => resetStep(),
  };

  /// Sign-in: email and password directly (no OTP login option).
  AuthStep entryStep() => AuthStep(
    id: 'entry',
    stage: 0,
    flow: const [0],
    index: 0,
    chip: 'Masuk',
    chipIcon: Icons.login_rounded,
    top: link('Daftar', () => switchMode('register')),
    footer: footer('Belum punya akun?', 'Daftar', () => switchMode('register')),
    title: 'Masuk ke inventaris',
    body: 'Perlengkapan kerja, dalam satu tempat.',
    art: const AuthEquipmentArt(),
    children: fields([
      field(
        email,
        'Email kantor',
        hint: 'Email yang terdaftar',
        icon: Icons.mail_outline,
        shape: ExpressiveShape.sunny8,
      ),
      field(
        password,
        'Kata sandi',
        icon: Icons.lock_outline,
        shape: ExpressiveShape.pentagon,
        secret: true,
        min: 6,
        last: true,
      ),
      rememberToggle(),
      Align(alignment: AlignmentDirectional.centerEnd, child: link('Lupa kata sandi?', () => switchMode('forgot'))),
    ]),
    action: action('Masuk'),
  );

  AuthStep registerStep() => AuthStep(
    id: 'register',
    stage: 1,
    flow: const [1, 2],
    index: 0,
    chip: 'Daftar',
    chipIcon: Icons.person_add_alt_rounded,
    top: link('Masuk', () => switchMode('login')),
    onBack: () => switchMode('login'),
    footer: footer('Sudah punya akun?', 'Masuk', () => switchMode('login')),
    title: 'Daftar akun',
    body: 'Untuk staf Scitech yang meminjam perlengkapan operasional.',
    art: const AuthBadgeArt(),
    children: fields([
      field(name, 'Nama lengkap', hint: 'Sesuai identitas kantor', icon: Icons.person_outline, min: 2),
      field(
        email,
        'Email kantor',
        hint: 'Email untuk verifikasi akun',
        icon: Icons.mail_outline,
        shape: ExpressiveShape.sunny8,
      ),
      field(
        phone,
        'Nomor telepon (opsional)',
        hint: '08xx xxxx xxxx',
        icon: Icons.call_outlined,
        shape: ExpressiveShape.clover4,
        keyboard: TextInputType.phone,
        optional: true,
      ),
      field(
        password,
        'Kata sandi',
        icon: Icons.lock_outline,
        shape: ExpressiveShape.pentagon,
        secret: true,
        min: 8,
        last: true,
      ),
      PasswordStrength(controller: password, rules: false),
    ]),
    action: action('Daftar dan verifikasi'),
  );

  AuthStep forgotStep() => AuthStep(
    id: 'forgot',
    stage: 1,
    flow: const [1, 2, 3],
    index: 0,
    chip: 'Lupa sandi',
    chipIcon: Icons.key_rounded,
    onBack: () => switchMode('login'),
    top: null,
    title: 'Lupa kata sandi?',
    body: 'Kita bantu pulihkan akses akun Anda. Mulai dari email yang terdaftar.',
    art: const AuthKeyArt(),
    children: fields([
      _recoveryGuide(0),
      const SizedBox(height: 14),
      field(
        email,
        'Email kantor',
        hint: 'Email yang terdaftar',
        icon: Icons.mail_outline,
        shape: ExpressiveShape.sunny8,
        last: true,
      ),
      info('Kami akan mengirim kode 6 digit untuk memverifikasi email Anda.'),
    ]),
    action: action('Kirim kode pemulihan', icon: Icons.send_rounded),
  );
}
