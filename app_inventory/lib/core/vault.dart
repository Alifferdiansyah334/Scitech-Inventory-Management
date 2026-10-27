import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenVault {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenVault implements TokenVault {
  const SecureTokenVault();
  static const _storage = FlutterSecureStorage();
  static const _key = 'sims_mobile_session_v1';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}
