import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

/// Не бросать DioException на 4xx — body с [message] парсим сами (как web).
bool apiStatusAcceptable(int? status) => status != null && status < 500;

Options apiOptions({Options? base}) {
  return (base ?? Options()).copyWith(
    validateStatus: apiStatusAcceptable,
  );
}

/// Парсит тело mobile API: Map, JSON-строка или bytes.
Map<String, dynamic>? parseApiJsonBody(dynamic body) {
  if (body is Map<String, dynamic>) {
    return body;
  }
  if (body is Map) {
    return Map<String, dynamic>.from(body);
  }
  if (body is String) {
    return _decodeJsonMap(body);
  }
  if (body is List<int>) {
    return _decodeJsonMap(utf8.decode(body));
  }
  if (body is Uint8List) {
    return _decodeJsonMap(utf8.decode(body));
  }
  return null;
}

Map<String, dynamic>? _decodeJsonMap(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  } catch (_) {
    return null;
  }
  return null;
}

/// Текст [message] из ответа platform (как FormAlert на web).
String apiMessageFromBody(
  dynamic body,
  AppLocalizations l10n, {
  String? fallback,
}) {
  final map = parseApiJsonBody(body);
  final message = map?['message'];
  if (message is String && message.isNotEmpty) {
    return message;
  }
  return fallback ?? l10n.requestError;
}

String apiNetworkMessage(DioException error, AppLocalizations l10n) {
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
      return l10n.noConnection;
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return l10n.requestFailed;
    case DioExceptionType.badResponse:
      final fromBody = apiMessageFromBody(
        error.response?.data,
        l10n,
        fallback: '',
      );
      if (fromBody.isNotEmpty) {
        return fromBody;
      }
      return l10n.requestFailed;
    default:
      return l10n.requestFailed;
  }
}
