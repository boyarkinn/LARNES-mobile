import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/invite/screens/lesson_invite_exit_screen.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'an exited guest only reads invitation status and must tap to return',
    (tester) async {
      var status = 'active';
      final calls = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add('${request.method} ${request.path}');
            handler.resolve(
              Response(requestOptions: request, data: {'status': status}),
            );
          },
        ),
      );
      const exit = '/invite/lesson/left?token=synthetic';
      final router = GoRouter(
        initialLocation: exit,
        routes: [
          GoRoute(
            path: '/invite/lesson/left',
            builder: (_, state) => LessonInviteExitScreen(
              token: state.uri.queryParameters['token']!,
            ),
          ),
          GoRoute(
            path: '/invite/lesson',
            builder: (_, _) => const Text('Invite entry'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        LocaleScope(
          localeController: LocaleController(),
          child: AuthScope(
            authSession: AuthSession(apiClient: ApiClient(dio: dio)),
            child: MaterialApp.router(
              routerConfig: router,
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Вы вышли с урока.'), findsOneWidget);
      expect(calls, ['GET /api/invite/lesson']);
      await tester.tap(find.text('Вернуться на урок'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/invite/lesson?token=synthetic',
      );
      router.go(exit);
      await tester.pumpAndSettle();
      status = 'expired';
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Урок уже закончился'), findsOneWidget);
      expect(find.text('Вернуться на урок'), findsNothing);
      expect(calls, everyElement('GET /api/invite/lesson'));
    },
  );
}
