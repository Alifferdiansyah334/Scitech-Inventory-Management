import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/app_updates.dart';

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
          ),
          actions: [
            TextButton(
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: updates,
    builder: (context, _) => PopScope(
      canPop: !updates.downloading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembaruan aplikasi'),
          automaticallyImplyLeading: !updates.downloading,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.system_update_rounded, size: 64),
                    const SizedBox(height: 20),
                    Text(
                      'SIMS ${updates.installedVersion}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Versi terpasang · build ${updates.installedBuild}',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 24),
                    if (updates.checking) const LinearProgressIndicator(),
                    if (updates.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          updates.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (!updates.checking) ...[
                      Text(
                        updates.available
                            ? 'Versi ${updates.release!.version} tersedia'
                            : updates.release == null
                            ? 'Belum ada paket pembaruan yang dipublikasikan.'
                            : 'Anda menggunakan versi terbaru.',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (updates.available) ...[
                        const SizedBox(height: 12),
                        Text(updates.release!.notes),
                        if (!updates.isWeb)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Ukuran unduhan: ${(updates.release!.sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB',
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (updates.downloading) ...[
                          LinearProgressIndicator(
                            value: updates.progress / 100,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mengunduh dan memverifikasi paket... ${updates.progress}%',
                          ),
                        ] else if (updates.isWeb || updates.downloaded)
                          FilledButton.icon(
                            onPressed: install,
                            icon: const Icon(Icons.system_update),
                            label: Text(
                              updates.isWeb
                                  ? 'Gunakan versi terbaru'
                                  : 'Pasang pembaruan',
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
                          const Text(
                            'Android memerlukan izin pemasangan untuk SIMS. Aktifkan izin tersebut, kembali ke aplikasi, lalu tekan Pasang pembaruan. Konfirmasi pemasangan tetap dilakukan oleh Android.',
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await updates.openInstallPermission();
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pengaturan izin belum dapat dibuka.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Buka izin pemasangan'),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: updates.downloading ? null : updates.check,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Periksa pembaruan'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      updates.isWeb
                          ? 'Pembaruan dimuat dari server aplikasi.'
                          : 'Paket diperiksa sebelum dipasang: sumber HTTPS, ukuran, checksum, identitas aplikasi, versi, dan tanda tangan. Data akun tidak dihapus. Paket dengan tanda tangan berbeda akan ditolak.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
