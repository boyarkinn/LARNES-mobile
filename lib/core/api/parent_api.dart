import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/features/parent/models/child_classroom_qr.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

Map<String, dynamic>? _asJsonMap(dynamic body) => parentPanelErrorMap(body);

String _messageFromBody(
  dynamic body,
  AppLocalizations l10n, {
  String? fallback,
}) =>
    parentPanelErrorMessage(body, l10n, fallback: fallback);

ParentApiException _parentApiException(
  dynamic body,
  AppLocalizations l10n, {
  String? fallback,
}) =>
    ParentApiException(
      _messageFromBody(body, l10n, fallback: fallback),
      code: parentPanelErrorCode(body),
    );

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
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
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
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
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
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
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
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
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
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
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
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<bool> hasPublishedLarnesCourses({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/larnes-courses/available',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.requestFailed),
        );
      }
      return data['hasPublishedCourses'] == true;
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<ParentActivityContextPage> fetchActivityContext(
    String childId, {
    String? place,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/activity/context',
        queryParameters: {
          'locale': locale,
          if (place != null && place.isNotEmpty) 'place': place,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentActivityLoadFailed),
        );
      }
      return ParentActivityContextPage.fromJson(data);
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<ParentActivityClassesPage> listAttendanceClasses(
    String childId, {
    String? place,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/activity/attendance/classes',
        queryParameters: {
          'locale': locale,
          if (place != null && place.isNotEmpty) 'place': place,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentActivityLoadFailed),
        );
      }
      return ParentActivityClassesPage.fromJson(data);
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<ParentActivityScheduleDayPage> fetchScheduleDay(
    String childId, {
    String? date,
    String? place,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/activity/schedule/day',
        queryParameters: {
          'locale': locale,
          if (date != null && date.isNotEmpty) 'date': date,
          if (place != null && place.isNotEmpty) 'place': place,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentActivityScheduleNotFound),
        );
      }
      return ParentActivityScheduleDayPage.fromJson(data);
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<ParentActivityPaymentsPage> fetchPayments(
    String childId, {
    String? place,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/activity/payments',
        queryParameters: {
          'locale': locale,
          if (place != null && place.isNotEmpty) 'place': place,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentActivityLoadFailed),
        );
      }
      return ParentActivityPaymentsPage.fromJson(data);
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<ParentActivityReceiptDetailPage> fetchPaymentReceipt(
    String childId,
    String batchId, {
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/activity/payments/receipts/$batchId',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentActivityPaymentDetailNotFound),
        );
      }
      return ParentActivityReceiptDetailPage.fromJson(data);
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<ParentActivityAccrualDetailPage> fetchPaymentAccrual(
    String childId,
    String batchId, {
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/activity/payments/accruals/$batchId',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentActivityPaymentDetailNotFound),
        );
      }
      return ParentActivityAccrualDetailPage.fromJson(data);
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<ParentAttendanceCalendarPage> fetchAttendanceCalendar(
    String childId,
    String groupId, {
    String? month,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/activity/attendance/$groupId/calendar',
        queryParameters: {
          'locale': locale,
          if (month != null && month.isNotEmpty) 'month': month,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentActivityCalendarNotFound),
        );
      }
      return ParentAttendanceCalendarPage.fromJson(data);
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<List<ParentDirectionCard>> listDirections(
    String childId, {
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/directions',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentDirectionLoadFailed),
        );
      }
      final directions = data['directions'] as List<dynamic>? ?? const [];
      return directions
          .map(
            (item) => ParentDirectionCard.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<DirectionTrack> fetchDirectionTrack(
    String childId,
    String directionId, {
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/directions/$directionId/programs',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentProgramLoadFailed),
        );
      }
      final track = data['track'];
      if (track is! Map) {
        throw ParentApiException(l10n.parentProgramLoadFailed);
      }
      return DirectionTrack.fromJson(Map<String, dynamic>.from(track));
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
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
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
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
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
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
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<ChildClassroomQrState> fetchChildClassroomQr(
    String childId, {
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/children/$childId/classroom-qr',
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(_messageFromBody(data, l10n));
      }
      final qr = data['classroomQr'];
      if (qr is! Map) {
        throw ParentApiException(l10n.requestError);
      }
      return ChildClassroomQrState.fromJson(Map<String, dynamic>.from(qr));
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<ChildClassroomQrState> mutateChildClassroomQr({
    required String childId,
    required ChildClassroomQrAction action,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/children/$childId/classroom-qr',
        data: {
          'action': action.name,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentApiException(_messageFromBody(data, l10n));
      }
      final qr = data['classroomQr'];
      if (qr is! Map) {
        throw ParentApiException(l10n.requestError);
      }
      return ChildClassroomQrState.fromJson(Map<String, dynamic>.from(qr));
    } on DioException catch (error) {
      throw _parentApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
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
      throw _parentApiException(
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

class ParentApiException implements Exception {
  const ParentApiException(this.message, {this.code});

  final String message;
  final String? code;

  bool get isFamilySetupRequired => isFamilySetupRequiredCode(code);

  @override
  String toString() => message;
}
