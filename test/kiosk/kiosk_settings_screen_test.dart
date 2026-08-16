import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
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
              'classroomId': '44444444-4444-4444-8444-444444444444',
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

InterceptorsWrapper _kioskExitInterceptor({
  void Function(RequestOptions options)? onExit,
}) {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      if (options.path.endsWith('/kiosk/exit')) {
        onExit?.call(options);
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
      if (options.path.endsWith('/child-logout')) {
        handler.resolve(
          Response(
            requestOptions: options,
            data: {'ok': true},
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
      final authSession = AuthSession();
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
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('exit clears tokens and navigates to enroll without user session',
        (tester) async {
      RequestOptions? exitRequest;

      final authSession = AuthSession();
      final tokenStorage = MemoryDeviceTokenStorage();
      final childStorage = MemoryChildSessionTokenStorage();
      await childStorage.writeToken('child-jwt-token');

      final kioskRouteState = KioskRouteState(deviceTokenStorage: tokenStorage);
      kioskRouteState.kioskApiClient.dio.interceptors.add(_deviceMeInterceptor());
      kioskRouteState.kioskApiClient.dio.interceptors.add(
        _kioskExitInterceptor(onExit: (options) => exitRequest = options),
      );

      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final router = GoRouter(
        initialLocation: '/kiosk/settings',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Login placeholder')),
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

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Выйти').last);
      await tester.pumpAndSettle();

      expect(exitRequest?.path, '/api/mobile/kiosk/exit');
      expect(exitRequest?.data, {'locale': 'ru'});
      expect(await tokenStorage.hasToken(), isFalse);
      expect(await childStorage.hasToken(), isFalse);
      expect(find.text('Login placeholder'), findsOneWidget);
    });
  });
}
