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

class FamilyAdultClaimApiException implements Exception {
  FamilyAdultClaimApiException(this.message, {this.verificationExpired = false});

  final String message;
  final bool verificationExpired;
}

class FamilyAdultClaimParentDraft {
  const FamilyAdultClaimParentDraft({
    required this.firstName,
    this.city,
    this.dateOfBirth,
    this.lastName,
    this.patronymic,
    this.placeId,
  });

  factory FamilyAdultClaimParentDraft.fromJson(Map<String, dynamic> json) {
    return FamilyAdultClaimParentDraft(
      city: json['city'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      patronymic: json['patronymic'] as String?,
      placeId: json['placeId'] as String?,
    );
  }

  final String? city;
  final String? dateOfBirth;
  final String firstName;
  final String? lastName;
  final String? patronymic;
  final String? placeId;
}

class FamilyAdultClaimInvitation {
  const FamilyAdultClaimInvitation({
    required this.contact,
    required this.contactChannel,
    required this.contactMasked,
    required this.expiresAt,
    required this.familyDisplayName,
    required this.mode,
    required this.networkName,
    required this.parent,
    required this.termsVersionId,
    required this.token,
  });

  factory FamilyAdultClaimInvitation.fromJson(Map<String, dynamic> json) {
    return FamilyAdultClaimInvitation(
      contact: json['contact'] as String? ?? '',
      contactChannel: json['contactChannel'] as String? ?? 'sms',
      contactMasked: json['contactMasked'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      familyDisplayName: json['familyDisplayName'] as String? ?? '',
      mode: json['mode'] as String? ?? 'register',
      networkName: json['networkName'] as String? ?? '',
      parent: FamilyAdultClaimParentDraft.fromJson(
        Map<String, dynamic>.from(json['parent'] as Map? ?? const {}),
      ),
      termsVersionId: json['termsVersionId'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }

  final String contact;
  final String contactChannel;
  final String contactMasked;
  final DateTime expiresAt;
  final String familyDisplayName;
  final String mode;
  final String networkName;
  final FamilyAdultClaimParentDraft parent;
  final String termsVersionId;
  final String token;

  bool get isLoggedIn => mode == 'loggedIn';
  bool get isWrongAccount => mode == 'wrong_account';
}

class FamilyAdultClaimCompleteResult {
  const FamilyAdultClaimCompleteResult({
    required this.next,
    required this.token,
    required this.user,
  });

  final String next;
  final String token;
  final AuthUser user;
}

class FamilyAdultClaimApi {
  FamilyAdultClaimApi(this._client);

  final ApiClient _client;

  Future<FamilyAdultClaimInvitation> fetchInvite({
    required String token,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/invites/family-adult-claim',
        queryParameters: {'token': token, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyAdultClaimApiException(_messageFromBody(data, l10n));
      }
      return FamilyAdultClaimInvitation.fromJson(
        Map<String, dynamic>.from(data['invitation'] as Map),
      );
    } on DioException catch (error) {
      throw FamilyAdultClaimApiException(
        _messageFromBody(error.response?.data, l10n, fallback: l10n.requestFailed),
      );
    }
  }

  Future<void> sendOtp({required String token, String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/invites/family-adult-claim/send-otp',
        data: {'token': token, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyAdultClaimApiException(_messageFromBody(data, l10n));
      }
    } on DioException catch (error) {
      throw FamilyAdultClaimApiException(
        _messageFromBody(error.response?.data, l10n, fallback: l10n.requestFailed),
      );
    }
  }

  Future<String> verifyOtp({
    required String token,
    required String code,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/invites/family-adult-claim/verify-otp',
        data: {'token': token, 'code': code, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyAdultClaimApiException(_messageFromBody(data, l10n));
      }
      return data['claimVerificationToken'] as String? ?? '';
    } on DioException catch (error) {
      throw FamilyAdultClaimApiException(
        _messageFromBody(error.response?.data, l10n, fallback: l10n.requestFailed),
      );
    }
  }

  Future<FamilyAdultClaimCompleteResult> complete({
    required String token,
    required String claimVerificationToken,
    required String firstName,
    required String lastName,
    required String patronymic,
    required String dateOfBirth,
    required String password,
    required String confirmPassword,
    required String placeMapboxId,
    required bool termsAccepted,
    required String termsVersionId,
    required String idempotencyKey,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/invites/family-adult-claim/complete',
        data: {
          'token': token,
          'claimVerificationToken': claimVerificationToken,
          'firstName': firstName,
          'lastName': lastName,
          'patronymic': patronymic,
          'dateOfBirth': dateOfBirth,
          'password': password,
          'confirmPassword': confirmPassword,
          'placeMapboxId': placeMapboxId,
          'termsAccepted': termsAccepted,
          'termsVersionId': termsVersionId,
          'idempotencyKey': idempotencyKey,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyAdultClaimApiException(
          _messageFromBody(data, l10n),
          verificationExpired: data?['verificationExpired'] == true,
        );
      }
      final sessionToken = data['token'] as String? ?? '';
      await _client.tokenStorage.writeToken(sessionToken);
      return FamilyAdultClaimCompleteResult(
        next: data['next'] as String? ?? 'parent',
        token: sessionToken,
        user: AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
      );
    } on DioException catch (error) {
      final data = _asJsonMap(error.response?.data);
      throw FamilyAdultClaimApiException(
        _messageFromBody(data, l10n, fallback: l10n.requestFailed),
        verificationExpired: data?['verificationExpired'] == true,
      );
    }
  }

  Future<String> accept({
    required String token,
    required String claimVerificationToken,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/invites/family-adult-claim/accept',
        data: {
          'token': token,
          'claimVerificationToken': claimVerificationToken,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyAdultClaimApiException(
          _messageFromBody(data, l10n),
          verificationExpired: data?['verificationExpired'] == true,
        );
      }
      return data['next'] as String? ?? 'parent';
    } on DioException catch (error) {
      final data = _asJsonMap(error.response?.data);
      throw FamilyAdultClaimApiException(
        _messageFromBody(data, l10n, fallback: l10n.requestFailed),
        verificationExpired: data?['verificationExpired'] == true,
      );
    }
  }

  Future<void> decline({required String token, String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/invites/family-adult-claim/decline',
        data: {'token': token, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyAdultClaimApiException(_messageFromBody(data, l10n));
      }
    } on DioException catch (error) {
      throw FamilyAdultClaimApiException(
        _messageFromBody(error.response?.data, l10n, fallback: l10n.requestFailed),
      );
    }
  }
}
