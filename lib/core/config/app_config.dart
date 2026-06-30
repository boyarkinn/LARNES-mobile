class AppConfig {
  const AppConfig._();

  /// Prod: https://larnes.online
  /// Android emulator + local Next.js: http://10.0.2.2:3000
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://larnes.online',
  );
}
