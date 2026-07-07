import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/features/auth/models/password_reset_flow.dart';
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

String _messageFromBody(
  dynamic body,
  AppLocalizations l10n, {
  String? fallback,
}) {
  final map = _asJsonMap(body);
  final message = map?['message'];
  if (message is String && message.isNotEmpty) {
    return message;
  }
  return fallback ?? l10n.requestError;
}

class PasswordResetApi {
  PasswordResetApi(this._client);

  final ApiClient _client;

  Future<PasswordResetFlowData> sendOtp({
    required String contact,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/password-reset/send-otp',
        data: {'contact': contact, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw PasswordResetApiException(_messageFromBody(data, l10n));
      }
      final normalized = data['contact'] as String?;
      final channelValue = data['channel'] as String?;
      if (normalized == null ||
          normalized.isEmpty ||
          channelValue == null ||
          channelValue.isEmpty) {
        throw PasswordResetApiException(l10n.sendCodeFailed);
      }
      return PasswordResetFlowData(
        contact: normalized,
        channel: PasswordResetFlowData.channelFromApi(channelValue),
      );
    } on DioException catch (error) {
      throw PasswordResetApiException(
        _messageFromBody(error.response?.data, l10n, fallback: _networkMessage(error, l10n)),
      );
    }
  }

  Future<String> verifyOtp({
    required String contact,
    required String code,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/password-reset/verify-otp',
        data: {
          'contact': contact,
          'code': code,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw PasswordResetApiException(_messageFromBody(data, l10n));
      }
      final token = data['verificationToken'] as String?;
      if (token == null || token.isEmpty) {
        throw PasswordResetApiException(l10n.verifyContactFailed);
      }
      return token;
    } on DioException catch (error) {
      throw PasswordResetApiException(
        _messageFromBody(error.response?.data, l10n, fallback: _networkMessage(error, l10n)),
      );
    }
  }

  Future<void> resendOtp({
    required String contact,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/password-reset/resend-otp',
        data: {'contact': contact, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw PasswordResetApiException(_messageFromBody(data, l10n));
      }
    } on DioException catch (error) {
      throw PasswordResetApiException(
        _messageFromBody(error.response?.data, l10n, fallback: _networkMessage(error, l10n)),
      );
    }
  }

  Future<LoginResult> setPassword({
    required String verificationToken,
    required String password,
    required String confirmPassword,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/password-reset/set-password',
        data: {
          'verificationToken': verificationToken,
          'password': password,
          'confirmPassword': confirmPassword,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw PasswordResetApiException(_messageFromBody(data, l10n));
      }
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw PasswordResetApiException(l10n.passwordResetFailed);
      }
      await _client.tokenStorage.writeToken(token);
      return LoginResult(
        token: token,
        accountType: data['accountType'] as String,
        homePath: data['homePath'] as String? ?? '/parent',
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw PasswordResetApiException(
        _messageFromBody(error.response?.data, l10n, fallback: _networkMessage(error, l10n)),
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

class PasswordResetApiException implements Exception {
  const PasswordResetApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
