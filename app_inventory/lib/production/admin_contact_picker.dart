import 'package:flutter/material.dart';
import '../models.dart';
import '../ui/springs.dart';
import '../ui/tokens.dart';

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
  final letters = parts.take(2).map((s) => s[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}

Future<AdminContact?> chooseAdminContact(
  BuildContext context,
  List<AdminContact> contacts,
) {
  return showModalBottomSheet<AdminContact>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    sheetAnimationStyle: sheetAnimation(context),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hubungi admin',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih penerima pesan WhatsApp Anda.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              for (final (i, contact) in contacts.indexed)
                SpringReveal(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PressSpring(
                      child: ListTile(
                        tileColor: AppColors.paper,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.navySoft,
                          foregroundColor: AppColors.navy,
                          child: Text(
                            _initials(contact.name),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          contact.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '+${contact.phone}',
                          style: const TextStyle(
                            fontFamily: AppFonts.mono,
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chat_outlined,
                          color: AppColors.navy,
                        ),
                        onTap: () => Navigator.pop(context, contact),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
