import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/auth/token_storage.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/screens/login_screen.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class MemoryTokenStorage extends TokenStorage {
  String? token;
  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> writeToken(String token) async => this.token = token;
  @override
  Future<void> clearToken() async => token = null;
}

const profile = {'id': 'synthetic-user', 'accountType': 'teacher'};

void main() {
  test(
    'API sends opt-in, restores token after restart and clears it on logout',
    () async {
      final storage = MemoryTokenStorage();
      final choices = <Object?>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final client = ApiClient(dio: dio, tokenStorage: storage);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/login')) {
              choices.add((options.data as Map)['rememberMe']);
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'token': 'synthetic-jwt',
                    'accountType': 'teacher',
                    'homePath': '/teacher',
                    'user': profile,
                  },
                ),
              );
            } else {
              expect(options.headers['Authorization'], 'Bearer synthetic-jwt');
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'status': 'success', 'user': profile},
                ),
              );
            }
          },
        ),
      );
      await AuthApi(
        client,
      ).login(login: 'example', password: 'synthetic', rememberMe: true);
      expect(choices.single, true);
      expect(storage.token, 'synthetic-jwt');
      final reopened = AuthSession(apiClient: client);
      await reopened.bootstrap();
      expect(reopened.isAuthenticated, true);
      await reopened.authApi.logout();
      expect(storage.token, isNull);
      await AuthApi(client).login(login: 'example', password: 'synthetic');
      expect(choices.last, false);
      reopened.dispose();
    },
  );

  for (final locale in ['ru', 'en']) {
    testWidgets(
      'login $locale: checkbox, shared autofill, successful save and no overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final storage = MemoryTokenStorage();
        Object? sentChoice;
        var allowLogin = false;
        final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              sentChoice = (options.data as Map)['rememberMe'];
              if (!allowLogin) {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 401,
                    data: {
                      'status': 'error',
                      'message': 'Synthetic invalid password',
                    },
                  ),
                );
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'token': 'synthetic-jwt',
                    'accountType': 'teacher',
                    'homePath': '/teacher',
                    'user': profile,
                  },
                ),
              );
            },
          ),
        );
        final auth = AuthSession(
          apiClient: ApiClient(dio: dio, tokenStorage: storage),
        );
        final router = GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
              path: '/login',
              builder: (_, _) => LoginScreen(authSession: auth),
            ),
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: Text('Signed in')),
            ),
          ],
        );
        final locales = LocaleController();
        await tester.pumpWidget(
          LocaleScope(
            localeController: locales,
            child: MaterialApp.router(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fields = tester
            .widgetList<TextField>(find.byType(TextField))
            .toList();
        expect(fields[0].autofillHints, [AutofillHints.username]);
        expect(fields[1].autofillHints, [AutofillHints.password]);
        expect(find.byType(AutofillGroup), findsOneWidget);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, false);
        final rememberLabel = locale == 'ru' ? 'Запомнить меня' : 'Remember me';
        final forgotLabel = locale == 'ru'
            ? 'Забыли пароль?'
            : 'Forgot password?';
        final rememberRect = tester.getRect(find.text(rememberLabel));
        final forgotRect = tester.getRect(find.text(forgotLabel));
        // The test font is wider than Inter; allow an accessible second row.
        if ((rememberRect.center.dy - forgotRect.center.dy).abs() < 2) {
          expect(rememberRect.left, greaterThan(forgotRect.right));
        } else {
          expect(rememberRect.top, greaterThan(forgotRect.bottom));
        }
        final rememberStyle = tester
            .widget<Text>(find.text(rememberLabel))
            .style!;
        final forgotStyle = tester.widget<Text>(find.text(forgotLabel)).style!;
        expect(rememberStyle.fontFamily, forgotStyle.fontFamily);
        expect(rememberStyle.fontWeight, forgotStyle.fontWeight);
        expect(rememberStyle.fontSize, forgotStyle.fontSize);
        expect(rememberStyle.color, forgotStyle.color);
        expect(tester.getSize(find.byType(Checkbox)), const Size(18, 18));
        final tapArea = find
            .ancestor(of: find.byType(Checkbox), matching: find.byType(InkWell))
            .first;
        expect(tester.getSize(tapArea).height, greaterThanOrEqualTo(44));
        await tester.tap(find.text(rememberLabel));
        await tester.pump();
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, true);
        await tester.enterText(find.byType(TextField).first, 'example');
        await tester.enterText(find.byType(TextField).last, 'synthetic');
        tester.testTextInput.log.clear();
        await tester.ensureVisible(find.byType(AuthPrimaryButton));
        await tester.tap(find.byType(AuthPrimaryButton));
        await tester.pumpAndSettle();
        expect(sentChoice, true);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, true);
        expect(storage.token, isNull);
        expect(
          tester.testTextInput.log.any(
            (call) =>
                call.method == 'TextInput.finishAutofillContext' &&
                call.arguments == true,
          ),
          false,
        );
        allowLogin = true;
        await tester.ensureVisible(find.byType(AuthPrimaryButton));
        await tester.tap(find.byType(AuthPrimaryButton));
        await tester.pumpAndSettle();
        expect(find.text('Signed in'), findsOneWidget);
        expect(
          tester.testTextInput.log.any(
            (call) =>
                call.method == 'TextInput.finishAutofillContext' &&
                call.arguments == true,
          ),
          true,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        auth.dispose();
        locales.dispose();
      },
    );
  }
}
