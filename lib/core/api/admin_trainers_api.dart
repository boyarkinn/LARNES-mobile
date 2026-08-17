import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/features/admin/models/trainer_catalog.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
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

class AdminTrainersApi {
  AdminTrainersApi(this._client);

  final ApiClient _client;

  Future<TrainerCatalogSnapshot> fetchCatalog({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get('/api/mobile/admin/trainers/catalog');
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw AdminTrainersApiException(
          _messageFromBody(data, l10n, fallback: l10n.adminTrainersLoadFailed),
        );
      }
      return TrainerCatalogSnapshot.fromJson(data);
    } on DioException catch (error) {
      throw AdminTrainersApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<TrainerPlayConfig> fetchPlayConfig({
    required String trainerKey,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/admin/trainers/$trainerKey/play-config',
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw AdminTrainersApiException(
          _messageFromBody(data, l10n, fallback: l10n.adminTrainerPlayLoadFailed),
        );
      }
      return TrainerPlayConfig.fromJson(data);
    } on DioException catch (error) {
      throw AdminTrainersApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<TrainerPlaySession> createPlaySession({
    required String trainerKey,
    required Map<String, dynamic> params,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/admin/trainers/$trainerKey/play-session',
        data: {
          'locale': locale,
          'params': params,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw AdminTrainersApiException(_messageFromBody(data, l10n));
      }
      return TrainerPlaySession.fromJson(data);
    } on DioException catch (error) {
      throw AdminTrainersApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
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

class AdminTrainersApiException implements Exception {
  const AdminTrainersApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
