part of 'profile_edit.dart';

/// Fields, photo picking and saving of [ProfileEditPage]; the page state
/// adds the layout.
abstract class _ProfileEditFields extends State<ProfileEditPage> {
  final form = GlobalKey<FormState>();
  final _saveKey = GlobalKey();
  late final user = widget.actions.app.profile!;
  late final name = TextEditingController(text: user.name);
  late final department = TextEditingController(text: user.department);
  late final phone = TextEditingController(text: user.phone);
  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  final picker = ImagePicker();
  AvatarChoice? _choice;
  bool processing = false, saving = false, hidePasswords = true;

  AvatarChoice get choice => _choice ??= AppearanceScope.of(context).avatarFor(user.id);

  bool get _changingPassword =>
      currentPassword.text.isNotEmpty || newPassword.text.isNotEmpty || confirmPassword.text.isNotEmpty;

  @override
  void dispose() {
    for (final c in [name, department, phone, currentPassword, newPassword, confirmPassword]) {
      c.dispose();
    }
    super.dispose();
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  bool get _cameraAvailable {
    try {
      return picker.supportsImageSource(ImageSource.camera);
    } catch (_) {
      return false;
    }
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => processing = true);
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null) return;
      final square = await compute(squareProfilePhoto, await picked.readAsBytes());
      if (!mounted) return;
      if (square == null) {
        _message('Foto tidak dapat dibaca. Pilih foto lain.');
        return;
      }
      final small = await ImageCompressor.compressBytes(square);
      if (mounted) setState(() => _choice = choice.copyWith(photo: small));
    } catch (_) {
      if (mounted) _message('Foto tidak dapat diambil. Periksa izin kamera atau galeri.');
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  String? _validate(String? value, {required int min, bool optional = false}) {
    final text = value?.trim() ?? '';
    if (optional && text.isEmpty) return null;
    if (text.length < min) return 'Isi minimal $min karakter.';
    return null;
  }

  void _celebrate() {
    HapticFeedback.mediumImpact();
    final origin = _saveKey.currentContext;
    if (origin == null) return;
    final scheme = Theme.of(context).colorScheme;
    ShapeBurst.show(
      context,
      origin: ShapeBurst.centerOf(origin),
      colors: [scheme.primary, scheme.secondaryContainer, scheme.tertiary, scheme.primaryContainer],
    );
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    final actions = widget.actions;
    AppearanceScope.of(context).setAvatar(user.id, choice);
    final values = {'full_name': name.text.trim(), 'department': department.text.trim(), 'phone': phone.text.trim()};
    final current = actions.app.profile ?? user;
    final changed =
        values['full_name'] != current.name ||
        values['department'] != current.department ||
        values['phone'] != current.phone;
    final password = _changingPassword;
    if (!changed && !password) {
      _celebrate();
      actions.message('Perubahan tersimpan.');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => saving = true);
    var saved = false;
    await actions.perform(() async {
      if (changed) await actions.app.updateProfile(values);
      if (password) {
        await actions.app.api.request(
          'api/mobile/auth/password',
          method: 'POST',
          data: {'currentPassword': currentPassword.text, 'newPassword': newPassword.text},
        );
        await actions.app.signOut(remote: false);
      }
      saved = true;
    }, success: password ? 'Kata sandi diubah. Silakan masuk kembali.' : 'Perubahan tersimpan.');
    if (!mounted) return;
    setState(() => saving = false);
    if (saved) {
      _celebrate();
      Navigator.of(context).pop();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Widget _passwordToggle() => IconButton(
    tooltip: hidePasswords ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
    onPressed: () => setState(() => hidePasswords = !hidePasswords),
    icon: Icon(hidePasswords ? Icons.visibility_outlined : Icons.visibility_off_outlined),
  );
}
