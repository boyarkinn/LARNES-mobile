import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/lesson_guest_key_storage.dart';
import 'package:larnes_mobile/features/parent/models/parent_live_lesson_room.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

const lessonGuestKeyHeader = 'X-Larnes-Lesson-Guest-Key';

class LessonInviteGuestApi {
  LessonInviteGuestApi(
    this._client, {
    LessonGuestKeyStorage? storage,
  }) : _storage = storage ?? LessonGuestKeyStorage();

  final ApiClient _client;
  final LessonGuestKeyStorage _storage;

  Future<String?> readStoredKey() => _storage.readKey();

  Future<void> join({
    required String token,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/invite/lesson/guest',
        data: {
          'locale': locale,
          'token': token,
        },
        options: await _guestOptions(),
      );
      final data = _asJsonMap(response.data);
      final guestKey = data?['guestKey'] as String?;
      if (data == null || data['status'] != 'success' || guestKey == null || guestKey.isEmpty) {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentLiveLessonJoinFailed),
        );
      }

      await _storage.writeKey(guestKey);
    } on DioException catch (error) {
      throw _parentApiException(error, l10n, fallback: l10n.parentLiveLessonJoinFailed);
    }
  }

  Future<ParentLiveLessonRoomState?> fetchRoom({
    required String token,
    String locale = 'ru',
    bool poll = false,
  }) async {
    final key = await _storage.readKey();
    if (key == null || key.isEmpty) {
      return null;
    }

    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/invite/lesson/guest',
        queryParameters: {
          'token': token,
          if (poll) 'poll': '1',
          if (!poll) 'locale': locale,
        },
        options: await _guestOptions(key),
      );
      if (response.statusCode == 404) {
        return const ParentLiveLessonRoomState(status: 'invalid');
      }

      final data = _asJsonMap(response.data);
      if (data == null) {
        throw ParentApiException(l10n.parentLiveLessonLoadFailed);
      }

      return ParentLiveLessonRoomState.fromJson(data);
    } on DioException catch (error) {
      throw _parentApiException(error, l10n, fallback: l10n.parentLiveLessonLoadFailed);
    }
  }

  Future<void> leave({
    required String token,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/invite/lesson/guest/leave',
        data: {'token': token},
        options: await _guestOptions(),
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'ok') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentLiveLessonLeaveFailed),
        );
      }
    } on DioException catch (error) {
      throw _parentApiException(error, l10n, fallback: l10n.parentLiveLessonLeaveFailed);
    }
  }

  Future<Options> _guestOptions([String? knownKey]) async {
    final key = knownKey ?? await _storage.readKey();
    return Options(
      headers: {
        if (key != null && key.isNotEmpty) lessonGuestKeyHeader: key,
      },
    );
  }
}

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
  final message = _asJsonMap(body)?['message'];
  if (message is String && message.isNotEmpty) {
    return message;
  }
  return fallback ?? l10n.requestError;
}

ParentApiException _parentApiException(
  DioException error,
  AppLocalizations l10n, {
  required String fallback,
}) {
  final message = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout
      ? l10n.noConnection
      : _messageFromBody(error.response?.data, l10n, fallback: fallback);
  return ParentApiException(message);
}
