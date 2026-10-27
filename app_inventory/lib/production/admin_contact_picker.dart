import 'package:flutter/material.dart';
import '../models.dart';

Future<AdminContact?> chooseAdminContact(
  BuildContext context,
  List<AdminContact> contacts,
) {
  return showModalBottomSheet<AdminContact>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hubungi admin',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('Pilih penerima pesan WhatsApp Anda.'),
              const SizedBox(height: 16),
              for (final contact in contacts)
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.chat_outlined)),
                  title: Text(contact.name),
                  subtitle: Text('+${contact.phone}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, contact),
                ),
              const SizedBox(height: 8),
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
