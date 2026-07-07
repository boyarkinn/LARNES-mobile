import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
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

class FamilyInvitePerson {
  const FamilyInvitePerson({
    required this.userId,
    required this.firstName,
    this.lastName,
    this.patronymic,
  });

  factory FamilyInvitePerson.fromJson(Map<String, dynamic> json) {
    return FamilyInvitePerson(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      patronymic: json['patronymic'] as String?,
      userId: json['userId'] as String? ?? '',
    );
  }

  final String userId;
  final String firstName;
  final String? lastName;
  final String? patronymic;

  String get fullName =>
      [lastName, firstName, patronymic].where((part) => part != null && part.isNotEmpty).join(' ');
}

class FamilyJoinRequestInvitation {
  const FamilyJoinRequestInvitation({
    required this.token,
    required this.expiresAt,
    required this.requester,
  });

  factory FamilyJoinRequestInvitation.fromJson(Map<String, dynamic> json) {
    return FamilyJoinRequestInvitation(
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      requester: FamilyInvitePerson.fromJson(
        Map<String, dynamic>.from(json['requester'] as Map),
      ),
      token: json['token'] as String? ?? '',
    );
  }

  final String token;
  final DateTime expiresAt;
  final FamilyInvitePerson requester;
}

class FamilyGuardianInvitation {
  const FamilyGuardianInvitation({
    required this.token,
    required this.expiresAt,
    required this.inviter,
  });

  factory FamilyGuardianInvitation.fromJson(Map<String, dynamic> json) {
    return FamilyGuardianInvitation(
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      inviter: FamilyInvitePerson.fromJson(
        Map<String, dynamic>.from(json['inviter'] as Map),
      ),
      token: json['token'] as String? ?? '',
    );
  }

  final String token;
  final DateTime expiresAt;
  final FamilyInvitePerson inviter;
}

class FamilyInvitesApi {
  FamilyInvitesApi(this._client);

  final ApiClient _client;

  Future<FamilyJoinRequestInvitation> fetchJoinRequest({
    required String token,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/invites/family-join-request',
        queryParameters: {'token': token, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyInvitesApiException(_messageFromBody(data, l10n));
      }
      final invitation = data['invitation'];
      if (invitation is! Map) {
        throw FamilyInvitesApiException(l10n.requestFailed);
      }
      return FamilyJoinRequestInvitation.fromJson(Map<String, dynamic>.from(invitation));
    } on DioException catch (error) {
      throw FamilyInvitesApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<FamilyGuardianInvitation> fetchGuardianInvite({
    required String token,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/invites/family-guardian',
        queryParameters: {'token': token, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyInvitesApiException(_messageFromBody(data, l10n));
      }
      final invitation = data['invitation'];
      if (invitation is! Map) {
        throw FamilyInvitesApiException(l10n.requestFailed);
      }
      return FamilyGuardianInvitation.fromJson(Map<String, dynamic>.from(invitation));
    } on DioException catch (error) {
      throw FamilyInvitesApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<void> acceptJoinRequest({
    required String token,
    String locale = 'ru',
  }) {
    return _postToken('/api/mobile/parent/invites/family-join-request/accept', token, locale);
  }

  Future<void> declineJoinRequest({
    required String token,
    String locale = 'ru',
  }) {
    return _postToken('/api/mobile/parent/invites/family-join-request/decline', token, locale);
  }

  Future<void> acceptGuardianInvite({
    required String token,
    String locale = 'ru',
  }) {
    return _postToken('/api/mobile/parent/invites/family-guardian/accept', token, locale);
  }

  Future<void> declineGuardianInvite({
    required String token,
    String locale = 'ru',
  }) {
    return _postToken('/api/mobile/parent/invites/family-guardian/decline', token, locale);
  }

  Future<void> _postToken(String path, String token, String locale) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        path,
        data: {'token': token, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyInvitesApiException(
          _messageFromBody(data, l10n),
          code: data?['code'] as String?,
        );
      }
    } on DioException catch (error) {
      final data = _asJsonMap(error.response?.data);
      throw FamilyInvitesApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
        code: data?['code'] as String?,
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

class FamilyInvitesApiException implements Exception {
  const FamilyInvitesApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
