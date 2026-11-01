import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'item_card.dart';
import 'team_loan_tile.dart';

/// Bottom sheet with the item's photo, tag, live stock and who uses it.
Future<void> showItemDetails(
  BuildContext context, {
  required AppState app,
  required InventoryItem item,
  required Widget Function(String) picture,
  required void Function(InventoryItem) onBorrow,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  sheetAnimationStyle: sheetAnimation(context),
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (context) {
    final usage = app.activity.where((l) => l.itemId == item.id).toList();
    final colleagues = usage
        .where((l) => !l.isMine)
        .fold<int>(0, (sum, l) => sum + l.quantity);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ItemPhoto(
                item: item,
                picture: picture,
                height: 200,
                iconSize: 72,
                tags: false,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: AssetTag(item.id, dark: true),
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.category,
                style: const TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Stat(
                    value: item.available,
                    label: 'tersedia',
                    tone: item.canBorrow ? Tone.ok : Tone.neutral,
                  ),
                  const SizedBox(width: 8),
                  _Stat(value: colleagues, label: 'dipakai rekan'),
                  const SizedBox(width: 8),
                  _Stat(value: item.total, label: 'total unit'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.description.isEmpty
                    ? 'Belum ada deskripsi barang.'
                    : item.description,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Text(
                'Stok tersedia: ${item.available} dari ${item.total} unit',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (!item.enabled)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StatusPill(
                      'Peminjaman dinonaktifkan',
                      tone: Tone.bad,
                    ),
                  ),
                ),
              if (usage.isNotEmpty) const SizedBox(height: 14),
              for (final loan in usage)
                TeamLoanTile(loan: loan, color: AppColors.paper),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: item.canBorrow
                    ? () {
                        Navigator.pop(context);
                        onBorrow(item);
                      }
                    : null,
                child: const Text('Ajukan peminjaman'),
              ),
            ],
          ),
        ),
      ),
    );
  },
);

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.tone = Tone.neutral,
  });
  final int value;
  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = toneColors(tone);
    final fg = tone == Tone.neutral ? AppColors.ink : colors.fg;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
