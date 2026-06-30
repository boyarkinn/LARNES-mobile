import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
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

class ParentAccountSnapshot {
  const ParentAccountSnapshot({
    required this.user,
    required this.childrenCount,
  });

  factory ParentAccountSnapshot.fromJson(Map<String, dynamic> json) {
    return ParentAccountSnapshot(
      user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      childrenCount: json['childrenCount'] as int? ?? 0,
    );
  }

  final AuthUser user;
  final int childrenCount;
}

class ParentAccountApi {
  ParentAccountApi(this._client);

  final ApiClient _client;

  Future<ParentAccountSnapshot> fetchAccount({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get('/api/mobile/parent/account');
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ParentAccountApiException(
          _messageFromBody(data, l10n, fallback: l10n.parentAccountLoadFailed),
        );
      }
      return ParentAccountSnapshot.fromJson(data);
    } on DioException catch (error) {
      throw ParentAccountApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<AuthUser> updateProfile({
    required String firstName,
    required String lastName,
    required String patronymic,
    String locale = 'ru',
  }) {
    return _patchUser(
      '/api/mobile/parent/account/profile',
      {
        'firstName': firstName,
        'lastName': lastName,
        'patronymic': patronymic,
        'locale': locale,
      },
      locale: locale,
    );
  }

  Future<AuthUser> updateDateOfBirth({
    required String dateOfBirth,
    String locale = 'ru',
  }) {
    return _patchUser(
      '/api/mobile/parent/account/date-of-birth',
      {'dateOfBirth': dateOfBirth, 'locale': locale},
      locale: locale,
    );
  }

  Future<AuthUser> updateCity({
    required String city,
    String locale = 'ru',
  }) {
    return _patchUser(
      '/api/mobile/parent/account/city',
      {'city': city, 'locale': locale},
      locale: locale,
    );
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
      throw ParentAccountApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
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
      throw ParentAccountApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
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
      throw ParentAccountApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
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
      throw ParentAccountApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
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
      throw ParentAccountApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
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
      throw ParentAccountApiException(
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

class ParentAccountApiException implements Exception {
  const ParentAccountApiException(this.message);
  final String message;

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
