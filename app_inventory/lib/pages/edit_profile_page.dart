import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/profile_store.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final imagePicker = ImagePicker();
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController departmentController;

  @override
  void initState() {
    super.initState();
    final profile = ProfileStore.instance.profile;
    nameController = TextEditingController(text: profile.name);
    emailController = TextEditingController(text: profile.email);
    departmentController = TextEditingController(text: profile.department);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    departmentController.dispose();
    super.dispose();
  }

  void save() {
    if (nameController.text.trim().isEmpty ||
        !emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan email harus diisi dengan benar'),
        ),
      );
      return;
    }

    final profile = ProfileStore.instance.profile;
    profile.name = nameController.text.trim();
    profile.email = emailController.text.trim();
    profile.department = departmentController.text.trim();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil diperbarui pada sesi aplikasi ini')),
    );
  }

  Future<void> pickProfilePhoto() async {
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );

    if (image == null) return;
    setState(() {
      ProfileStore.instance.profile.avatarPath = image.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFFEEF2FF),
                  backgroundImage:
                      ProfileStore.instance.profile.avatarPath == null
                      ? null
                      : FileImage(
                          File(ProfileStore.instance.profile.avatarPath!),
                        ),
                  child: ProfileStore.instance.profile.avatarPath == null
                      ? Text(
                          ProfileStore.instance.profile.initials,
                          style: const TextStyle(
                            color: Color(0xFF4F46E5),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton(
                    key: const ValueKey('edit_profile_photo_button'),
                    tooltip: 'Ubah foto profil',
                    onPressed: pickProfilePhoto,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _FieldLabel(label: 'NAMA LENGKAP'),
          const SizedBox(height: 8),
          _ProfileField(
            controller: nameController,
            icon: Icons.person_outline,
            hint: 'Nama lengkap',
          ),
          const SizedBox(height: 18),
          _FieldLabel(label: 'EMAIL'),
          const SizedBox(height: 8),
          _ProfileField(
            controller: emailController,
            icon: Icons.email_outlined,
            hint: 'nama@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          _FieldLabel(label: 'DEPARTEMEN'),
          const SizedBox(height: 8),
          _ProfileField(
            controller: departmentController,
            icon: Icons.badge_outlined,
            hint: 'Departemen (opsional)',
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Simpan Perubahan'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Foto profil dipilih dari galeri perangkat dan berlaku selama sesi aplikasi ini.',
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    ),
  );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
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
  );
}
