import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:larnes_mobile/core/auth/secure_storage_utils.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'larnes_session_token';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => readSecureStorageValue(_storage, _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => deleteSecureStorageValue(_storage, _tokenKey);
}
