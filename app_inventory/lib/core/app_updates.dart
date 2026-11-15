import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' hide appBuildNumber;
import 'api.dart';
import 'release_info.dart';
import 'update_reload_stub.dart' if (dart.library.js_interop) 'update_reload_web.dart' as web_update;

class AppRelease {
  const AppRelease({
    required this.version,
    required this.buildNumber,
    required this.notes,
    this.url,
    this.sha256,
    this.sizeBytes,
  });
  final String version, notes;
  final int buildNumber;
  final Uri? url;
  final String? sha256;
  final int? sizeBytes;
  static AppRelease? parse(Map<String, dynamic> data, Uri origin, bool web) {
    if (data['available'] != true) return null;
    final number = data['build_number'];
    final version = data['version'];
    if (number is! int || number < 1 || version is! String || !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
      throw const FormatException('Informasi pembaruan tidak valid.');
    }
    final notes = data['notes'] as String? ?? '';
    if (notes.length > 2000) {
      throw const FormatException('Informasi pembaruan tidak valid.');
    }
    if (web) {
      return AppRelease(version: version, buildNumber: number, notes: notes);
    }
    final file = data['apk_path'];
    final hash = data['sha256'];
    final size = data['size_bytes'];
    if (origin.scheme != 'https' ||
        file is! String ||
        !RegExp(r'^/releases/[A-Za-z0-9][A-Za-z0-9._+\-]*\.apk$').hasMatch(file) ||
        hash is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
        size is! int ||
        size < 1 ||
        size > 150 * 1024 * 1024) {
      throw const FormatException('Paket pembaruan tidak dapat diverifikasi.');
    }
    final url = origin.resolve(file);
    if (url.origin != origin.origin) {
      throw const FormatException('Sumber pembaruan tidak diizinkan.');
    }
    return AppRelease(version: version, buildNumber: number, notes: notes, url: url, sha256: hash, sizeBytes: size);
  }
}

class AppUpdates extends ChangeNotifier {
  AppUpdates(this.api, {this.webOverride, this.currentBuildOverride});
  final ApiClient api;
  final bool? webOverride;
  final int? currentBuildOverride;
  static const channel = MethodChannel('sims/app_updates');
  AppRelease? release;
  String? error;
  int installedBuild = appBuildNumber, progress = 0;
  String installedVersion = appVersion;
  bool checking = false, downloading = false, downloaded = false;
  bool get isWeb => webOverride ?? kIsWeb;
  bool get supported => isWeb || defaultTargetPlatform == TargetPlatform.android;
  bool get available => release != null && release!.buildNumber > installedBuild;
  bool _disposed = false;
  void emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> check() async {
    if (checking || downloading) return;
    checking = true;
    error = null;
    emit();
    try {
      if (!supported) {
        throw const FormatException('Pembaruan ini tersedia untuk Android dan browser.');
      }
      if (currentBuildOverride != null) {
        installedBuild = currentBuildOverride!;
      } else if (!isWeb) {
        final info = await channel.invokeMapMethod<String, dynamic>('installedRelease');
        if (info == null) {
          throw const FormatException('Versi aplikasi belum dapat dibaca.');
        }
        installedBuild = (info['build_number'] as num).toInt();
        installedVersion = info['version'] as String;
      }
      final response =
          await api.request('api/mobile/releases?platform=${isWeb ? 'web' : 'android'}', authenticated: false)
              as Map<String, dynamic>;
      final latest = AppRelease.parse(response, Uri.parse(api.baseUrl), isWeb);
      if (release?.buildNumber != latest?.buildNumber) downloaded = false;
      release = latest;
    } catch (e) {
      error = e is PlatformException ? 'Pembaruan belum dapat diperiksa. Coba kembali nanti.' : e.toString();
    } finally {
      checking = false;
      emit();
    }
  }

  Future<void> download() async {
    final target = release;
    if (!available || target == null || isWeb || downloading) return;
    downloading = true;
    error = null;
    progress = 0;
    downloaded = false;
    emit();
    channel.setMethodCallHandler((call) async {
      if (call.method == 'downloadProgress') {
        progress = ((call.arguments as num).toInt()).clamp(0, 100);
        emit();
      }
    });
    try {
      await channel.invokeMethod('downloadUpdate', {
        'url': target.url.toString(),
        'origin': Uri.parse(api.baseUrl).origin,
        'sha256': target.sha256,
        'build_number': target.buildNumber,
        'size_bytes': target.sizeBytes,
      });
      downloaded = true;
    } on PlatformException catch (e) {
      error = e.message ?? 'Paket pembaruan belum dapat diunduh.';
    } finally {
      downloading = false;
      channel.setMethodCallHandler(null);
      emit();
    }
  }

  Future<String> install() async {
    error = null;
    try {
      if (isWeb) {
        await web_update.reloadUpdatedApp();
        return 'reloading';
      }
      if (!downloaded) {
        throw const FormatException('Unduh pembaruan terlebih dahulu.');
      }
      return await channel.invokeMethod<String>('installUpdate') ?? 'failed';
    } catch (e) {
      error = e is PlatformException ? e.message : e.toString();
      emit();
      return 'failed';
    }
  }

  Future<void> openInstallPermission() async {
    await channel.invokeMethod('openInstallPermission');
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
