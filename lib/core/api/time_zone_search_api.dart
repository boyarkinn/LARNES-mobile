import 'package:dio/dio.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/api_error_body.dart';

class TimeZonePlaceSuggestion {
  const TimeZonePlaceSuggestion({
    required this.mapboxId,
    required this.label,
    required this.shortLabel,
    this.timeZone,
  });

  final String mapboxId;
  final String label;
  final String shortLabel;
  final String? timeZone;
}

class ResolvedTimeZonePlace {
  const ResolvedTimeZonePlace({
    required this.mapboxId,
    required this.label,
    required this.timeZone,
  });

  final String mapboxId;
  final String label;
  final String timeZone;
}

class TimeZoneSearchException implements Exception {
  const TimeZoneSearchException(this.code);
  final String code;
}

/// Uses the authenticated app client. These read-only endpoints never update a profile city.
class TimeZoneSearchApi {
  TimeZoneSearchApi(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> parameters,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await _client.dio.get(
        path,
        queryParameters: parameters,
        cancelToken: cancelToken,
      );
      final body = parseApiJsonBody(response.data);
      if (response.statusCode != 200 || body?['status'] != 'success') {
        throw TimeZoneSearchException(body?['error'] as String? ?? 'upstream');
      }
      return body!;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw const TimeZoneSearchException('upstream');
    }
  }

  Future<List<TimeZonePlaceSuggestion>> suggest({
    required String query,
    required String locale,
    CancelToken? cancelToken,
  }) async {
    final body = await _get('/api/time-zones/suggest', {
      'q': query,
      'locale': locale,
    }, cancelToken);
    final values = body['suggestions'];
    if (values is! List) throw const TimeZoneSearchException('upstream');
    return values
        .whereType<Map>()
        .where(
          (value) =>
              value['kind'] == 'place' &&
              value['mapboxId'] is String &&
              (value['mapboxId'] as String).isNotEmpty &&
              value['label'] is String &&
              value['shortLabel'] is String,
        )
        .map(
          (value) => TimeZonePlaceSuggestion(
            mapboxId: value['mapboxId'] as String,
            label: value['label'] as String,
            shortLabel: value['shortLabel'] as String,
            timeZone: value['timeZone'] is String
                ? value['timeZone'] as String
                : null,
          ),
        )
        .toList(growable: false);
  }

  Future<ResolvedTimeZonePlace> resolve({
    required String mapboxId,
    required String locale,
    CancelToken? cancelToken,
  }) async {
    final body = await _get('/api/time-zones/resolve', {
      'mapboxId': mapboxId,
      'locale': locale,
    }, cancelToken);
    final selection = body['selection'];
    if (selection is! Map ||
        selection['mapboxId'] != mapboxId ||
        selection['label'] is! String ||
        selection['timeZone'] is! String ||
        (selection['timeZone'] as String).isEmpty) {
      throw const TimeZoneSearchException('unresolved');
    }
    return ResolvedTimeZonePlace(
      mapboxId: mapboxId,
      label: selection['label'] as String,
      timeZone: selection['timeZone'] as String,
    );
  }
}
