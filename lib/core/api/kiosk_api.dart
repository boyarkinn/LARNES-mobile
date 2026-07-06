import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/kiosk_api_client.dart';
import 'package:larnes_mobile/features/kiosk/api/kiosk_session_api.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_commands_response.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

Map<String, dynamic>? _asJsonMap(dynamic body) {
  if (body is Map<String, dynamic>) {
    return body;
  }
  if (body is Map) {
    return Map<String, dynamic>.from(body);
  }
  return null;
}

String _messageFromBody(dynamic body, AppLocalizations l10n, {String? fallback}) {
  final map = _asJsonMap(body);
  final message = map?['message'];
  if (message is String && message.isNotEmpty) {
    return message;
  }
  return fallback ?? l10n.requestError;
}

String? _codeFromBody(dynamic body) {
  final map = _asJsonMap(body);
  final code = map?['code'];
  if (code is String && code.isNotEmpty) {
    return code;
  }
  return null;
}

KioskApiException _apiExceptionFromBody(
  dynamic body,
  AppLocalizations l10n, {
  String? fallback,
  int? statusCode,
}) {
  return KioskApiException(
    _messageFromBody(body, l10n, fallback: fallback),
    code: _codeFromBody(body),
    statusCode: statusCode,
  );
}

String _kioskMessage(DioException error, AppLocalizations l10n) {
  if (error.response?.statusCode == 401) {
    return l10n.requestFailed;
  }
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout) {
    return l10n.noConnection;
  }
  return l10n.requestFailed;
}

KioskApiException _apiExceptionFromDio(DioException error, AppLocalizations l10n) {
  return _apiExceptionFromBody(
    error.response?.data,
    l10n,
    fallback: _kioskMessage(error, l10n),
    statusCode: error.response?.statusCode,
  );
}

class KioskApi implements KioskSessionApi {
  KioskApi(this._client);

  final KioskApiClient _client;

  @override
  Future<KioskDeviceContext> getDeviceMe({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get('/api/classroom/devices/me');
      final data = _asJsonMap(response.data);
      final deviceId = data?['deviceId'];
      if (data == null || deviceId is! String || deviceId.isEmpty) {
        throw _apiExceptionFromBody(data, l10n, fallback: l10n.requestFailed);
      }

      return KioskDeviceContext.fromJson(data);
    } on DioException catch (error) {
      throw _apiExceptionFromDio(error, l10n);
    }
  }

  Future<KioskCommandsResponse> pollCommands({
    required int since,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/classroom/devices/me/commands',
        queryParameters: {'since': since},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['commandSeq'] is! int) {
        throw _apiExceptionFromBody(data, l10n, fallback: l10n.requestFailed);
      }

      return KioskCommandsResponse.fromJson(data);
    } on DioException catch (error) {
      throw _apiExceptionFromDio(error, l10n);
    }
  }

  Future<void> heartbeat({
    int? ackSeq,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/classroom/devices/heartbeat',
        data: ackSeq == null ? null : {'ackSeq': ackSeq},
      );
      final data = _asJsonMap(response.data);
      if (data?['ok'] != true) {
        throw _apiExceptionFromBody(data, l10n, fallback: l10n.requestFailed);
      }
    } on DioException catch (error) {
      throw _apiExceptionFromDio(error, l10n);
    }
  }

  Future<void> childLogout({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post('/api/classroom/devices/child-logout');
      final data = _asJsonMap(response.data);
      if (data?['ok'] != true) {
        throw _apiExceptionFromBody(data, l10n, fallback: l10n.requestFailed);
      }
    } on DioException catch (error) {
      throw _apiExceptionFromDio(error, l10n);
    }
  }

  Future<KioskScanResult> scan({
    required String token,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/classroom/scan',
        data: {'token': token},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['ok'] != true) {
        throw _apiExceptionFromBody(data, l10n, fallback: l10n.requestFailed);
      }

      return KioskScanResult.fromJson(data);
    } on DioException catch (error) {
      throw _apiExceptionFromDio(error, l10n);
    }
  }

  Future<bool> hasDeviceToken() => _client.deviceTokenStorage.hasToken();

  Future<void> clearDeviceToken() => _client.deviceTokenStorage.clearToken();
}

class KioskApiException implements Exception {
  const KioskApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}
