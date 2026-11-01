import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'request_parts.dart';

/// Success state of the request: popping check on navy, an asset-label
/// receipt overlapping the header, waiting status and next actions.
class RequestSuccessView extends StatelessWidget {
  const RequestSuccessView({
    required this.item,
    required this.quantity,
    required this.presetDays,
    required this.due,
    required this.purpose,
    required this.onWhatsApp,
    required this.onDone,
    super.key,
  });
  final InventoryItem item;
  final int quantity;

  /// Chosen preset duration, or null when a custom date was picked.
  final int? presetDays;
  final DateTime due;
  final String purpose;

  /// Null hides the WhatsApp action (switch off or no admin contacts).
  final VoidCallback? onWhatsApp;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.navy,
            padding: EdgeInsets.fromLTRB(24, insets.top + 36, 24, 36),
            child: centered(
              const Column(
                children: [
                  _SuccessCheck(),
                  SizedBox(height: 20),
                  Text(
                    'Pengajuan berhasil!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Permohonan sudah tercatat dan menunggu persetujuan admin. Pantau perkembangannya di Pinjaman saya.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.navyMuted, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                // Overlap the navy block by 1 px so no sub-pixel seam shows.
                top: -1,
                left: 0,
                right: 0,
                height: 89,
                child: ColoredBox(
                  color: AppColors.navy,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadii.sheet),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _Receipt(
                      item: item,
                      quantity: quantity,
                      presetDays: presetDays,
                      due: due,
                      purpose: purpose,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + insets.bottom),
            child: centered(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: AppColors.accentText,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Menunggu persetujuan admin',
                            style: TextStyle(
                              color: AppColors.accentText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (onWhatsApp != null) ...[
                    OutlinedButton.icon(
                      onPressed: onWhatsApp,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Kirim notifikasi WhatsApp ke admin'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'WhatsApp terbuka dengan pesan pengajuan yang sudah disiapkan. Tekan Kirim di WhatsApp untuk mengirimnya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                  ],
                  FilledButton(
                    onPressed: onDone,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: const Text('Lihat status pinjaman'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White check circle that pops once (0.8 → 1) with the bouncy spring.
class _SuccessCheck extends StatefulWidget {
  const _SuccessCheck();

  @override
  State<_SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<_SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController scale = AnimationController.unbounded(
    vsync: this,
    value: 0.8,
  );
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (reducedMotion(context)) {
      scale.value = 1;
    } else {
      springTo(scale, 1, AppSprings.bouncy);
    }
  }

  @override
  void dispose() {
    scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Berhasil',
    child: ScaleTransition(
      scale: scale,
      child: Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 44, color: AppColors.navy),
      ),
    ),
  );
}

/// Receipt styled as a punched asset label, slightly rotated.
class _Receipt extends StatelessWidget {
  const _Receipt({
    required this.item,
    required this.quantity,
    required this.presetDays,
    required this.due,
    required this.purpose,
  });
  final InventoryItem item;
  final int quantity;
  final int? presetDays;
  final DateTime due;
  final String purpose;

  Widget row(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -2 * math.pi / 180,
    child: Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330A1428),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.paper,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Center(child: AssetTag(item.id)),
          const SizedBox(height: 14),
          const DashedLine(),
          const SizedBox(height: 4),
          row('Jumlah', '$quantity unit'),
          if (presetDays != null) row('Lama pinjam', '$presetDays hari'),
          row('Batas kembali', longDate(due)),
          row('Keperluan', purpose),
        ],
      ),
    ),
  );
}

/// Dashed perforation line drawn across the receipt.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 1,
    width: double.infinity,
    child: CustomPaint(painter: _DashPainter()),
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.control
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}
