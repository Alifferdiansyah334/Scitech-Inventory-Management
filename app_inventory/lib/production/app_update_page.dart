import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/app_updates.dart';
import '../ui/components.dart';
import '../ui/springs.dart';
import '../ui/tokens.dart';

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
          title: const Text('Muat versi terbaru?'),
          content: const Text(
            'Pastikan perubahan Anda sudah tersimpan. Aplikasi akan dimuat ulang; data di server tetap tersimpan.',
            style: TextStyle(fontSize: 15, color: AppColors.muted),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Muat ulang'),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan izin belum dapat dibuka.')),
        );
      }
    }
  }

  ({String title, String message, IconData icon, Tone tone}) status() {
    if (updates.checking) {
      return (
        title: 'Memeriksa pembaruan...',
        message: 'Menghubungi server aplikasi.',
        icon: Icons.sync_rounded,
        tone: Tone.info,
      );
    }
    if (updates.available) {
      final release = updates.release!;
      return (
        title: 'Versi ${release.version} tersedia',
        message: updates.isWeb || release.sizeBytes == null
            ? 'Build ${release.buildNumber}'
            : 'Build ${release.buildNumber} · Ukuran unduhan: ${(release.sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB',
        icon: Icons.system_update_rounded,
        tone: Tone.info,
      );
    }
    if (updates.release == null) {
      return (
        title: 'Belum ada paket pembaruan yang dipublikasikan.',
        message: 'Periksa kembali nanti.',
        icon: Icons.inventory_2_outlined,
        tone: Tone.neutral,
      );
    }
    return (
      title: 'Anda menggunakan versi terbaru.',
      message: 'Tidak ada tindakan yang diperlukan.',
      icon: Icons.verified_outlined,
      tone: Tone.ok,
    );
  }

  Widget header(BuildContext context) => BrandHeader(
    padding: EdgeInsets.fromLTRB(
      16,
      MediaQuery.paddingOf(context).top + 12,
      20,
      32,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HeaderIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Kembali',
                  onPressed: updates.downloading
                      ? null
                      : () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pembaruan aplikasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'SIMS ${updates.installedVersion}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Versi terpasang · build ${updates.installedBuild}',
              style: const TextStyle(color: AppColors.navyMuted, fontSize: 15),
            ),
          ],
        ),
      ),
    ),
  );

  Widget statusCard() {
    final s = status();
    final colors = toneColors(s.tone);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(s.icon, background: colors.bg, foreground: colors.fg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (updates.checking) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (!updates.checking && updates.available) ...[
            if (updates.release!.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: Text(updates.release!.notes),
              ),
            ],
            const SizedBox(height: 16),
            ...actions(),
          ],
        ],
      ),
    );
  }

  List<Widget> actions() => [
    if (updates.downloading) ...[
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: updates.progress / 100,
          minHeight: 8,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Mengunduh dan memverifikasi paket... ${updates.progress}%',
        style: const TextStyle(fontSize: 13, color: AppColors.muted),
      ),
    ] else if (updates.isWeb || updates.downloaded)
      FilledButton.icon(
        onPressed: install,
        icon: const Icon(Icons.system_update),
        label: Text(
          updates.isWeb ? 'Gunakan versi terbaru' : 'Pasang pembaruan',
        ),
      )
    else
      FilledButton.icon(
        onPressed: updates.download,
        icon: const Icon(Icons.download_outlined),
        label: const Text('Unduh pembaruan'),
      ),
    if (permissionRequired) ...[
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: const Text(
          'Android memerlukan izin pemasangan untuk SIMS. Aktifkan izin tersebut, kembali ke aplikasi, lalu tekan Pasang pembaruan. Konfirmasi pemasangan tetap dilakukan oleh Android.',
          style: TextStyle(color: AppColors.accentText),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: openPermission,
        child: const Text('Buka izin pemasangan'),
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: updates,
    builder: (context, _) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: !updates.downloading,
        child: Scaffold(
          backgroundColor: AppColors.paper,
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header(context),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (updates.error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.badSoft,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.control,
                                ),
                              ),
                              child: Text(
                                updates.error!,
                                style: const TextStyle(
                                  color: AppColors.bad,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SpringReveal(child: statusCard()),
                          if (!updates.checking) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: updates.downloading
                                  ? null
                                  : updates.check,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Periksa pembaruan'),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            updates.isWeb
                                ? 'Pembaruan dimuat dari server aplikasi.'
                                : 'Paket diperiksa sebelum dipasang: sumber HTTPS, ukuran, checksum, identitas aplikasi, versi, dan tanda tangan. Data akun tidak dihapus. Paket dengan tanda tangan berbeda akan ditolak.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
