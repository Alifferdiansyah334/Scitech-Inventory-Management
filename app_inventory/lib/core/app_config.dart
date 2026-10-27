import 'package:flutter/foundation.dart';
import 'api.dart';
import 'app_state.dart';
import 'vault.dart';

class AppConfig {
  AppConfig._();
  static final AppConfig instance = AppConfig._();

  /// URL default backend Next.js API (bisa di-override lewat --dart-define=API_URL=...)
  String baseUrl = resolveApiUrl();

  late final ApiClient api = ApiClient(baseUrl: baseUrl);
  late final TokenVault vault = const SecureTokenVault();
  late final AppState appState = AppState(api: api, vault: vault);

  /// Status apakah backend sedang aktif dan terhubung
  bool isConnected = false;

  Future<void> initialize() async {
    try {
      await appState.restore();
      isConnected = appState.profile != null;
    } catch (e) {
      debugPrint('Pemulihan sesi belum berhasil.');
    }
  }
}

String resolveApiUrl() {
  const configured = String.fromEnvironment('API_URL');
  if (configured.isNotEmpty) return configured;
  if (kIsWeb) {
    final uri = Uri.base;
    if (!const ['localhost', '127.0.0.1'].contains(uri.host) ||
        const [3000, 3001].contains(uri.port)) {
      return uri.origin;
    }
  }
  return kReleaseMode ? '' : 'http://localhost:3000';
}
