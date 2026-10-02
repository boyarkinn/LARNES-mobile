import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/child_session_api_client.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/features/parent/models/lesson_call_pass.dart';
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

String? _codeFromBody(dynamic body) {
  final code = _asJsonMap(body)?['code'];
  if (code is String && code.isNotEmpty) {
    return code;
  }
  return null;
}

class KioskLessonCallApi {
  KioskLessonCallApi(this._client);

  final ChildSessionApiClient _client;

  Future<LessonCallPass?> fetchPass({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/classroom/devices/me/lesson/call-pass',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      final pass = data == null ? null : LessonCallPass.fromJson(data);
      if (pass == null) {
        throw KioskApiException(l10n.requestFailed, code: _codeFromBody(data));
      }
      return pass;
    } on DioException catch (error) {
      throw KioskApiException(
        l10n.requestFailed,
        code: _codeFromBody(error.response?.data),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<LessonCallTeachers> claimRoster({
    required String endpointId,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/classroom/devices/me/lesson/call-roster',
        data: {'endpointId': endpointId},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw KioskApiException(l10n.requestFailed, code: _codeFromBody(data));
      }
      final teachers = data['teacherEndpointIds'];
      final primary = data['teacherEndpointId'];
      return LessonCallTeachers(
        ids: [
          if (teachers is List)
            for (final id in teachers)
              if (id is String && id.isNotEmpty) id,
        ],
        primary: primary is String ? primary : '',
      );
    } on DioException catch (error) {
      throw KioskApiException(
        l10n.requestFailed,
        code: _codeFromBody(error.response?.data),
        statusCode: error.response?.statusCode,
      );
    }
  }
}
