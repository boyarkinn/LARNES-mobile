import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/api/family_setup_api.dart';
import 'package:larnes_mobile/core/api/lesson_invite_guest_api.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/invite/screens/lesson_invite_guest_room_screen.dart';
import 'package:larnes_mobile/features/parent/screens/child_picker_screen.dart';
import 'package:larnes_mobile/features/parent/screens/live_lesson_room_screen.dart';
import 'package:larnes_mobile/features/parent/widgets/child_profile_card.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Presence must work even if no media endpoint connects.
class _OfflineWebView extends PlatformInAppWebViewWidget {
  _OfflineWebView(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox();
  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      params.controllerFromPlatform!(controller) as T;
  @override
  void dispose() {}
}

class _OfflineWebPlatform extends InAppWebViewPlatform {
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => _OfflineWebView(params);
}

void main() {
  for (final known in [true, false]) {
    testWidgets(
      'early family exit with ${known ? "known" : "pending"} session',
      (tester) async {
        final opening = Completer<void>();
        final firstReads = <RequestOptions>[];
        final leaves = <RequestOptions>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) async {
              if (request.path.endsWith('/leave')) {
                leaves.add(request);
              } else {
                firstReads.add(request);
                await opening.future;
              }
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {'status': 'ok', 'sessionId': 'session'},
                ),
              );
            },
          ),
        );
        final router = GoRouter(
          initialLocation: '/room',
          routes: [
            GoRoute(
              path: '/room',
              builder: (_, _) => LiveLessonRoomScreen(
                childId: 'child',
                sessionId: known ? 'session' : null,
              ),
            ),
            GoRoute(path: '/parent', builder: (_, _) => const Text('Exit')),
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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        expect(
          firstReads.single.queryParameters['sessionId'],
          known ? 'session' : null,
        );
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(router.routeInformationProvider.value.uri.path, '/parent');
        expect(leaves.length, known ? 1 : 0);
        opening.complete();
        await tester.pump(const Duration(milliseconds: 30));
        await tester.pump(const Duration(milliseconds: 30));
        expect(leaves.single.data['sessionId'], 'session');
        expect(
          leaves.single.headers[lessonConnectionHeader],
          firstReads.single.headers[lessonConnectionHeader],
        );
        expect(router.routeInformationProvider.value.uri.path, '/parent');
      },
    );
  }
  for (final guest in [false, true]) {
    testWidgets('${guest ? "guest" : "family"} exit, late poll and return', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({
        'larnes_lesson_guest_key': 'key',
      });
      SharedPreferences.setMockInitialValues({});
      InAppWebViewPlatform.instance = _OfflineWebPlatform();
      final roomPath = guest
          ? '/api/invite/lesson/guest'
          : '/api/mobile/parent/children/child/live-lesson';
      final exitPath = guest ? '/invite/lesson/left' : '/parent';
      final requests = <RequestOptions>[];
      final delayedPoll = Completer<void>();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            var body = <String, dynamic>{'status': 'ok'};
            if (request.path == roomPath) {
              requests.add(request);
              if (request.queryParameters['poll'] == '1') {
                await delayedPoll.future;
                body = {'status': 'left'};
              } else {
                body = {
                  'status': 'ok',
                  'sessionId': 'session',
                  'childId': 'child',
                };
              }
            } else if (request.path == '$roomPath/leave') {
              requests.add(request);
            }
            handler.resolve(Response(requestOptions: request, data: body));
          },
        ),
      );
      final auth = AuthSession(apiClient: ApiClient(dio: dio));
      if (guest) {
        final probeResponse = auth.lessonInviteGuestApi.fetchRoom(
          token: 'invite',
          connectionId: null,
        );
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 10));
        await probeResponse;
        final probe = requests.single;
        expect(probe.headers[lessonGuestKeyHeader], 'key');
        expect(probe.headers[lessonConnectionHeader], isNull);
        expect(probe.queryParameters['observeOnly'], '1');
        requests.clear();
      }
      final router = GoRouter(
        initialLocation: '/room',
        routes: [
          GoRoute(
            path: '/room',
            builder: (_, _) => guest
                ? const LessonInviteGuestRoomScreen(token: 'invite')
                : const LiveLessonRoomScreen(childId: 'child'),
          ),
          GoRoute(path: exitPath, builder: (_, _) => const Text('Exit')),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        LocaleScope(
          localeController: LocaleController(),
          child: AuthScope(
            authSession: auth,
            child: MaterialApp.router(
              routerConfig: router,
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      final id = requests.single.headers[lessonConnectionHeader] as String;
      expect(
        id,
        matches(RegExp(r'^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$')),
      );
      expect(requests.single.queryParameters['observeOnly'], isNull);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 20));
      expect(requests.last.queryParameters['poll'], '1');
      expect(requests.last.headers[lessonConnectionHeader], id);
      if (!guest) expect(requests.last.queryParameters['sessionId'], 'session');
      if (guest) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byIcon(Icons.call_end));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(requests.last.path, '$roomPath/leave');
      expect(requests.last.headers[lessonConnectionHeader], id);
      expect(requests.last.data['sessionId'], 'session');
      if (guest) expect(requests.last.headers[lessonGuestKeyHeader], 'key');
      expect(router.routeInformationProvider.value.uri.path, exitPath);
      router.go('/room');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final newId = requests.last.headers[lessonConnectionHeader];
      expect(newId, isNot(id));
      delayedPoll.complete();
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/room');
      expect(requests.length, 4);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
  testWidgets('picker keeps fresh presence after returning from a lesson', (
    tester,
  ) async {
    var childReads = 0;
    final late = Completer<void>();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) async {
          final body = <String, dynamic>{'status': 'success'};
          if (request.path == '/api/mobile/parent/children') {
            final read = ++childReads;
            if (read == 2) await late.future;
            body['children'] = [
              {
                'id': 'child',
                'firstName': 'Ученик',
                'liveLesson': {
                  'presence': read <= 2 ? 'online' : 'none',
                  'sessionId': 'session',
                },
              },
            ];
          }
          handler.resolve(Response(requestOptions: request, data: body));
        },
      ),
    );
    final auth = AuthSession(apiClient: ApiClient(dio: dio))
      ..applyUser(const AuthUser(id: 'family', accountType: 'parent'))
      ..applyFamilySetup(
        const FamilySetupSnapshot(isComplete: true, status: 'complete'),
      );
    final router = GoRouter(
      initialLocation: '/parent',
      routes: [
        GoRoute(
          path: '/parent',
          builder: (_, _) => const Scaffold(body: ChildPickerScreen()),
        ),
        GoRoute(
          path: '/parent/child/lesson',
          builder: (_, state) =>
              Text('Урок ${state.uri.queryParameters['sessionId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      LocaleScope(
        localeController: LocaleController(),
        child: AuthScope(
          authSession: auth,
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
    final card = find.byType(ChildProfileCard);
    expect(tester.widget<ChildProfileCard>(card).liveLabel, 'На уроке');
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('Урок session'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(childReads, 2);
    router.pop();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<ChildProfileCard>(card).liveLabel, 'Зайдите в урок');
    late.complete();
    await tester.pump(const Duration(milliseconds: 30));
    expect(tester.widget<ChildProfileCard>(card).liveLabel, 'Зайдите в урок');
    await tester.pumpWidget(const SizedBox());
  });
}
