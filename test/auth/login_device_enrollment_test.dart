import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';

void main() {
  group('AuthApi.login device enrollment', () {
    test('parses device_enrollment success without writing user token', () async {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.com',
          validateStatus: (_) => true,
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/login')) {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'kind': 'device_enrollment',
                    'deviceToken': 'device-jwt',
                    'deviceId': 'dev-1',
                    'deviceKind': 'tablet',
                    'expiresAt': '2026-12-31T00:00:00.000Z',
                  },
                ),
              );
              return;
            }
            handler.next(options);
          },
        ),
      );

      final client = ApiClient(dio: dio);
      final api = AuthApi(client);

      final outcome = await api.login(
        login: 'dev-test-code',
        password: 'secret',
      );

      expect(outcome, isA<DeviceEnrollmentLoginOutcome>());
      final enrollment = outcome as DeviceEnrollmentLoginOutcome;
      expect(enrollment.deviceToken, 'device-jwt');
      expect(enrollment.deviceId, 'dev-1');
      expect(enrollment.deviceKind, 'tablet');
      expect(await client.tokenStorage.readToken(), isNull);
    });
  });
}
