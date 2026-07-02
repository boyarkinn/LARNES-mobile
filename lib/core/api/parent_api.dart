import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
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

class ParentApi {
  ParentApi(this._client);

  final ApiClient _client;

  Future<List<ParentChild>> listChildren({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get('/api/mobile/parent/children');
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(_messageFromBody(data, l10n, fallback: l10n.parentLoadChildrenFailed));
      }
      final children = data['children'] as List<dynamic>? ?? const [];
      return children
          .map(
            (item) => ParentChild.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ParentApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<ParentChildDetail> fetchChild(String childId, {String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get('/api/mobile/parent/children/$childId');
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(_messageFromBody(data, l10n));
      }
      return ParentChildDetail.fromJson(data);
    } on DioException catch (error) {
      throw ParentApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<ParentChild> createChild({
    required CreateChildPayload payload,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/children',
        data: payload.toJson(locale),
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(_messageFromBody(data, l10n, fallback: l10n.parentCreateChildFailed));
      }
      final child = data['child'] as Map<String, dynamic>?;
      if (child == null) {
        throw ParentApiException(l10n.parentCreateChildFailed);
      }
      return ParentChild.fromJson(child);
    } on DioException catch (error) {
      throw ParentApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<ParentChild> updateChild({
    required String childId,
    required CreateChildPayload payload,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.patch(
        '/api/mobile/parent/children/$childId',
        data: payload.toJson(locale),
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(_messageFromBody(data, l10n, fallback: l10n.parentUpdateChildFailed));
      }
      final child = data['child'];
      if (child is! Map) {
        throw ParentApiException(l10n.parentUpdateChildFailed);
      }
      return ParentChild.fromJson(Map<String, dynamic>.from(child));
    } on DioException catch (error) {
      throw ParentApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<ParentHomeworkListPage> listHomework(
    String childId, {
    ParentHomeworkTab tab = ParentHomeworkTab.due,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/homework',
        queryParameters: {
          'tab': tab.apiValue,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentHomeworkLoadFailed),
        );
      }
      return ParentHomeworkListPage.fromJson(data);
    } on DioException catch (error) {
      throw ParentApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<ParentHomeworkPlaySnapshot> fetchHomeworkSnapshot(
    String childId,
    String assignmentId, {
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/homework/$assignmentId',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentHomeworkPlayLoadFailed),
        );
      }
      final snapshot = data['snapshot'];
      if (snapshot is! Map) {
        throw ParentApiException(l10n.parentHomeworkPlayLoadFailed);
      }
      return ParentHomeworkPlaySnapshot.fromJson(
        Map<String, dynamic>.from(snapshot),
      );
    } on DioException catch (error) {
      throw ParentApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<List<ParentProgramCard>> listPrograms(
    String childId, {
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/programs',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentProgramLoadFailed),
        );
      }
      final programs = data['programs'] as List<dynamic>? ?? const [];
      return programs
          .map(
            (item) => ParentProgramCard.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ParentApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<ParentProgramPlaySnapshot> fetchProgramSnapshot(
    String childId,
    String programId, {
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/programs/$programId',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentProgramPlayLoadFailed),
        );
      }
      final snapshot = data['snapshot'];
      if (snapshot is! Map) {
        throw ParentApiException(l10n.parentProgramPlayLoadFailed);
      }
      return ParentProgramPlaySnapshot.fromJson(
        Map<String, dynamic>.from(snapshot),
      );
    } on DioException catch (error) {
      throw ParentApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<ParentProgramCompleteLessonResult> completeProgramLesson({
    required String childId,
    required String programId,
    required int topicOrdinal,
    required int lessonOrdinal,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/children/$childId/programs/$programId/complete-lesson',
        data: {
          'topicOrdinal': topicOrdinal,
          'lessonOrdinal': lessonOrdinal,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentProgramPlayCompleteFailed),
        );
      }
      return ParentProgramCompleteLessonResult(
        progressStatus: data['progressStatus'] as String? ?? 'in_progress',
      );
    } on DioException catch (error) {
      throw ParentApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<void> advanceHomeworkStep({
    required String childId,
    required String assignmentId,
    required int nextStepIndex,
    required int totalSteps,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/children/$childId/homework/$assignmentId/advance',
        data: {
          'nextStepIndex': nextStepIndex,
          'totalSteps': totalSteps,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentHomeworkPlayAdvanceFailed),
        );
      }
    } on DioException catch (error) {
      throw ParentApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<void> deleteChild(String childId, {String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.delete(
        '/api/mobile/parent/children/$childId',
        data: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(_messageFromBody(data, l10n, fallback: l10n.parentDeleteChildFailed));
      }
    } on DioException catch (error) {
      throw ParentApiException(
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

class ParentApiException implements Exception {
  const ParentApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
