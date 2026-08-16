import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/core/api/kiosk_api_client.dart';
import 'package:larnes_mobile/core/auth/device_token_storage.dart';

/// Cached device-token presence for [GoRouter] redirects and splash bootstrap.
class KioskRouteState extends ChangeNotifier {
  KioskRouteState._({
    required this.deviceTokenStorage,
    required this.kioskApiClient,
  });

  factory KioskRouteState({
    DeviceTokenStorage? deviceTokenStorage,
    KioskApiClient? kioskApiClient,
  }) {
    final storage = deviceTokenStorage ?? DeviceTokenStorage();
    return KioskRouteState._(
      deviceTokenStorage: storage,
      kioskApiClient:
          kioskApiClient ?? KioskApiClient(deviceTokenStorage: storage),
    );
  }

  final DeviceTokenStorage deviceTokenStorage;
  final KioskApiClient kioskApiClient;

  bool _hasDeviceToken = false;

  bool get hasDeviceToken => _hasDeviceToken;

  Future<void> refreshDeviceToken() async {
    final next = await deviceTokenStorage.hasToken();
    if (_hasDeviceToken == next) {
      return;
    }
    _hasDeviceToken = next;
    notifyListeners();
  }

  Future<void> persistDeviceToken(String token) async {
    await deviceTokenStorage.writeToken(token);
    await refreshDeviceToken();
  }

  Future<void> clearDeviceToken() async {
    await deviceTokenStorage.clearToken();
    await refreshDeviceToken();
  }
}
