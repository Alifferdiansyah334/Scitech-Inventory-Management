import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/appearance.dart';
import '../../core/image_compressor.dart';
import '../../core/password_policy.dart';
import '../../ui/avatars.dart';
import '../../ui/controls.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'actions.dart';
import 'avatar_picker.dart';

part 'profile_edit_state.dart';

/// 'Edit profil' (AgroLens article editor): picture (device photo or
/// illustrated preset, with a frame shape) stored on this device, the
/// profile fields saved to the server and an optional password change.
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({required this.actions, super.key});
  final WorkspaceActions actions;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends _ProfileEditFields {
  @override
  Widget build(BuildContext context) {
    final current = choice;
    final text = Theme.of(context).textTheme;
    void pick(AvatarChoice next) => setState(() => _choice = next);
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profil')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _photoCard(current, pick),
                gap,
                EditorCard(
                  title: 'Pilih avatar',
                  child: AvatarPresetGrid(choice: current, onChanged: pick),
                ),
                gap,
                EditorCard(
                  title: 'Bentuk bingkai',
                  trailing: frameName(current.frame),
                  child: FramePicker(choice: current, onChanged: pick),
                ),
                const SizedBox(height: 20),
                ExpressiveTextField(
                  controller: name,
                  label: 'Nama tampilan',
                  icon: Icons.person_outline_rounded,
                  shape: ExpressiveShape.clover4,
                  maxLength: 120,
                  textInputAction: TextInputAction.next,
                  capitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => _validate(v, min: 2),
                ),
                gap,
                ExpressiveTextField(
                  controller: department,
                  label: 'Tim / divisi (opsional)',
                  icon: Icons.groups_outlined,
                  shape: ExpressiveShape.gem,
                  maxLength: 120,
                  textInputAction: TextInputAction.next,
                  validator: (v) => _validate(v, min: 0, optional: true),
                ),
                gap,
                ExpressiveTextField(
                  controller: phone,
                  label: 'Nomor telepon (opsional)',
                  icon: Icons.call_outlined,
                  shape: ExpressiveShape.sunny8,
                  maxLength: 30,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: (v) => _validate(v, min: 0, optional: true),
                ),
                const SizedBox(height: 24),
                Semantics(header: true, child: Text('Ganti kata sandi', style: text.titleMedium)),
                const SizedBox(height: 2),
                Text(
                  'Kosongkan bila tidak diganti. Setelah diganti, Anda akan diminta masuk kembali.',
                  style: text.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                ExpressiveTextField(
                  controller: currentPassword,
                  label: 'Kata sandi saat ini',
                  icon: Icons.lock_outline_rounded,
                  shape: ExpressiveShape.cookie12,
                  obscureText: hidePasswords,
                  capitalization: TextCapitalization.none,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  trailing: _passwordToggle(),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => _changingPassword && (v ?? '').isEmpty ? 'Isi kata sandi saat ini.' : null,
                ),
                gap,
                ExpressiveTextField(
                  controller: newPassword,
                  label: 'Kata sandi baru',
                  icon: Icons.key_rounded,
                  shape: ExpressiveShape.flower8,
                  obscureText: hidePasswords,
                  capitalization: TextCapitalization.none,
                  maxLength: 128,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  trailing: _passwordToggle(),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => _changingPassword ? PasswordPolicy(v ?? '').error : null,
                ),
                gap,
                ExpressiveTextField(
                  controller: confirmPassword,
                  label: 'Konfirmasi kata sandi baru',
                  icon: Icons.verified_user_outlined,
                  shape: ExpressiveShape.pentagon,
                  obscureText: hidePasswords,
                  capitalization: TextCapitalization.none,
                  maxLength: 128,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  trailing: _passwordToggle(),
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _save(),
                  validator: (v) =>
                      _changingPassword && v != newPassword.text ? 'Konfirmasi kata sandi tidak sama.' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 528),
              child: ListenableBuilder(
                listenable: widget.actions.app,
                builder: (context, _) {
                  final busy = saving || processing || widget.actions.locked;
                  final scheme = Theme.of(context).colorScheme;
                  return FilledButton.icon(
                    key: _saveKey,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    onPressed: busy ? null : _save,
                    icon: saving
                        ? ExpressiveLoadingIndicator(size: 20, color: AppColors.onDisabled)
                        : ShapeIcon(
                            icon: Icons.check_rounded,
                            shape: ExpressiveShape.cookie9,
                            size: 28,
                            fill: scheme.onPrimary,
                            foreground: scheme.primary,
                            iconScale: .6,
                          ),
                    label: Text(saving ? 'Menyimpan...' : 'Simpan'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Author photo area of the AgroLens editor: the picture in its frame
  /// (tap for the gallery), where it is kept, and camera / gallery / remove.
  Widget _photoCard(AvatarChoice current, ValueChanged<AvatarChoice> pick) {
    final text = Theme.of(context).textTheme;
    final hasPhoto = current.photo != null;
    return EditorCard(
      title: 'Foto profil',
      trailing: hasPhoto ? 'Foto' : 'Avatar',
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Semantics(
            button: true,
            label: 'Pilih foto dari galeri',
            child: PressSpring(
              squash: .12,
              scale: .92,
              child: GestureDetector(
                onTap: processing ? null : () => _pick(ImageSource.gallery),
                child: ProfileAvatar(
                  preset: current.presetSpec,
                  photo: current.photo,
                  frame: current.frame,
                  size: 96,
                  semanticLabel: 'Pratinjau foto profil',
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Foto tersimpan di perangkat ini', style: text.bodySmall?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: processing || !_cameraAvailable ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Kamera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: processing ? null : () => _pick(ImageSource.gallery),
                      icon: processing
                          ? ExpressiveLoadingIndicator(size: 20, color: AppColors.ink)
                          : const Icon(Icons.image_outlined),
                      label: const Text('Galeri'),
                    ),
                    if (hasPhoto)
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        onPressed: processing ? null : () => pick(current.copyWith(clearPhoto: true)),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Hapus foto'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
