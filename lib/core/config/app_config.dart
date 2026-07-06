class AppConfig {
  const AppConfig._();

  static const prodApiBaseUrl = 'https://larnes.online';

  /// Override at run time: `--dart-define=API_BASE_URL=...`
  ///
  /// Default: [prodApiBaseUrl] (VPS — работает с физического телефона).
  /// Локальный platform: `http://<LAN-IP>:3200` или эмулятор `http://10.0.2.2:3200`.
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return prodApiBaseUrl;
  }
}
