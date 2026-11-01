import 'package:flutter/material.dart';
import '../../ui/tokens.dart';
import 'request_parts.dart';

const purposePresets = [
  'Meeting & Presentasi',
  'Operasional & Proyek',
  'Maintenance & Perbaikan',
  'Pengujian',
  'Acara Internal',
];

/// Keperluan: horizontally scrollable quick chips that fill the field, plus
/// the free-text purpose.
class PurposeCard extends StatelessWidget {
  const PurposeCard({required this.controller, required this.busy, super.key});
  final TextEditingController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) => RequestCard(
    title: 'Keperluan',
    trailing: const Text(
      'geser untuk lainnya',
      style: TextStyle(fontSize: 12, color: AppColors.muted),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final text in purposePresets)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(text),
                      selected: controller.text.trim() == text,
                      backgroundColor: AppColors.paper,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: controller.text.trim() == text
                            ? Colors.white
                            : AppColors.ink,
                      ),
                      onSelected: busy ? null : (_) => controller.text = text,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          enabled: !busy,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Jelaskan untuk apa barang akan digunakan...',
          ),
        ),
      ],
    ),
  );
}
