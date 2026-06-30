import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  /// Prod: https://larnes.online
  /// Android emulator + local Next.js: http://10.0.2.2:3200
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (kDebugMode) {
      return 'http://10.0.2.2:3200';
    }
    return 'https://larnes.online';
  }
}
