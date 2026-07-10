import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/auth/secure_storage_utils.dart';

class _ThrowingSecureStorage extends FlutterSecureStorage {
  _ThrowingSecureStorage({required this.onDelete});

  final List<String> onDelete;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw PlatformException(
      code: 'Exception encountered',
      message: 'read',
      details: 'javax.crypto.BadPaddingException',
    );
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    onDelete.add(key);
  }
}

void main() {
  test('readSecureStorageValue clears corrupt entry and returns null', () async {
    final deleted = <String>[];
    final storage = _ThrowingSecureStorage(onDelete: deleted);

    final value = await readSecureStorageValue(storage, 'larnes_session_token');

    expect(value, isNull);
    expect(deleted, ['larnes_session_token']);
  });
}
