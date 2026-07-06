import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/network/screens/network_centers_screen.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

Dio _networkDio({required bool fail}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (fail) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          );
          return;
        }

        if (options.path.endsWith('/centers')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
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
          );
          return;
        }

        if (options.path.endsWith('/devices')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'devices': [
                  {
                    'id': '33333333-3333-4333-8333-333333333333',
                    'kind': 'tablet',
                    'isOnline': true,
                    'slotLabel': 'M1',
                    'centerName': 'Center A',
                    'classroomTitle': 'Room 1',
                  },
                ],
              },
            ),
          );
          return;
        }

        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 404,
              data: {'message': 'Not found'},
            ),
          ),
        );
      },
    ),
  );
  return dio;
}

Widget _wrap({
  required AuthSession authSession,
  required Widget child,
}) {
  return LocaleScope(
    localeController: LocaleController(),
    child: AuthScope(
      authSession: authSession,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: child,
      ),
    ),
  );
}

void main() {
  group('NetworkCentersScreen', () {
    testWidgets('shows centers and devices after load', (tester) async {
      final authSession = AuthSession(
        apiClient: ApiClient(dio: _networkDio(fail: false)),
      );

      await tester.binding.setSurfaceSize(const Size(360, 640));

      await tester.pumpWidget(
        _wrap(
          authSession: authSession,
          child: const NetworkCentersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Center A'), findsOneWidget);
      expect(find.text('Moscow'), findsOneWidget);
      expect(find.text('Слот M1'), findsOneWidget);
      expect(find.text('Center A · Room 1'), findsOneWidget);
      expect(find.text('Онлайн'), findsOneWidget);
      expect(find.text('Добавить устройство'), findsOneWidget);

      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('shows error and retry when load fails', (tester) async {
      final authSession = AuthSession(
        apiClient: ApiClient(dio: _networkDio(fail: true)),
      );

      await tester.pumpWidget(
        _wrap(
          authSession: authSession,
          child: const NetworkCentersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Нет связи с сервером. Проверьте интернет.'), findsOneWidget);
      expect(find.text('Продолжить'), findsOneWidget);
    });
  });
}
