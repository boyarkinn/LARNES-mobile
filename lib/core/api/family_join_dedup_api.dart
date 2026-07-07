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

class FamilyJoinDedupChildCard {
  const FamilyJoinDedupChildCard({
    required this.childId,
    required this.createdAt,
    required this.fullName,
    this.homeworkHint,
    this.networkHint,
    this.programHint,
  });

  factory FamilyJoinDedupChildCard.fromJson(Map<String, dynamic> json) {
    return FamilyJoinDedupChildCard(
      childId: json['childId'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      fullName: json['fullName'] as String? ?? '',
      homeworkHint: json['homeworkHint'] as String?,
      networkHint: json['networkHint'] as String?,
      programHint: json['programHint'] as String?,
    );
  }

  final String childId;
  final DateTime createdAt;
  final String fullName;
  final String? homeworkHint;
  final String? networkHint;
  final String? programHint;
}

class FamilyJoinDedupContext {
  const FamilyJoinDedupContext({
    required this.displayFirstName,
    required this.kind,
    required this.normalizedFirstName,
    required this.remainingCount,
    required this.sourceChild,
    required this.targetChild,
    required this.token,
  });

  factory FamilyJoinDedupContext.fromJson(Map<String, dynamic> json) {
    return FamilyJoinDedupContext(
      displayFirstName: json['displayFirstName'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      normalizedFirstName: json['normalizedFirstName'] as String? ?? '',
      remainingCount: json['remainingCount'] as int? ?? 0,
      sourceChild: FamilyJoinDedupChildCard.fromJson(
        Map<String, dynamic>.from(json['sourceChild'] as Map? ?? const {}),
      ),
      targetChild: FamilyJoinDedupChildCard.fromJson(
        Map<String, dynamic>.from(json['targetChild'] as Map? ?? const {}),
      ),
      token: json['token'] as String? ?? '',
    );
  }

  final String displayFirstName;
  final String kind;
  final String normalizedFirstName;
  final int remainingCount;
  final FamilyJoinDedupChildCard sourceChild;
  final FamilyJoinDedupChildCard targetChild;
  final String token;
}

class FamilyJoinDedupResolveResult {
  const FamilyJoinDedupResolveResult({
    required this.completed,
    this.next,
  });

  factory FamilyJoinDedupResolveResult.fromJson(Map<String, dynamic> json) {
    final nextJson = json['context'];
    return FamilyJoinDedupResolveResult(
      completed: json['completed'] as bool? ?? false,
      next: nextJson is Map<String, dynamic>
          ? FamilyJoinDedupContext.fromJson(nextJson)
          : null,
    );
  }

  final bool completed;
  final FamilyJoinDedupContext? next;
}

class FamilyJoinDedupApi {
  FamilyJoinDedupApi(this._client);

  final ApiClient _client;

  Future<FamilyJoinDedupContext?> fetchContext({
    required String token,
    required String kind,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/mobile/parent/family-join-dedup',
        queryParameters: {'token': token, 'kind': kind, 'locale': locale},
      );
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyJoinDedupApiException(_messageFromBody(data, l10n));
      }
      final contextJson = data['context'];
      if (contextJson is! Map<String, dynamic>) {
        return null;
      }
      return FamilyJoinDedupContext.fromJson(contextJson);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw FamilyJoinDedupApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: _networkMessage(error, l10n),
        ),
      );
    }
  }

  Future<FamilyJoinDedupResolveResult> resolveDifferentChildren({
    required String token,
    required String kind,
    required String normalizedFirstName,
    String locale = 'ru',
  }) {
    return _resolve(
      '/api/mobile/parent/family-join-dedup/different-children',
      {
        'token': token,
        'kind': kind,
        'normalizedFirstName': normalizedFirstName,
        'locale': locale,
      },
      locale,
    );
  }

  Future<FamilyJoinDedupResolveResult> resolvePickKeeper({
    required String token,
    required String kind,
    required String normalizedFirstName,
    required String keeperChildId,
    String locale = 'ru',
  }) {
    return _resolve(
      '/api/mobile/parent/family-join-dedup/pick-keeper',
      {
        'token': token,
        'kind': kind,
        'normalizedFirstName': normalizedFirstName,
        'keeperChildId': keeperChildId,
        'locale': locale,
      },
      locale,
    );
  }

  Future<FamilyJoinDedupResolveResult> _resolve(
    String path,
    Map<String, dynamic> body,
    String locale,
  ) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.post(path, data: body);
      final data = _asJsonMap(response.data);
      if (data == null || data['status'] != 'success') {
        throw FamilyJoinDedupApiException(_messageFromBody(data, l10n));
      }
      return FamilyJoinDedupResolveResult.fromJson(data);
    } on DioException catch (error) {
      throw FamilyJoinDedupApiException(
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

class FamilyJoinDedupApiException implements Exception {
  const FamilyJoinDedupApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
