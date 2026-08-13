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

class ConfirmFamilyChildrenApiException implements Exception {
  ConfirmFamilyChildrenApiException(this.message);
  final String message;
}

class ConfirmFamilyChildDraft {
  ConfirmFamilyChildDraft({
    required this.id,
    required this.firstName,
    this.dateOfBirth,
    this.displayName,
    this.gender,
    this.lastName,
    this.patronymic,
  });

  factory ConfirmFamilyChildDraft.fromJson(Map<String, dynamic> json) {
    return ConfirmFamilyChildDraft(
      dateOfBirth: json['dateOfBirth'] as String?,
      displayName: json['displayName'] as String?,
      firstName: json['firstName'] as String? ?? '',
      gender: json['gender'] as String?,
      id: json['id'] as String? ?? '',
      lastName: json['lastName'] as String?,
      patronymic: json['patronymic'] as String?,
    );
  }

  final String id;
  String firstName;
  String? dateOfBirth;
  String? displayName;
  String? gender;
  String? lastName;
  String? patronymic;
}

class PendingConfirmFamily {
  const PendingConfirmFamily({
    required this.childDataConsentVersionId,
    required this.children,
    required this.familyDisplayName,
    required this.familyId,
  });

  factory PendingConfirmFamily.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? const [];
    return PendingConfirmFamily(
      childDataConsentVersionId: json['childDataConsentVersionId'] as String? ?? '',
      children: childrenJson
          .map((item) => ConfirmFamilyChildDraft.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      familyDisplayName: json['familyDisplayName'] as String? ?? '',
      familyId: json['familyId'] as String? ?? '',
    );
  }

  final String childDataConsentVersionId;
  final List<ConfirmFamilyChildDraft> children;
  final String familyDisplayName;
  final String familyId;
}

class ConfirmFamilyChildrenApi {
  ConfirmFamilyChildrenApi(this._client);

  final ApiClient _client;

  Future<PendingConfirmFamily?> fetchPending({String locale = 'ru'}) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/family/confirm-children',
        queryParameters: {'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ConfirmFamilyChildrenApiException(_messageFromBody(data, l10n));
      }
      final pending = data['pending'];
      if (pending == null) {
        return null;
      }
      return PendingConfirmFamily.fromJson(Map<String, dynamic>.from(pending as Map));
    } on DioException catch (error) {
      throw ConfirmFamilyChildrenApiException(
        _messageFromBody(error.response?.data, l10n, fallback: l10n.requestFailed),
      );
    }
  }

  Future<void> confirm({
    required String familyId,
    required String documentVersionId,
    required String idempotencyKey,
    required List<ConfirmFamilyChildDraft> children,
    required String authorityBasis,
    required bool authorityDeclared,
    required bool consentAccepted,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/parent/family/confirm-children',
        data: {
          'familyId': familyId,
          'documentVersionId': documentVersionId,
          'idempotencyKey': idempotencyKey,
          'authorityBasis': authorityBasis,
          'authorityDeclared': authorityDeclared,
          'consentAccepted': consentAccepted,
          'locale': locale,
          'children': children
              .map(
                (child) => {
                  'childId': child.id,
                  'firstName': child.firstName,
                  'lastName': child.lastName ?? '',
                  'patronymic': child.patronymic ?? '',
                  'dateOfBirth': child.dateOfBirth ?? '',
                  'gender': child.gender ?? '',
                },
              )
              .toList(),
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw ConfirmFamilyChildrenApiException(_messageFromBody(data, l10n));
      }
    } on DioException catch (error) {
      throw ConfirmFamilyChildrenApiException(
        _messageFromBody(error.response?.data, l10n, fallback: l10n.requestFailed),
      );
    }
  }
}
