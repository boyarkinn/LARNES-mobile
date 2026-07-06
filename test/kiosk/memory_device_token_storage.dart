import 'package:larnes_mobile/core/auth/device_token_storage.dart';

/// In-memory [DeviceTokenStorage] for unit/widget tests (no platform plugin).
class MemoryDeviceTokenStorage extends DeviceTokenStorage {
  MemoryDeviceTokenStorage();

  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}
