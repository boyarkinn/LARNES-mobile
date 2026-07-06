import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/child_session_api_client.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
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

KioskProgramApiException _apiExceptionFromBody(
  dynamic body,
  AppLocalizations l10n, {
  String? fallback,
  int? statusCode,
}) {
  return KioskProgramApiException(
    _messageFromBody(body, l10n, fallback: fallback),
    statusCode: statusCode,
  );
}

KioskProgramApiException _apiExceptionFromDio(DioException error, AppLocalizations l10n) {
  return _apiExceptionFromBody(
    error.response?.data,
    l10n,
    fallback: _networkMessage(error, l10n),
    statusCode: error.response?.statusCode,
  );
}

abstract class KioskProgramGateway {
  Future<ParentProgramPlaySnapshot> fetchPlaySnapshot(
    String programId, {
    String locale = 'ru',
  });

  Future<ParentProgramCompleteLessonResult> completeLesson({
    required String programId,
    required int topicOrdinal,
    required int lessonOrdinal,
    String locale = 'ru',
  });
}

class KioskProgramApi implements KioskProgramGateway {
  KioskProgramApi(this._client);

  final ChildSessionApiClient _client;

  @override
  Future<ParentProgramPlaySnapshot> fetchPlaySnapshot(
    String programId, {
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/classroom/programs/$programId/play-snapshot',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw _apiExceptionFromBody(
          data,
          l10n,
          fallback: l10n.parentProgramPlayLoadFailed,
        );
      }
      final snapshot = data['snapshot'];
      if (snapshot is! Map) {
        throw KioskProgramApiException(l10n.parentProgramPlayLoadFailed);
      }
      return ParentProgramPlaySnapshot.fromJson(
        Map<String, dynamic>.from(snapshot),
      );
    } on DioException catch (error) {
      throw _apiExceptionFromDio(error, l10n);
    }
  }

  @override
  Future<ParentProgramCompleteLessonResult> completeLesson({
    required String programId,
    required int topicOrdinal,
    required int lessonOrdinal,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/classroom/programs/$programId/complete-lesson',
        data: {
          'topicOrdinal': topicOrdinal,
          'lessonOrdinal': lessonOrdinal,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw _apiExceptionFromBody(
          data,
          l10n,
          fallback: l10n.parentProgramPlayCompleteFailed,
        );
      }
      return ParentProgramCompleteLessonResult(
        progressStatus: data['progressStatus'] as String? ?? 'in_progress',
      );
    } on DioException catch (error) {
      throw _apiExceptionFromDio(error, l10n);
    }
  }
}

class KioskProgramApiException implements Exception {
  const KioskProgramApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
