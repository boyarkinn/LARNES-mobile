import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_scope.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/kiosk/screens/kiosk_settings_screen.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

import 'memory_child_session_token_storage.dart';
import 'memory_device_token_storage.dart';

const _deviceId = '55555555-5555-4555-8555-555555555555';

InterceptorsWrapper _deviceMeInterceptor() {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      if (options.path.endsWith('/devices/me') &&
          !options.path.contains('/commands')) {
        handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'deviceId': _deviceId,
              'kind': 'phone',
              'centerName': 'Center A',
              'classroomTitle': 'Room 1',
              'slotLabel': 'M1',
              'lesson': null,
            },
          ),
        );
        return;
      }
      handler.next(options);
    },
  );
}

InterceptorsWrapper _unbindInterceptor({
  void Function(RequestOptions options)? onUnbind,
}) {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      if (options.path.endsWith('/devices/unbind')) {
        onUnbind?.call(options);
        handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'status': 'success',
              'ok': true,
            },
          ),
        );
        return;
      }
      handler.next(options);
    },
  );
}

void main() {
  Widget wrap({
    required AuthSession authSession,
    required KioskRouteState kioskRouteState,
    required GoRouter router,
  }) {
    return LocaleScope(
      localeController: LocaleController(),
      child: AuthScope(
        authSession: authSession,
        child: KioskScope(
          kioskRouteState: kioskRouteState,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ru'),
            routerConfig: router,
          ),
        ),
      ),
    );
  }

  group('KioskSettingsScreen', () {
    testWidgets('shows placement and device id', (tester) async {
      final networkDio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final authSession = AuthSession(apiClient: ApiClient(dio: networkDio));
      authSession.applyUser(
        const AuthUser(
          id: '22222222-2222-4222-8222-222222222222',
          accountType: 'network_owner',
        ),
      );

      final tokenStorage = MemoryDeviceTokenStorage();
      final kioskRouteState = KioskRouteState(deviceTokenStorage: tokenStorage);
      kioskRouteState.kioskApiClient.dio.interceptors.add(_deviceMeInterceptor());

      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final router = GoRouter(
        initialLocation: '/kiosk/settings',
        routes: [
          GoRoute(
            path: '/kiosk/settings',
            builder: (context, state) => const KioskSettingsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(
          authSession: authSession,
          kioskRouteState: kioskRouteState,
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Настройки устройства'), findsOneWidget);
      expect(find.textContaining('Center A'), findsOneWidget);
      expect(find.textContaining('Слот M1'), findsOneWidget);
      expect(find.text(_deviceId), findsOneWidget);
      expect(find.text('Отвязать и выйти из kiosk'), findsOneWidget);
    });

    testWidgets('unbind clears tokens and navigates to enroll', (tester) async {
      RequestOptions? unbindRequest;

      final networkDio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      networkDio.interceptors.add(
        _unbindInterceptor(onUnbind: (options) => unbindRequest = options),
      );

      final authSession = AuthSession(apiClient: ApiClient(dio: networkDio));
      authSession.applyUser(
        const AuthUser(
          id: '22222222-2222-4222-8222-222222222222',
          accountType: 'network_owner',
        ),
      );

      final tokenStorage = MemoryDeviceTokenStorage();
      final childStorage = MemoryChildSessionTokenStorage();
      await childStorage.writeToken('child-jwt-token');

      final kioskRouteState = KioskRouteState(deviceTokenStorage: tokenStorage);
      kioskRouteState.kioskApiClient.dio.interceptors.add(_deviceMeInterceptor());

      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final router = GoRouter(
        initialLocation: '/kiosk/settings',
        routes: [
          GoRoute(
            path: '/kiosk/enroll',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Enroll placeholder')),
            ),
          ),
          GoRoute(
            path: '/kiosk/settings',
            builder: (context, state) => KioskSettingsScreen(
              childSessionTokenStorage: childStorage,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(
          authSession: authSession,
          kioskRouteState: kioskRouteState,
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отвязать и выйти из kiosk'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отвязать'));
      await tester.pumpAndSettle();

      expect(unbindRequest?.path, '/api/mobile/network/devices/unbind');
      expect(unbindRequest?.data, {
        'deviceId': _deviceId,
        'locale': 'ru',
      });
      expect(await tokenStorage.hasToken(), isFalse);
      expect(await childStorage.hasToken(), isFalse);
      expect(find.text('Enroll placeholder'), findsOneWidget);
    });

    testWidgets('shows login prompt when user session missing', (tester) async {
      final networkDio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final authSession = AuthSession(apiClient: ApiClient(dio: networkDio));

      final tokenStorage = MemoryDeviceTokenStorage();
      final kioskRouteState = KioskRouteState(deviceTokenStorage: tokenStorage);
      kioskRouteState.kioskApiClient.dio.interceptors.add(_deviceMeInterceptor());

      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final router = GoRouter(
        initialLocation: '/kiosk/settings',
        routes: [
          GoRoute(
            path: '/kiosk/settings',
            builder: (context, state) => const KioskSettingsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(
          authSession: authSession,
          kioskRouteState: kioskRouteState,
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Войдите снова, чтобы отвязать устройство.'),
        findsOneWidget,
      );
      expect(find.text('Отвязать и выйти из kiosk'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
