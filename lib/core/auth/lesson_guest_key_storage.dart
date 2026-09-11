import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:larnes_mobile/core/auth/secure_storage_utils.dart';

class LessonGuestKeyStorage {
  LessonGuestKeyStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'larnes_lesson_guest_key';

  final FlutterSecureStorage _storage;

  Future<String?> readKey() => readSecureStorageValue(_storage, _key);

  Future<void> writeKey(String guestKey) =>
      _storage.write(key: _key, value: guestKey);

  Future<void> clearKey() => deleteSecureStorageValue(_storage, _key);
}
