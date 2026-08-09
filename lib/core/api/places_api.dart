import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/api_error_body.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.label,
    required this.mapboxId,
    required this.shortLabel,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      label: json['label'] as String? ?? '',
      mapboxId: json['mapboxId'] as String? ?? '',
      shortLabel: json['shortLabel'] as String? ?? '',
    );
  }

  final String label;
  final String mapboxId;
  final String shortLabel;
}

class ResolvedPlace {
  const ResolvedPlace({
    required this.displayLabel,
    required this.mapboxId,
    this.city,
  });

  factory ResolvedPlace.fromJson(Map<String, dynamic> json) {
    return ResolvedPlace(
      displayLabel: json['displayLabel'] as String? ?? '',
      mapboxId: json['mapboxId'] as String? ?? '',
      city: json['city'] as String?,
    );
  }

  final String displayLabel;
  final String mapboxId;
  final String? city;
}

class PlaceCitySelection {
  const PlaceCitySelection({
    required this.displayLabel,
    required this.mapboxId,
  });

  final String displayLabel;
  final String mapboxId;
}

class PlacesApi {
  PlacesApi(this._client);

  final ApiClient _client;

  Future<List<PlaceSuggestion>> suggest({
    required String mode,
    required String query,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/places/suggest',
        queryParameters: {
          'locale': locale,
          'mode': mode,
          'q': query,
        },
      );
      final data = parseApiJsonBody(response.data);
      if (data == null || data['status'] != 'success') {
        throw PlacesApiException(_messageFromBody(data, l10n));
      }

      return (data['suggestions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((entry) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(entry)))
          .where((suggestion) => suggestion.mapboxId.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (error) {
      throw PlacesApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: apiNetworkMessage(error, l10n),
        ),
      );
    }
  }

  Future<ResolvedPlace> resolve({
    required String mode,
    required String mapboxId,
    String locale = 'ru',
  }) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      final response = await _client.dio.get(
        '/api/places/resolve',
        queryParameters: {
          'locale': locale,
          'mode': mode,
          'mapboxId': mapboxId,
        },
      );
      final data = parseApiJsonBody(response.data);
      if (data == null || data['status'] != 'success') {
        throw PlacesApiException(_messageFromBody(data, l10n));
      }

      final place = data['place'];
      if (place is! Map) {
        throw PlacesApiException(l10n.placesAutocompleteInvalidSelection);
      }

      return ResolvedPlace.fromJson(Map<String, dynamic>.from(place));
    } on DioException catch (error) {
      throw PlacesApiException(
        _messageFromBody(
          error.response?.data,
          l10n,
          fallback: apiNetworkMessage(error, l10n),
        ),
      );
    }
  }

  static String _messageFromBody(
    dynamic body,
    AppLocalizations l10n, {
    String? fallback,
  }) =>
      apiMessageFromBody(body, l10n, fallback: fallback ?? l10n.placesAutocompleteUnavailable);
}

class PlacesApiException implements Exception {
  const PlacesApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
