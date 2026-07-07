import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
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

class FamilySetupSnapshot {
  const FamilySetupSnapshot({
    required this.isComplete,
    required this.status,
    this.pendingJoinToken,
    this.pendingJoinUrl,
  });

  factory FamilySetupSnapshot.fromJson(Map<String, dynamic> json) {
    return FamilySetupSnapshot(
      isComplete: json['isComplete'] as bool? ?? false,
      pendingJoinToken: json['pendingJoinToken'] as String?,
      pendingJoinUrl: json['pendingJoinUrl'] as String?,
      status: json['status'] as String? ?? 'unset',
    );
  }

  final bool isComplete;
  final String? pendingJoinToken;
  final String? pendingJoinUrl;
  final String status;

  bool get isPendingJoin => status == 'pending_join';
}

class FamilySetupApi {
  FamilySetupApi(this._client);

  final ApiClient _client;

  Future<FamilySetupSnapshot> fetchStatus({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/family-setup',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilySetupApiException(_messageFromBody(data, l10n));
      }
      final setup = data['familySetup'];
      if (setup is! Map) {
        throw FamilySetupApiException(l10n.requestFailed);
      }
      return FamilySetupSnapshot.fromJson(Map<String, dynamic>.from(setup));
    } on DioException catch (error) {
      throw FamilySetupApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<FamilySetupSnapshot> answer({
    required String answer,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/family-setup',
        data: {'answer': answer, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilySetupApiException(_messageFromBody(data, l10n));
      }
      final setup = data['familySetup'];
      if (setup is! Map) {
        throw FamilySetupApiException(l10n.requestFailed);
      }
      return FamilySetupSnapshot.fromJson(Map<String, dynamic>.from(setup));
    } on DioException catch (error) {
      throw FamilySetupApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<FamilySetupSnapshot> cancelJoin({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/family-setup/cancel-join',
        data: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilySetupApiException(_messageFromBody(data, l10n));
      }
      final setup = data['familySetup'];
      if (setup is! Map) {
        throw FamilySetupApiException(l10n.requestFailed);
      }
      return FamilySetupSnapshot.fromJson(Map<String, dynamic>.from(setup));
    } on DioException catch (error) {
      throw FamilySetupApiException(
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

class FamilySetupApiException implements Exception {
  const FamilySetupApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
