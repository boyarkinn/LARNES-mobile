import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/time_zone_search_api.dart';
import 'package:larnes_mobile/core/auth/token_storage.dart';
import 'package:larnes_mobile/core/time/user_time_zone.dart';

class _MemoryTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => 'synthetic-mobile-session';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_timezone');
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'Europe/Moscow');
    await UserTimeZone.initialize();
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'shared endpoints use mobile auth and preserve null suggestion zones',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final api = ApiClient(
        dio: dio,
        tokenStorage: _MemoryTokenStorage(),
      ).timeZoneSearchApi;
      final paths = <String>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            paths.add(options.path);
            expect(
              options.headers['Authorization'],
              'Bearer synthetic-mobile-session',
            );
            expect(options.queryParameters['locale'], 'ru');
            expect(options.method, 'GET');
            expect(options.data, isNull);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: options.path.endsWith('suggest')
                    ? {
                        'status': 'success',
                        'suggestions': [
                          {
                            'kind': 'place',
                            'mapboxId': 'city-chelyabinsk',
                            'label': 'Челябинск, Россия',
                            'shortLabel': 'Челябинск',
                            'timeZone': null,
                          },
                        ],
                      }
                    : {
                        'status': 'success',
                        'selection': {
                          'mapboxId': 'city-chelyabinsk',
                          'label': 'Челябинск, Россия',
                          'timeZone': 'Asia/Yekaterinburg',
                        },
                      },
              ),
            );
          },
        ),
      );
      final suggestions = await api.suggest(query: 'Челябинск', locale: 'ru');
      expect(suggestions.single.timeZone, isNull);
      final selection = await api.resolve(
        mapboxId: suggestions.single.mapboxId,
        locale: 'ru',
      );
      expect(selection.timeZone, 'Asia/Yekaterinburg');
      expect(paths, ['/api/time-zones/suggest', '/api/time-zones/resolve']);
      dio.close();
    },
  );

  test(
    'rejects unresolved or mismatched city selections and structured API failures',
    () async {
      for (final body in [
        {
          'status': 'success',
          'selection': {'mapboxId': 'city', 'label': 'City', 'timeZone': null},
        },
        {
          'status': 'success',
          'selection': {
            'mapboxId': 'other',
            'label': 'City',
            'timeZone': 'UTC',
          },
        },
        {'status': 'error', 'error': 'unresolved'},
      ]) {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
        final api = ApiClient(
          dio: dio,
          tokenStorage: _MemoryTokenStorage(),
        ).timeZoneSearchApi;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: body),
            ),
          ),
        );
        await expectLater(
          api.resolve(mapboxId: 'city', locale: 'en'),
          throwsA(isA<TimeZoneSearchException>()),
        );
        dio.close();
      }
    },
  );

  test(
    'cancellation remains cancellable instead of becoming a search failure',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final api = ApiClient(
        dio: dio,
        tokenStorage: _MemoryTokenStorage(),
      ).timeZoneSearchApi;
      final cancellation = CancelToken()..cancel();
      await expectLater(
        api.suggest(query: 'London', locale: 'en', cancelToken: cancellation),
        throwsA(
          isA<DioException>().having(CancelToken.isCancel, 'is cancel', true),
        ),
      );
      dio.close();
    },
  );
}
