import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/api/kiosk_api_client.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';

import 'memory_device_token_storage.dart';

void main() {
  group('KioskDeviceContext.fromJson', () {
    test('parses placement payload', () {
      final context = KioskDeviceContext.fromJson({
        'deviceId': '55555555-5555-4555-8555-555555555555',
        'kind': 'phone',
        'centerName': 'Center A',
        'classroomId': '44444444-4444-4444-8444-444444444444',
        'classroomTitle': 'Room 1',
        'slotLabel': 'M1',
        'lesson': null,
      });

      expect(context.deviceId, '55555555-5555-4555-8555-555555555555');
      expect(context.kind, NetworkDeviceKind.phone);
      expect(context.slotLabel, 'M1');
      expect(context.lesson, isNull);
    });

    test('parses active lesson binding', () {
      final context = KioskDeviceContext.fromJson({
        'deviceId': '55555555-5555-4555-8555-555555555555',
        'kind': 'tablet',
        'slotLabel': 'M1',
        'lesson': {
          'commandSeq': 3,
          'lessonSessionId': '66666666-6666-4666-8666-666666666666',
          'pendingCommand': 'open_scan',
          'status': 'waiting_scan',
        },
      });

      expect(context.lesson?.pendingCommand, 'open_scan');
      expect(context.lesson?.commandSeq, 3);
    });
  });

  group('KioskApi.getDeviceMe', () {
    test('parses success payload and sends device bearer', () async {
      RequestOptions? captured;
      final tokenStorage = MemoryDeviceTokenStorage();
      await tokenStorage.writeToken('device-jwt-token');

      final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final client = KioskApiClient(
        deviceTokenStorage: tokenStorage,
        dio: dio,
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'deviceId': '55555555-5555-4555-8555-555555555555',
                  'kind': 'phone',
                  'centerName': 'Center A',
                  'classroomTitle': 'Room 1',
                  'slotLabel': 'M1',
                  'lesson': null,
                },
              ),
            );
          },
        ),
      );

      final context = await client.kioskApi.getDeviceMe();

      expect(context.centerName, 'Center A');
      expect(captured?.path, '/api/classroom/devices/me');
      expect(captured?.headers['Authorization'], 'Bearer device-jwt-token');
    });

    test('hasDeviceToken and clearDeviceToken delegate to storage', () async {
      final tokenStorage = MemoryDeviceTokenStorage();
      final api = KioskApiClient(deviceTokenStorage: tokenStorage).kioskApi;

      expect(await api.hasDeviceToken(), isFalse);

      await tokenStorage.writeToken('device-jwt-token');
      expect(await api.hasDeviceToken(), isTrue);

      await api.clearDeviceToken();
      expect(await api.hasDeviceToken(), isFalse);
    });

    test('throws on unauthorized response', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final client = KioskApiClient(
        deviceTokenStorage: MemoryDeviceTokenStorage(),
        dio: dio,
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'Unauthorized'},
                ),
              ),
            );
          },
        ),
      );

      expect(() => client.kioskApi.getDeviceMe(), throwsA(isA<KioskApiException>()));
    });
  });

  group('KioskApi.pollCommands', () {
    test('parses commands and sends since query', () async {
      RequestOptions? captured;
      final client = KioskApiClient(
        deviceTokenStorage: MemoryDeviceTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'since': 2,
                  'commandSeq': 3,
                  'commands': [
                    {'command': 'open_scan', 'seq': 3},
                  ],
                },
              ),
            );
          },
        ),
      );

      final response = await client.kioskApi.pollCommands(since: 2);

      expect(captured?.path, '/api/classroom/devices/me/commands');
      expect(captured?.queryParameters['since'], 2);
      expect(response.commandSeq, 3);
      expect(response.commands.first.command, KioskDeviceCommandKind.openScan);
    });
  });

  group('KioskApi.heartbeat', () {
    test('posts ackSeq when provided', () async {
      RequestOptions? captured;
      final client = KioskApiClient(
        deviceTokenStorage: MemoryDeviceTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'ok': true},
              ),
            );
          },
        ),
      );

      await client.kioskApi.heartbeat(ackSeq: 3);

      expect(captured?.path, '/api/classroom/devices/heartbeat');
      expect(captured?.method, 'POST');
      expect(captured?.data, {'ackSeq': 3});
    });

    test('posts without body when ackSeq omitted', () async {
      RequestOptions? captured;
      final client = KioskApiClient(
        deviceTokenStorage: MemoryDeviceTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'ok': true},
              ),
            );
          },
        ),
      );

      await client.kioskApi.heartbeat();

      expect(captured?.data, isNull);
    });
  });

  group('KioskApi.childLogout', () {
    test('posts child logout endpoint', () async {
      RequestOptions? captured;
      final client = KioskApiClient(
        deviceTokenStorage: MemoryDeviceTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'ok': true},
              ),
            );
          },
        ),
      );

      await client.kioskApi.childLogout();

      expect(captured?.path, '/api/classroom/devices/child-logout');
      expect(captured?.method, 'POST');
    });
  });

  group('KioskApi.scan', () {
    test('parses success payload and posts token body', () async {
      RequestOptions? captured;
      final client = KioskApiClient(
        deviceTokenStorage: MemoryDeviceTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'ok': true,
                  'outcome': 'play',
                  'programId': '77777777-7777-4777-8777-777777777777',
                  'childId': '88888888-8888-4888-8888-888888888888',
                  'childDisplayName': 'Anna',
                  'childSessionToken': 'child-jwt-token',
                },
              ),
            );
          },
        ),
      );

      final result = await client.kioskApi.scan(token: 'qr-token-value');

      expect(captured?.path, '/api/classroom/scan');
      expect(captured?.method, 'POST');
      expect(captured?.data, {'token': 'qr-token-value'});
      expect(result.outcome, KioskScanOutcome.play);
      expect(result.childDisplayName, 'Anna');
    });

    test('throws with server code on scan error', () async {
      final client = KioskApiClient(
        deviceTokenStorage: MemoryDeviceTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 403,
                  data: {
                    'status': 'error',
                    'code': 'revoked',
                    'message': 'QR отозван',
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(
        () => client.kioskApi.scan(token: 'bad-token'),
        throwsA(
          isA<KioskApiException>()
              .having((error) => error.code, 'code', 'revoked')
              .having((error) => error.message, 'message', 'QR отозван'),
        ),
      );
    });
  });
}
