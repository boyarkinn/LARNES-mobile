import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/config/mobile_config.dart';
import 'package:larnes_mobile/core/config/turnstile_url.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';

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

class RegisterApi {
  RegisterApi(this._client);

  final ApiClient _client;
  MobileConfig? _cachedConfig;

  Future<MobileConfig> fetchConfig({bool forceRefresh = false}) async {
    if (_cachedConfig != null && !forceRefresh) {
      return _cachedConfig!;
    }

    try {
      final response = await _client.dio.get('/api/mobile/config');
      final data = _asJsonMap(response.data);
      if (data != null && data['status'] == 'success') {
        _cachedConfig = MobileConfig.fromJson(data);
        return MobileConfig(
          cities: _cachedConfig!.cities,
          turnstilePageUrl: normalizeTurnstilePageUrl(_cachedConfig!.turnstilePageUrl),
          turnstileRequired: _cachedConfig!.turnstileRequired,
          turnstileSiteKey: _cachedConfig!.turnstileSiteKey,
        );
      }
    } on DioException {
      // Fallback for offline dev.
    }

    return _cachedConfig ?? MobileConfig.fallback;
  }

  Future<String> sendOtp({
    required RegisterContactChannel channel,
    required String contact,
    String? turnstileToken,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/register/send-otp',
        data: {
          'channel': _channelValue(channel),
          'contact': contact,
          'locale': locale,
          if (turnstileToken != null && turnstileToken.isNotEmpty)
            'turnstileToken': turnstileToken,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw RegisterApiException(_messageFromBody(data, l10n));
      }
      final normalized = data['contact'] as String?;
      if (normalized == null || normalized.isEmpty) {
        throw RegisterApiException(l10n.sendCodeFailed);
      }
      return normalized;
    } on DioException catch (error) {
      throw RegisterApiException(
        _messageFromBody(error.response?.data, l10n, fallback: _networkMessage(error, l10n)),
      );
    }
  }

  Future<String> verifyOtp({
    required RegisterContactChannel channel,
    required String contact,
    required String code,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/register/verify-otp',
        data: {
          'channel': _channelValue(channel),
          'contact': contact,
          'code': code,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw RegisterApiException(_messageFromBody(data, l10n));
      }
      final token = data['verificationToken'] as String?;
      if (token == null || token.isEmpty) {
        throw RegisterApiException(l10n.verifyContactFailed);
      }
      return token;
    } on DioException catch (error) {
      throw RegisterApiException(
        _messageFromBody(error.response?.data, l10n, fallback: _networkMessage(error, l10n)),
      );
    }
  }

  Future<void> resendOtp({
    required RegisterContactChannel channel,
    required String contact,
    String? turnstileToken,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/register/resend-otp',
        data: {
          'channel': _channelValue(channel),
          'contact': contact,
          'locale': locale,
          if (turnstileToken != null && turnstileToken.isNotEmpty)
            'turnstileToken': turnstileToken,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw RegisterApiException(_messageFromBody(data, l10n));
      }
    } on DioException catch (error) {
      throw RegisterApiException(
        _messageFromBody(error.response?.data, l10n, fallback: _networkMessage(error, l10n)),
      );
    }
  }

  Future<LoginResult> register({
    required RegisterFlowData flow,
    required String verificationToken,
    required Map<String, String> profile,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/register',
        data: {
          'accountType': _accountTypeValue(flow.accountType),
          'channel': _channelValue(flow.channel),
          'contact': flow.contact,
          'locale': locale,
          'verificationToken': verificationToken,
          ...profile,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw RegisterApiException(_messageFromBody(data, l10n));
      }
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw RegisterApiException(l10n.createAccountFailed);
      }
      await _client.tokenStorage.writeToken(token);
      return LoginResult(
        token: token,
        accountType: data['accountType'] as String,
        homePath: data['homePath'] as String? ?? '/parent',
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw RegisterApiException(
        _messageFromBody(error.response?.data, l10n, fallback: _networkMessage(error, l10n)),
      );
    }
  }

  static String _channelValue(RegisterContactChannel channel) {
    return channel == RegisterContactChannel.email ? 'email' : 'sms';
  }

  static String _accountTypeValue(RegisterAccountType accountType) {
    switch (accountType) {
      case RegisterAccountType.parent:
        return 'parent';
      case RegisterAccountType.teacher:
        return 'teacher';
      case RegisterAccountType.networkOwner:
        return 'network_owner';
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

class RegisterApiException implements Exception {
  const RegisterApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
