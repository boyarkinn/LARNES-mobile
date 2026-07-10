import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Читает значение; при BAD_DECRYPT (переустановка / MIUI) — очищает и null.
Future<String?> readSecureStorageValue(
  FlutterSecureStorage storage,
  String key,
) async {
  try {
    return await storage.read(key: key);
  } on PlatformException {
    await deleteSecureStorageValue(storage, key);
    return null;
  } catch (_) {
    await deleteSecureStorageValue(storage, key);
    return null;
  }
}

Future<void> deleteSecureStorageValue(
  FlutterSecureStorage storage,
  String key,
) async {
  try {
    await storage.delete(key: key);
  } catch (_) {}
}
