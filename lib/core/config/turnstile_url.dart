import 'package:larnes_mobile/core/config/app_config.dart';

/// Эмулятор не видит localhost ПК — подменяем на 10.0.2.2.
String normalizeTurnstilePageUrl(String pageUrl) {
  if (pageUrl.isEmpty) {
    return pageUrl;
  }

  final apiBase = Uri.parse(AppConfig.apiBaseUrl);
  if (apiBase.host != '10.0.2.2') {
    return pageUrl;
  }

  final pageUri = Uri.tryParse(pageUrl);
  if (pageUri == null) {
    return pageUrl;
  }

  if (pageUri.host == 'localhost' || pageUri.host == '127.0.0.1') {
    return pageUri.replace(host: '10.0.2.2').toString();
  }

  return pageUrl;
}
