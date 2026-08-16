import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/kiosk_api_client.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
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

String _networkMessage(DioException error, AppLocalizations l10n) {
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout) {
    return l10n.noConnection;
  }
  return l10n.requestFailed;
}

class KioskTrainerApi {
  KioskTrainerApi(this._client);

  final KioskApiClient _client;

  Future<ParentHomeworkPlaySnapshot> fetchPlaySnapshot({
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/classroom/trainer/play-snapshot',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw KioskTrainerApiException(
          _messageFromBody(data, l10n, fallback: l10n.requestFailed),
        );
      }
      final snapshot = data['snapshot'];
      if (snapshot is! Map) {
        throw KioskTrainerApiException(l10n.requestFailed);
      }
      return ParentHomeworkPlaySnapshot.fromJson(
        Map<String, dynamic>.from(snapshot),
      );
    } on DioException catch (error) {
      throw KioskTrainerApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
        statusCode: error.response?.statusCode,
      );
    }
  }
}

class KioskTrainerApiException implements Exception {
  const KioskTrainerApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
