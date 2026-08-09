import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

Map<String, dynamic>? _asJsonMap(dynamic body) => parentPanelErrorMap(body);

String newLegalIdempotencyKey() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class VoluntaryConsentContext {
  const VoluntaryConsentContext({
    required this.activeEventId,
    required this.fields,
    required this.versionId,
    required this.versionLabel,
  });

  factory VoluntaryConsentContext.fromJson(Map<String, dynamic> json) {
    final version = json['version'] is Map
        ? Map<String, dynamic>.from(json['version'] as Map)
        : const <String, dynamic>{};
    return VoluntaryConsentContext(
      activeEventId: json['activeEventId'] as String?,
      fields: (json['fields'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      versionId: version['id'] as String?,
      versionLabel: version['label'] as String?,
    );
  }

  final String? activeEventId;
  final List<String> fields;
  final String? versionId;
  final String? versionLabel;

  bool get isActive => activeEventId != null;
}

class VoluntaryConsentSubmission {
  const VoluntaryConsentSubmission({
    required this.accepted,
    required this.idempotencyKey,
    required this.versionId,
  });

  final bool accepted;
  final String idempotencyKey;
  final String versionId;

  Map<String, dynamic> toJson() => {
    'voluntaryConsentAccepted': accepted,
    'voluntaryConsentIdempotencyKey': idempotencyKey,
    'voluntaryConsentVersionId': versionId,
  };
}

String _messageFromBody(
  dynamic body,
  AppLocalizations l10n, {
  String? fallback,
}) =>
    parentPanelErrorMessage(body, l10n, fallback: fallback);

ParentAccountApiException _parentAccountApiException(
  dynamic body,
  AppLocalizations l10n, {
  String? fallback,
}) =>
    ParentAccountApiException(
      _messageFromBody(body, l10n, fallback: fallback),
      code: parentPanelErrorCode(body),
    );

class ParentAccountSnapshot {
  const ParentAccountSnapshot({
    required this.user,
    required this.childrenCount,
    required this.voluntaryConsent,
  });

  factory ParentAccountSnapshot.fromJson(Map<String, dynamic> json) {
    return ParentAccountSnapshot(
      user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      childrenCount: json['childrenCount'] as int? ?? 0,
      voluntaryConsent: VoluntaryConsentContext.fromJson(
        Map<String, dynamic>.from(json['voluntaryConsent'] as Map),
      ),
    );
  }

  final AuthUser user;
  final int childrenCount;
  final VoluntaryConsentContext voluntaryConsent;
}

class ParentAccountApi {
  ParentAccountApi(this._client);

  final ApiClient _client;

  Future<ParentAccountSnapshot> fetchAccount({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/account',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentAccountApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentAccountLoadFailed),
        );
      }
      return ParentAccountSnapshot.fromJson(data);
    } on DioException catch (error) {
      throw _parentAccountApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<AuthUser> updateProfile({
    required String firstName,
    required String lastName,
    required String patronymic,
    VoluntaryConsentSubmission? consent,
    String locale = 'ru',
  }) {
    return _patchUser(
      '/api/mobile/parent/account/profile',
      {
        'firstName': firstName,
        'lastName': lastName,
        'patronymic': patronymic,
        'locale': locale,
        if (consent != null) ...consent.toJson(),
      },
      locale: locale,
    );
  }

  Future<AuthUser> updateDateOfBirth({
    required String dateOfBirth,
    VoluntaryConsentSubmission? consent,
    String locale = 'ru',
  }) {
    return _patchUser(
      '/api/mobile/parent/account/date-of-birth',
      {
        'dateOfBirth': dateOfBirth,
        'locale': locale,
        if (consent != null) ...consent.toJson(),
      },
      locale: locale,
    );
  }

  Future<AuthUser> updateCity({
    required String placeMapboxId,
    VoluntaryConsentSubmission? consent,
    String locale = 'ru',
  }) {
    return _patchUser(
      '/api/mobile/parent/account/city',
      {
        'placeMapboxId': placeMapboxId,
        'locale': locale,
        if (consent != null) ...consent.toJson(),
      },
      locale: locale,
    );
  }

  Future<void> revokeVoluntaryConsent({
    required String idempotencyKey,
    required String targetEventId,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/account/voluntary-consent/revoke',
        data: {
          'idempotencyKey': idempotencyKey,
          'locale': locale,
          'targetEventId': targetEventId,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentAccountApiException(_messageFromBody(data, l10n));
      }
    } on DioException catch (error) {
      throw _parentAccountApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<String> updateRelationship({
    required String relationship,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.patch(
        '/api/mobile/parent/account/relationship',
        data: {
          'relationship': relationship,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentAccountApiException(_messageFromBody(data, l10n));
      }
      return data['relationship'] as String? ?? relationship;
    } on DioException catch (error) {
      throw _parentAccountApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<AuthUser> updateLogin({
    required String currentPassword,
    required String newLogin,
    required String confirmNewLogin,
    String locale = 'ru',
  }) {
    return _patchUser(
      '/api/mobile/parent/account/login',
      {
        'currentPassword': currentPassword,
        'newLogin': newLogin,
        'confirmNewLogin': confirmNewLogin,
        'locale': locale,
      },
      locale: locale,
    );
  }

  Future<({AuthUser user, String? token})> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.patch(
        '/api/mobile/parent/account/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentAccountApiException(_messageFromBody(data, l10n));
      }
      final user = AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
      final token = data['token'] as String?;
      return (user: user, token: token);
    } on DioException catch (error) {
      throw _parentAccountApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<ContactChangeSendResult> sendContactChangeOtp({
    required ContactChangeChannel channel,
    required String currentPassword,
    required String newContact,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    final basePath = channel == ContactChangeChannel.phone ? 'phone' : 'email';
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/account/$basePath/send-otp',
        data: {
          'currentPassword': currentPassword,
          'newContact': newContact,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentAccountApiException(
          _messageFromBody(data, l10n, fallback: l10n.sendCodeFailed),
        );
      }
      return ContactChangeSendResult(
        contact: data['contact'] as String? ?? newContact,
        pendingToken: data['pendingToken'] as String? ?? '',
      );
    } on DioException catch (error) {
      throw _parentAccountApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<AuthUser> verifyContactChangeOtp({
    required ContactChangeChannel channel,
    required String pendingToken,
    required String code,
    String locale = 'ru',
  }) {
    final basePath = channel == ContactChangeChannel.phone ? 'phone' : 'email';
    return _postUser(
      '/api/mobile/parent/account/$basePath/verify-otp',
      {
        'pendingToken': pendingToken,
        'code': code,
        'locale': locale,
      },
      locale: locale,
      fallback: lookupAppLocalizations(Locale(locale)).verifyCodeFailed,
    );
  }

  Future<void> resendContactChangeOtp({
    required ContactChangeChannel channel,
    required String pendingToken,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    final basePath = channel == ContactChangeChannel.phone ? 'phone' : 'email';
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/account/$basePath/resend-otp',
        data: {
          'pendingToken': pendingToken,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentAccountApiException(
          _messageFromBody(data, l10n, fallback: l10n.resendFailed),
        );
      }
    } on DioException catch (error) {
      throw _parentAccountApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<void> logoutAllDevices({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post('/api/mobile/parent/account/logout-all');
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentAccountApiException(_messageFromBody(data, l10n));
      }
    } on DioException catch (error) {
      throw _parentAccountApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<AuthUser> _postUser(
    String path,
    Map<String, dynamic> payload, {
    required String locale,
    required String fallback,
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(path, data: payload);
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentAccountApiException(_messageFromBody(data, l10n, fallback: fallback));
      }
      return AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    } on DioException catch (error) {
      throw _parentAccountApiException(
        error.response?.data,
        l10n,
        fallback: _networkMessage(error, l10n),
      );
    }
  }

  Future<AuthUser> _patchUser(
    String path,
    Map<String, dynamic> payload, {
    required String locale,
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.patch(path, data: payload);
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentAccountApiException(_messageFromBody(data, l10n));
      }
      return AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    } on DioException catch (error) {
      throw _parentAccountApiException(
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

class ParentAccountApiException implements Exception {
  const ParentAccountApiException(this.message, {this.code});

  final String message;
  final String? code;

  bool get isFamilySetupRequired => isFamilySetupRequiredCode(code);

  @override
  String toString() => message;
}

enum ContactChangeChannel { phone, email }

class ContactChangeSendResult {
  const ContactChangeSendResult({
    required this.contact,
    required this.pendingToken,
  });

  final String contact;
  final String pendingToken;
}
