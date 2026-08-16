import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/features/network/models/network_center.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';
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

NetworkApiException _apiExceptionFromBody(
  dynamic body,
  AppLocalizations l10n, {
  String? fallback,
}) {
  return NetworkApiException(
    _messageFromBody(body, l10n, fallback: fallback),
    code: _codeFromBody(body),
  );
}

class NetworkApi {
  NetworkApi(this._client);

  final ApiClient _client;

  Future<List<NetworkCenter>> listCenters({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get('/api/mobile/network/centers');
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw _apiExceptionFromBody(data, l10n, fallback: l10n.requestFailed);
      }

      final centers = data['centers'] as List<dynamic>? ?? const [];
      return centers
          .map(
            (item) => NetworkCenter.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _apiExceptionFromBody(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<List<NetworkDevice>> listDevices({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get('/api/mobile/network/devices');
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw _apiExceptionFromBody(data, l10n, fallback: l10n.requestFailed);
      }

      final devices = data['devices'] as List<dynamic>? ?? const [];
      return devices
          .map(
            (item) => NetworkDevice.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _apiExceptionFromBody(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<void> unbindDevice({
    required String deviceId,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/network/devices/unbind',
        data: {
          'deviceId': deviceId,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw _apiExceptionFromBody(data, l10n, fallback: l10n.requestFailed);
      }
    } on DioException catch (error) {
      throw _apiExceptionFromBody(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  static String _networkMessage(DioException error, AppLocalizations l10n) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return l10n.noConnection;
    }
    return l10n.requestFailed;
  }
}

class NetworkApiException implements Exception {
  const NetworkApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
