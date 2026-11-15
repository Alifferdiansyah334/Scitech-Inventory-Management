import 'package:flutter/material.dart';
import '../../ui/controls.dart';
import '../../ui/shapes.dart';
import '../../ui/theme.dart';

const purposePresets = [
  'Meeting & Presentasi',
  'Operasional & Proyek',
  'Maintenance & Perbaikan',
  'Pengujian',
  'Acara Internal',
];

/// One icon and shape per preset, in [purposePresets] order.
const _presetLooks = [
  (Icons.co_present_outlined, ExpressiveShape.cookie9),
  (Icons.work_outline_rounded, ExpressiveShape.gem),
  (Icons.build_outlined, ExpressiveShape.pentagon),
  (Icons.science_outlined, ExpressiveShape.sunny8),
  (Icons.celebration_outlined, ExpressiveShape.flower8),
];

/// Shortest purpose the request accepts (after trimming).
const purposeMinLength = 5;

String? validatePurpose(String? value) =>
    (value ?? '').trim().length < purposeMinLength ? 'Isi keperluan minimal $purposeMinLength karakter.' : null;

/// Keperluan (article editor field): the expressive editor card, at least
/// three lines, then the suggestions as filter chips that fill it.
class PurposeSection extends StatelessWidget {
  const PurposeSection({required this.controller, required this.busy, super.key});
  final TextEditingController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExpressiveTextField(
        controller: controller,
        label: 'Keperluan',
        icon: Icons.notes_rounded,
        shape: ExpressiveShape.flower8,
        hint: 'Contoh: presentasi proyek di ruang rapat',
        minLines: 3,
        maxLines: 6,
        maxLength: 500,
        enabled: !busy,
        showWordCount: false,
        validator: validatePurpose,
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          'Saran keperluan',
          style: context.text.labelLarge?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ),
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < purposePresets.length; i++)
              // Long labels at large text sizes shrink instead of overflowing.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: ExpressiveFilterChip(
                  label: purposePresets[i],
                  icon: _presetLooks[i].$1,
                  shape: _presetLooks[i].$2,
                  selected: controller.text.trim() == purposePresets[i],
                  onSelected: () {
                    if (busy) return;
                    controller.value = TextEditingValue(
                      text: purposePresets[i],
                      selection: TextSelection.collapsed(offset: purposePresets[i].length),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
