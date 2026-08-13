import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/api/register_api.dart';
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

class RegisterSchoolOffersApiException implements Exception {
  RegisterSchoolOffersApiException(this.message);
  final String message;
}

class PendingSchoolOffer {
  const PendingSchoolOffer({
    required this.adultContactId,
    required this.childId,
    required this.childFirstName,
    required this.familyId,
    required this.ownerUserId,
    required this.parentFirstName,
    required this.parentLastName,
    required this.parentPatronymic,
    required this.parentDateOfBirth,
    this.childDateOfBirth,
    this.childGender,
    this.childLastName,
    this.childPatronymic,
    this.networkDisplayName,
    this.parentCity,
    this.parentPlaceId,
  });

  factory PendingSchoolOffer.fromJson(Map<String, dynamic> json) {
    return PendingSchoolOffer(
      adultContactId: json['adultContactId'] as String? ?? '',
      childDateOfBirth: json['childDateOfBirth'] as String?,
      childFirstName: json['childFirstName'] as String? ?? '',
      childGender: json['childGender'] as String?,
      childId: json['childId'] as String? ?? '',
      childLastName: json['childLastName'] as String?,
      childPatronymic: json['childPatronymic'] as String?,
      familyId: json['familyId'] as String? ?? '',
      networkDisplayName: json['networkDisplayName'] as String?,
      ownerUserId: json['ownerUserId'] as String? ?? '',
      parentCity: json['parentCity'] as String?,
      parentDateOfBirth: json['parentDateOfBirth'] as String? ?? '',
      parentFirstName: json['parentFirstName'] as String? ?? '',
      parentLastName: json['parentLastName'] as String? ?? '',
      parentPatronymic: json['parentPatronymic'] as String? ?? '',
      parentPlaceId: json['parentPlaceId'] as String?,
    );
  }

  final String adultContactId;
  final String? childDateOfBirth;
  final String childFirstName;
  final String? childGender;
  final String childId;
  final String? childLastName;
  final String? childPatronymic;
  final String familyId;
  final String? networkDisplayName;
  final String ownerUserId;
  final String? parentCity;
  final String parentDateOfBirth;
  final String parentFirstName;
  final String parentLastName;
  final String parentPatronymic;
  final String? parentPlaceId;
}

class RegisterSchoolOffersApi {
  RegisterSchoolOffersApi(this._client);

  final ApiClient _client;

  Future<List<PendingSchoolOffer>> listOffers({
    required RegisterContactChannel channel,
    required String contact,
    required String verificationToken,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/register/school-offers',
        data: {
          'channel': channel == RegisterContactChannel.email ? 'email' : 'sms',
          'contact': contact,
          'verificationToken': verificationToken,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw RegisterSchoolOffersApiException(_messageFromBody(data, l10n));
      }
      final offers = data['offers'] as List<dynamic>? ?? const [];
      return offers
          .map((item) => PendingSchoolOffer.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException catch (error) {
      throw RegisterSchoolOffersApiException(
        _messageFromBody(error.response?.data, l10n, fallback: l10n.requestFailed),
      );
    }
  }

  Future<void> skip({
    required RegisterContactChannel channel,
    required String contact,
    required String verificationToken,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/register/school-offers/skip',
        data: {
          'channel': channel == RegisterContactChannel.email ? 'email' : 'sms',
          'contact': contact,
          'verificationToken': verificationToken,
          'locale': locale,
        },
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw RegisterSchoolOffersApiException(_messageFromBody(data, l10n));
      }
    } on DioException catch (error) {
      throw RegisterSchoolOffersApiException(
        _messageFromBody(error.response?.data, l10n, fallback: l10n.requestFailed),
      );
    }
  }

  Future<LoginResult> complete({
    required Map<String, dynamic> payload,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(
        '/api/mobile/auth/register/school-offers/complete',
        data: {...payload, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw RegisterSchoolOffersApiException(_messageFromBody(data, l10n));
      }
      final token = data['token'] as String? ?? '';
      await _client.tokenStorage.writeToken(token);
      return LoginResult(
        token: token,
        accountType: data['accountType'] as String? ?? 'parent',
        homePath: data['homePath'] as String? ?? '/parent',
        user: AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
      );
    } on DioException catch (error) {
      throw RegisterSchoolOffersApiException(
        _messageFromBody(error.response?.data, l10n, fallback: l10n.requestFailed),
      );
    }
  }
}
