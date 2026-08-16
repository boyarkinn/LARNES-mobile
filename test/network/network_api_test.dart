import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/network_api.dart';

Dio _mockDio(
  Map<String, dynamic> Function(RequestOptions options) respond, {
  void Function(RequestOptions options)? onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(options);
        handler.resolve(
          Response(
            requestOptions: options,
            data: respond(options),
          ),
        );
      },
    ),
  );
  return dio;
}

Dio _mockDioWithErrors({
  required Map<String, dynamic> Function(RequestOptions options) respond,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final result = respond(options);
        if (result.containsKey('__errorStatus')) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: result['__errorStatus'] as int,
                data: result['__errorBody'],
              ),
            ),
          );
          return;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            data: result,
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  group('NetworkApi.listCenters', () {
    test('parses success payload', () async {
      final api = NetworkApi(
        ApiClient(
          dio: _mockDio(
            (_) => {
              'status': 'success',
              'centers': [
                {
                  'id': '11111111-1111-4111-8111-111111111111',
                  'name': 'Center A',
                  'ownerUserId': '22222222-2222-4222-8222-222222222222',
                  'createdAt': '2026-07-06T10:00:00.000Z',
                  'city': 'Moscow',
                },
              ],
            },
          ),
        ),
      );

      final centers = await api.listCenters();
      expect(centers, hasLength(1));
      expect(centers.first.name, 'Center A');
      expect(centers.first.city, 'Moscow');
    });

    test('throws on error status', () async {
      final api = NetworkApi(
        ApiClient(
          dio: _mockDio((_) => {'status': 'error', 'message': 'Forbidden'}),
        ),
      );

      expect(() => api.listCenters(), throwsA(isA<NetworkApiException>()));
    });
  });

  group('NetworkApi.listDevices', () {
    test('parses success payload', () async {
      final api = NetworkApi(
        ApiClient(
          dio: _mockDio(
            (_) => {
              'status': 'success',
              'devices': [
                {
                  'id': '33333333-3333-4333-8333-333333333333',
                  'kind': 'tablet',
                  'isOnline': true,
                  'slotLabel': 'M1',
                },
              ],
            },
          ),
        ),
      );

      final devices = await api.listDevices();
      expect(devices, hasLength(1));
      expect(devices.first.slotLabel, 'M1');
      expect(devices.first.isOnline, isTrue);
    });
  });

  group('NetworkApi.unbindDevice', () {
    test('posts deviceId and parses success', () async {
      RequestOptions? captured;

      final api = NetworkApi(
        ApiClient(
          dio: _mockDio(
            (_) => {
              'status': 'success',
              'ok': true,
            },
            onRequest: (options) => captured = options,
          ),
        ),
      );

      await api.unbindDevice(
        deviceId: '55555555-5555-4555-8555-555555555555',
      );

      expect(captured?.path, '/api/mobile/network/devices/unbind');
      expect(captured?.method, 'POST');
      expect(captured?.data, {
        'deviceId': '55555555-5555-4555-8555-555555555555',
        'locale': 'ru',
      });
    });

    test('throws with server code on device not found', () async {
      final api = NetworkApi(
        ApiClient(
          dio: _mockDioWithErrors(
            respond: (_) => {
              '__errorStatus': 404,
              '__errorBody': {
                'status': 'error',
                'code': 'device_not_found',
                'message': 'Устройство не найдено',
              },
            },
          ),
        ),
      );

      expect(
        () => api.unbindDevice(
          deviceId: '55555555-5555-4555-8555-555555555555',
        ),
        throwsA(
          isA<NetworkApiException>()
              .having((error) => error.code, 'code', 'device_not_found')
              .having((error) => error.message, 'message', 'Устройство не найдено'),
        ),
      );
    });
  });
}
