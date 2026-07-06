import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_scope.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/kiosk/screens/kiosk_enroll_screen.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

import 'memory_device_token_storage.dart';

Dio _enrollDio() {
  const centerId = '11111111-1111-4111-8111-111111111111';
  const classroomId = '44444444-4444-4444-8444-444444444444';

  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.endsWith('/centers')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'centers': [
                  {
                    'id': centerId,
                    'name': 'Center A',
                    'ownerUserId': '22222222-2222-4222-8222-222222222222',
                    'createdAt': '2026-07-06T10:00:00.000Z',
                  },
                ],
              },
            ),
          );
          return;
        }

        if (options.path.endsWith('/classrooms')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'classrooms': [
                  {
                    'id': classroomId,
                    'centerId': centerId,
                    'centerName': 'Center A',
                    'title': 'Room 1',
                  },
                ],
              },
            ),
          );
          return;
        }

        if (options.path.endsWith('/enroll')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'deviceId': '55555555-5555-4555-8555-555555555555',
                'deviceToken': 'device-jwt-token',
              },
            ),
          );
          return;
        }

        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  Widget wrap({
    required AuthSession authSession,
    required KioskRouteState kioskRouteState,
    required Widget child,
  }) {
    return LocaleScope(
      localeController: LocaleController(),
      child: AuthScope(
        authSession: authSession,
        child: KioskScope(
          kioskRouteState: kioskRouteState,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ru'),
            home: child,
          ),
        ),
      ),
    );
  }

  group('KioskEnrollScreen', () {
    testWidgets('loads form fields from network api', (tester) async {
      final authSession = AuthSession(apiClient: ApiClient(dio: _enrollDio()));
      authSession.applyUser(
        const AuthUser(
          id: '22222222-2222-4222-8222-222222222222',
          accountType: 'network_owner',
        ),
      );

      await tester.pumpWidget(
        wrap(
          authSession: authSession,
          kioskRouteState: KioskRouteState(deviceTokenStorage: MemoryDeviceTokenStorage()),
          child: const KioskEnrollScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Center A'), findsWidgets);
      expect(find.text('Room 1'), findsOneWidget);
      expect(find.text('Привязать устройство'), findsOneWidget);
    });

    testWidgets('persists device token on submit', (tester) async {
      final authSession = AuthSession(apiClient: ApiClient(dio: _enrollDio()));
      authSession.applyUser(
        const AuthUser(
          id: '22222222-2222-4222-8222-222222222222',
          accountType: 'network_owner',
        ),
      );
      final tokenStorage = MemoryDeviceTokenStorage();
      final kioskRouteState = KioskRouteState(deviceTokenStorage: tokenStorage);

      await tester.pumpWidget(
        wrap(
          authSession: authSession,
          kioskRouteState: kioskRouteState,
          child: const KioskEnrollScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'M1');
      await tester.tap(find.text('Привязать устройство'));
      await tester.pumpAndSettle();

      expect(await tokenStorage.hasToken(), isTrue);
      expect(await tokenStorage.readToken(), 'device-jwt-token');
    });
  });
}
