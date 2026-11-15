import 'package:flutter/material.dart';
import '../models.dart';
import '../ui/components.dart';
import '../ui/shapes.dart';
import '../ui/springs.dart';
import '../ui/theme.dart';

/// Shapes the admins keep in the picker, in order.
const _adminShapes = [
  ExpressiveShape.cookie9,
  ExpressiveShape.flower8,
  ExpressiveShape.clover4,
  ExpressiveShape.sunny8,
];

/// AgroLens sheet (palette sheet recipe): title and description, then one
/// connected link row per configured admin. Resolves to the chosen contact,
/// or null when dismissed.
Future<AdminContact?> chooseAdminContact(BuildContext context, List<AdminContact> contacts) {
  return showModalBottomSheet<AdminContact>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: sheetAnimation(context),
    constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * .85),
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text('Hubungi admin', style: context.text.titleLarge)),
            const SizedBox(height: 4),
            Text(
              'Pilih penerima pesan WhatsApp Anda.',
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (contacts.isEmpty)
              const StateMessage(
                title: 'Kontak admin belum tersedia',
                message: 'Belum ada nomor admin yang dapat dihubungi.',
                icon: Icons.contact_phone_outlined,
              )
            else
              LinkGroup(
                children: [
                  for (final (i, contact) in contacts.indexed)
                    LinkTile(
                      icon: Icons.support_agent_rounded,
                      shape: _adminShapes[i % _adminShapes.length],
                      title: contact.name,
                      subtitle: '+${contact.phone}',
                      onTap: () => Navigator.pop(context, contact),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    ),
  );
}
