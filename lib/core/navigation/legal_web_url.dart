import 'package:larnes_mobile/core/config/app_config.dart';

String buildLegalHubUrl({required String locale}) {
  final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
  final language = locale == 'en' ? 'en' : 'ru';

  return '$base/$language/legal';
}

String buildAppWebUrl(String path) {
  final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
  final normalizedPath = path.startsWith('/') ? path : '/$path';

  return '$base$normalizedPath';
}
