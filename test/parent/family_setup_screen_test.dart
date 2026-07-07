import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/screens/family_setup_screen.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

Dio _familySetupDio({required String status}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.endsWith('/family-setup') && options.method == 'GET') {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'familySetup': {
                  'isComplete': false,
                  'status': status,
                  'pendingJoinToken': status == 'pending_join' ? 'token-1' : null,
                  'pendingJoinUrl': status == 'pending_join' ? 'https://example.com/join' : null,
                },
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

Widget _wrap({
  required AuthSession authSession,
  required Widget child,
}) {
  return LocaleScope(
    localeController: LocaleController(),
    child: AuthScope(
      authSession: authSession,
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
}

void main() {
  testWidgets('family setup gate shows waiting state', (tester) async {
    final authSession = AuthSession(
      apiClient: ApiClient(dio: _familySetupDio(status: 'pending_join')),
    );

    await tester.pumpWidget(
      _wrap(
        authSession: authSession,
        child: const FamilySetupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ждём подтверждения'), findsOneWidget);
    expect(find.text('https://example.com/join'), findsOneWidget);
    expect(find.text('Я ошибся — создать свою семью'), findsOneWidget);
  });

  testWidgets('family setup gate shows solo/join choices', (tester) async {
    final authSession = AuthSession(
      apiClient: ApiClient(dio: _familySetupDio(status: 'unset')),
    );

    await tester.pumpWidget(
      _wrap(
        authSession: authSession,
        child: const FamilySetupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Нет, создать свою семью'), findsOneWidget);
    expect(find.text('Да, семья уже есть'), findsOneWidget);
  });
}
