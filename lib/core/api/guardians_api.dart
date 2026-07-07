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

class FamilyGuardian {
  const FamilyGuardian({
    required this.userId,
    required this.firstName,
    required this.isSelf,
    required this.joinedAt,
    required this.relationship,
    this.lastName,
    this.patronymic,
  });

  factory FamilyGuardian.fromJson(Map<String, dynamic> json) {
    return FamilyGuardian(
      firstName: json['firstName'] as String? ?? '',
      isSelf: json['isSelf'] as bool? ?? false,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      lastName: json['lastName'] as String?,
      patronymic: json['patronymic'] as String?,
      relationship: json['relationship'] as String? ?? 'mother',
      userId: json['userId'] as String? ?? '',
    );
  }

  final String userId;
  final String firstName;
  final String? lastName;
  final String? patronymic;
  final String relationship;
  final bool isSelf;
  final DateTime joinedAt;

  String get fullName =>
      [lastName, firstName, patronymic].where((part) => part != null && part.isNotEmpty).join(' ');
}

class PendingGuardianInvite {
  const PendingGuardianInvite({
    required this.id,
    required this.token,
    required this.inviteUrl,
    required this.createdAt,
    required this.expiresAt,
  });

  factory PendingGuardianInvite.fromJson(Map<String, dynamic> json) {
    return PendingGuardianInvite(
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      id: json['id'] as String? ?? '',
      inviteUrl: json['inviteUrl'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }

  final String id;
  final String token;
  final String inviteUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
}

class GuardianInviteResult {
  const GuardianInviteResult({
    required this.id,
    required this.token,
    required this.inviteUrl,
  });

  factory GuardianInviteResult.fromJson(Map<String, dynamic> json) {
    return GuardianInviteResult(
      id: json['id'] as String? ?? '',
      inviteUrl: json['inviteUrl'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }

  final String id;
  final String token;
  final String inviteUrl;
}

class GuardiansSnapshot {
  const GuardiansSnapshot({
    required this.guardians,
    required this.pendingInvites,
  });

  final List<FamilyGuardian> guardians;
  final List<PendingGuardianInvite> pendingInvites;
}

class GuardiansApi {
  GuardiansApi(this._client);

  final ApiClient _client;

  Future<GuardiansSnapshot> fetchGuardians({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/guardians',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw GuardiansApiException(_messageFromBody(data, l10n));
      }
      final guardiansRaw = data['guardians'];
      final invitesRaw = data['pendingGuardianInvites'];
      return GuardiansSnapshot(
        guardians: guardiansRaw is List
            ? guardiansRaw
                .whereType<Map>()
                .map((item) => FamilyGuardian.fromJson(Map<String, dynamic>.from(item)))
                .toList()
            : const [],
        pendingInvites: invitesRaw is List
            ? invitesRaw
                .whereType<Map>()
                .map((item) => PendingGuardianInvite.fromJson(Map<String, dynamic>.from(item)))
                .toList()
            : const [],
      );
    } on DioException catch (error) {
      throw GuardiansApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<GuardianInviteResult> createInvite({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/guardians',
        data: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw GuardiansApiException(_messageFromBody(data, l10n));
      }
      final invite = data['invite'];
      if (invite is! Map) {
        throw GuardiansApiException(l10n.requestFailed);
      }
      return GuardianInviteResult.fromJson(Map<String, dynamic>.from(invite));
    } on DioException catch (error) {
      throw GuardiansApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<void> revokeInvite({
    required String inviteId,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/guardians/invite/revoke',
        data: {'inviteId': inviteId, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw GuardiansApiException(_messageFromBody(data, l10n));
      }
    } on DioException catch (error) {
      throw GuardiansApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<void> removeGuardian({
    required String targetUserId,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/guardians/remove',
        data: {'targetUserId': targetUserId, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw GuardiansApiException(_messageFromBody(data, l10n));
      }
    } on DioException catch (error) {
      throw GuardiansApiException(
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

class GuardiansApiException implements Exception {
  const GuardiansApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
