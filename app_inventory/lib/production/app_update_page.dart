import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/brand.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/app_updates.dart';
import '../ui/components.dart';
import '../ui/motion.dart';
import '../ui/physics.dart';
import '../ui/progress.dart';
import '../ui/shapes.dart';
import '../ui/theme.dart';
import '../ui/tokens.dart';
import '../ui/widgets.dart';

part 'app_update/update_views.dart';

/// App update in the AgroLens result anatomy: a tall shape header with a
/// rounded bottom, a status card overlapping it with a wavy ring, sections
/// (version, release notes, how packages are checked) and a bottom action
/// bar.
class AppUpdatePage extends StatefulWidget {
  const AppUpdatePage({required this.api, super.key});
  final ApiClient api;
  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage> {
  late final AppUpdates updates = AppUpdates(widget.api);
  bool permissionRequired = false;
  @override
  void initState() {
    super.initState();
    updates.check();
  }

  @override
  void dispose() {
    updates.dispose();
    super.dispose();
  }

  Future<void> install() async {
    if (updates.isWeb) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          icon: const ShapeIcon(icon: Icons.restart_alt_rounded, shape: ExpressiveShape.sunny8, size: 48),
          title: const Text('Muat versi terbaru?'),
          content: const Text(
            'Pastikan perubahan Anda sudah tersimpan. Aplikasi akan dimuat ulang; data di server tetap tersimpan.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Muat ulang')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final result = await updates.install();
    if (mounted) {
      setState(() => permissionRequired = result == 'permission_required');
    }
  }

  Future<void> openPermission() async {
    try {
      await updates.openInstallPermission();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pengaturan izin belum dapat dibuka.')));
      }
    }
  }

  ({String pill, String title, String message, IconData icon, Tone tone}) status() {
    if (updates.checking) {
      return (
        pill: 'Memeriksa',
        title: 'Memeriksa pembaruan...',
        message: 'Menghubungi server aplikasi.',
        icon: Icons.sync_rounded,
        tone: Tone.info,
      );
    }
    if (updates.available) {
      final release = updates.release!;
      return (
        pill: updates.downloaded ? 'Siap dipasang' : 'Tersedia',
        title: 'Versi ${release.version} tersedia',
        message: updates.isWeb || release.sizeBytes == null
            ? 'Build ${release.buildNumber}'
            : 'Build ${release.buildNumber} · Ukuran unduhan: ${(release.sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB',
        icon: Icons.system_update_rounded,
        tone: Tone.waiting,
      );
    }
    if (updates.release == null) {
      return (
        pill: 'Belum ada',
        title: 'Belum ada paket pembaruan yang dipublikasikan.',
        message: 'Periksa kembali nanti.',
        icon: Icons.inventory_2_outlined,
        tone: Tone.neutral,
      );
    }
    return (
      pill: 'Terbaru',
      title: 'Anda menggunakan versi terbaru.',
      message: 'Tidak ada tindakan yang diperlukan.',
      icon: Icons.verified_outlined,
      tone: Tone.ok,
    );
  }

  List<Widget> sections() {
    final release = updates.available ? updates.release : null;
    final muted = context.colors.onSurfaceVariant;
    return [
      if (updates.error != null) note(updates.error!, Tone.bad),
      if (permissionRequired)
        note(
          'Android memerlukan izin pemasangan untuk SIMS. Aktifkan izin tersebut, kembali ke aplikasi, lalu tekan Pasang pembaruan. Konfirmasi pemasangan tetap dilakukan oleh Android.',
          Tone.waiting,
          action: TextButton(onPressed: openPermission, child: const Text('Buka izin pemasangan')),
        ),
      if (release != null && !updates.checking) ...[
        const SectionTitle('Versi baru'),
        Text('Versi ${release.version} · build ${release.buildNumber}', style: context.text.bodyLarge),
        if (release.notes.isNotEmpty) ...[
          const SectionTitle('Catatan rilis'),
          Text(release.notes, style: context.text.bodyLarge),
        ],
      ],
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              updates.isWeb
                  ? 'Pembaruan dimuat dari server aplikasi.'
                  : 'Paket diperiksa sebelum dipasang: sumber HTTPS, ukuran, checksum, identitas aplikasi, versi, dan tanda tangan. Data akun tidak dihapus. Paket dengan tanda tangan berbeda akan ditolak.',
              style: context.text.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: updates,
    builder: (context, _) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.heroIsDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: !updates.downloading,
        child: Scaffold(
          backgroundColor: context.colors.surface,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: CustomScrollView(
                slivers: [
                  // One box so the status card can overlap the header.
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        header(),
                        Padding(
                          padding: EdgeInsets.only(top: headerHeight() - 44, bottom: 8),
                          child: Reveal(child: TiltOnTouch(maxAngle: .05, child: statusCard())),
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverList.list(children: sections()),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: actionBar(),
        ),
      ),
    ),
  );
}
