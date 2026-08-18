import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/api/child_session_api_client.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_scope.dart';
import 'package:larnes_mobile/features/kiosk/screens/kiosk_settings_screen.dart';
import 'package:larnes_mobile/features/kiosk/screens/kiosk_shell.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_child_bound_view.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_shell.dart';

import 'memory_child_session_token_storage.dart';
import 'memory_device_token_storage.dart';

const _programId = '77777777-7777-4777-8777-777777777777';

ChildSessionApiClient createMockChildSessionApiClient({
  required MemoryChildSessionTokenStorage storage,
  String programTitle = 'Program A',
}) {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.contains('/play-snapshot')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'snapshot': {
                  'childId': '88888888-8888-4888-8888-888888888888',
                  'programId': _programId,
                  'title': programTitle,
                  'status': 'in_progress',
                  'topicOrdinal': 1,
                  'lessonOrdinal': 1,
                  'steps': [
                    {
                      'id': 'step-1',
                      'trainerKey': 'number-row-show',
                      'params': {'digit': 5},
                      'topicOrdinal': 1,
                      'lessonOrdinal': 1,
                      'isLastInLesson': true,
                      'isLastInProgram': false,
                    },
                  ],
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
            response: Response(
              requestOptions: options,
              statusCode: 404,
            ),
          ),
        );
      },
    ),
  );

  return ChildSessionApiClient(
    childSessionTokenStorage: storage,
    dio: dio,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  KioskRouteState kioskRouteStateWithMock({
    Map<String, dynamic>? deviceMeData,
    Map<String, dynamic>? scanData,
    Map<String, dynamic> Function()? deviceMeProvider,
  }) {
    final tokenStorage = MemoryDeviceTokenStorage();
    final kioskRouteState = KioskRouteState(deviceTokenStorage: tokenStorage);

    kioskRouteState.kioskApiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.endsWith('/devices/me') &&
              !options.path.contains('/commands')) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: deviceMeProvider?.call() ??
                    deviceMeData ??
                    {
                      'deviceId': '55555555-5555-4555-8555-555555555555',
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

          if (options.path.contains('/commands')) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'since': 0,
                  'commandSeq': 0,
                  'commands': <Map<String, dynamic>>[],
                },
              ),
            );
            return;
          }

          if (options.path.endsWith('/heartbeat') ||
              options.path.endsWith('/child-logout')) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'ok': true},
              ),
            );
            return;
          }

          if (options.path.endsWith('/scan')) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: scanData ??
                    {
                      'ok': true,
                      'outcome': 'play',
                      'programId': _programId,
                      'childId': '88888888-8888-4888-8888-888888888888',
                      'childDisplayName': 'Анна Петрова',
                      'childSessionToken': 'child-jwt-token',
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
              ),
            ),
          );
        },
      ),
    );

    return kioskRouteState;
  }

  Widget wrap({
    required KioskRouteState kioskRouteState,
    required GoRouter router,
    AuthSession? authSession,
  }) {
    return AuthScope(
      authSession: authSession ?? AuthSession(),
      child: KioskScope(
        kioskRouteState: kioskRouteState,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          routerConfig: router,
        ),
      ),
    );
  }

  group('KioskShell', () {
    testWidgets('shows registration screen without device token', (tester) async {
      final kioskRouteState = KioskRouteState();

      final router = GoRouter(
        initialLocation: '/kiosk',
        routes: [
          GoRoute(
            path: '/kiosk',
            builder: (context, state) => const KioskShell(
              syncInterval: Duration(days: 1),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(kioskRouteState: kioskRouteState, router: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Устройство не зарегистрировано'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
      expect(find.text('В панели сети → Устройства выдайте одноразовый доступ.'), findsOneWidget);
    });

    testWidgets('shows unplaced screen without scan UI', (tester) async {
      final kioskRouteState = kioskRouteStateWithMock(
        deviceMeData: {
          'deviceId': '55555555-5555-4555-8555-555555555555',
          'kind': 'phone',
          'centerName': null,
          'classroomId': null,
          'classroomTitle': null,
          'slotLabel': null,
          'lesson': null,
        },
      );
      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final router = GoRouter(
        initialLocation: '/kiosk',
        routes: [
          GoRoute(
            path: '/kiosk',
            builder: (context, state) => const KioskShell(
              syncInterval: Duration(days: 1),
              placementPollInterval: Duration(days: 1),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(kioskRouteState: kioskRouteState, router: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Место не назначено'), findsOneWidget);
      expect(find.text('Занятие не начато'), findsNothing);
      expect(find.text('Поднесите QR'), findsNothing);
      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Ожидаем назначения'), findsOneWidget);
      expect(find.text('Откройте панель сети → Устройства.'), findsOneWidget);
    });

    testWidgets('transitions to idle after seat assignment', (tester) async {
      var placed = false;

      final kioskRouteState = kioskRouteStateWithMock(
        deviceMeProvider: () {
          if (placed) {
            return {
              'deviceId': '55555555-5555-4555-8555-555555555555',
              'kind': 'phone',
              'centerName': 'Center A',
              'classroomId': '44444444-4444-4444-8444-444444444444',
              'classroomTitle': 'Room 1',
              'slotLabel': 'M1',
              'lesson': null,
            };
          }
          return {
            'deviceId': '55555555-5555-4555-8555-555555555555',
            'kind': 'phone',
            'classroomId': null,
            'slotLabel': null,
            'lesson': null,
          };
        },
      );
      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final router = GoRouter(
        initialLocation: '/kiosk',
        routes: [
          GoRoute(
            path: '/kiosk',
            builder: (context, state) => KioskShell(
              syncInterval: Duration(days: 1),
              placementPollInterval: const Duration(milliseconds: 100),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(kioskRouteState: kioskRouteState, router: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Место не назначено'), findsOneWidget);

      placed = true;
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Место не назначено'), findsNothing);
      expect(find.text('Занятие не начато'), findsOneWidget);
    });

    testWidgets('shows idle placement after load', (tester) async {
      final kioskRouteState = kioskRouteStateWithMock();
      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final router = GoRouter(
        initialLocation: '/kiosk',
        routes: [
          GoRoute(
            path: '/kiosk',
            builder: (context, state) => const KioskShell(
              syncInterval: Duration(days: 1),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(kioskRouteState: kioskRouteState, router: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Занятие не начато'), findsOneWidget);
      expect(find.textContaining('Center A'), findsOneWidget);
      expect(find.textContaining('Слот M1'), findsOneWidget);
      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Ожидаем начала занятия'), findsOneWidget);
    });

    testWidgets('settings button opens settings route', (tester) async {
      final kioskRouteState = kioskRouteStateWithMock();
      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final authSession = AuthSession();
      authSession.applyUser(
        const AuthUser(
          id: '22222222-2222-4222-8222-222222222222',
          accountType: 'network_owner',
        ),
      );

      final router = GoRouter(
        initialLocation: '/kiosk',
        routes: [
          GoRoute(
            path: '/kiosk',
            builder: (context, state) => const KioskShell(
              syncInterval: Duration(days: 1),
            ),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) => const KioskSettingsScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(
          kioskRouteState: kioskRouteState,
          router: router,
          authSession: authSession,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();

      expect(find.text('Настройки устройства'), findsOneWidget);
    });

    testWidgets('shows scan copy when lesson awaits scan', (tester) async {
      final kioskRouteState = kioskRouteStateWithMock(
        deviceMeData: {
          'deviceId': '55555555-5555-4555-8555-555555555555',
          'kind': 'phone',
          'centerName': 'Center A',
          'classroomId': '44444444-4444-4444-8444-444444444444',
          'classroomTitle': 'Room 1',
          'slotLabel': 'M1',
          'lesson': {
            'commandSeq': 2,
            'lessonSessionId': '66666666-6666-4666-8666-666666666666',
            'pendingCommand': 'open_scan',
            'status': 'waiting_scan',
          },
        },
      );
      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final router = GoRouter(
        initialLocation: '/kiosk',
        routes: [
          GoRoute(
            path: '/kiosk',
            builder: (context, state) => const KioskShell(
              syncInterval: Duration(days: 1),
              mockScanner: true,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(kioskRouteState: kioskRouteState, router: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Поднесите QR'), findsNothing);
      expect(find.textContaining('Center A'), findsOneWidget);
      expect(find.text('Включить камеру'), findsOneWidget);
    });

    testWidgets('opens program player after mock scan success', (tester) async {
      final childStorage = MemoryChildSessionTokenStorage();
      final childClient = createMockChildSessionApiClient(storage: childStorage);
      final kioskRouteState = kioskRouteStateWithMock(
        deviceMeData: {
          'deviceId': '55555555-5555-4555-8555-555555555555',
          'kind': 'phone',
          'centerName': 'Center A',
          'classroomId': '44444444-4444-4444-8444-444444444444',
          'classroomTitle': 'Room 1',
          'slotLabel': 'M1',
          'lesson': {
            'commandSeq': 2,
            'lessonSessionId': '66666666-6666-4666-8666-666666666666',
            'pendingCommand': 'open_scan',
            'status': 'waiting_scan',
          },
        },
      );
      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final router = GoRouter(
        initialLocation: '/kiosk',
        routes: [
          GoRoute(
            path: '/kiosk',
            builder: (context, state) => KioskShell(
              syncInterval: Duration(days: 1),
              mockScanner: true,
              childSessionTokenStorage: childStorage,
              childSessionApiClient: childClient,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(kioskRouteState: kioskRouteState, router: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Включить камеру'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(TrainerPlayShell), findsOneWidget);
      expect(find.text('Программа назначена'), findsNothing);
      expect(find.text('Настройки'), findsNothing);
    });

    testWidgets('shows result after no_program scan', (tester) async {
      final childStorage = MemoryChildSessionTokenStorage();
      final childClient = createMockChildSessionApiClient(storage: childStorage);
      final kioskRouteState = kioskRouteStateWithMock(
        deviceMeData: {
          'deviceId': '55555555-5555-4555-8555-555555555555',
          'kind': 'phone',
          'centerName': 'Center A',
          'classroomId': '44444444-4444-4444-8444-444444444444',
          'classroomTitle': 'Room 1',
          'slotLabel': 'M1',
          'lesson': {
            'commandSeq': 2,
            'lessonSessionId': '66666666-6666-4666-8666-666666666666',
            'pendingCommand': 'open_scan',
            'status': 'waiting_scan',
          },
        },
        scanData: {
          'ok': true,
          'outcome': 'no_program',
          'childId': '88888888-8888-4888-8888-888888888888',
          'childDisplayName': 'Петрова Анна Сергеевна',
          'childCardColor': 'violet',
          'childGender': 'female',
          'childGivenName': 'Анна Сергеевна',
          'childLastName': 'Петрова',
          'childSessionToken': 'child-jwt-token',
        },
      );
      await kioskRouteState.persistDeviceToken('device-jwt-token');

      final router = GoRouter(
        initialLocation: '/kiosk',
        routes: [
          GoRoute(
            path: '/kiosk',
            builder: (context, state) => KioskShell(
              syncInterval: Duration(days: 1),
              mockScanner: true,
              childSessionTokenStorage: childStorage,
              childSessionApiClient: childClient,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(kioskRouteState: kioskRouteState, router: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Включить камеру'));
      await tester.pumpAndSettle();

      expect(find.byType(KioskChildBoundView), findsOneWidget);
      expect(find.text('Петрова'), findsOneWidget);
      expect(find.text('Анна Сергеевна'), findsOneWidget);
      expect(find.text('Ребёнок на занятии'), findsNothing);
      expect(find.text('Пока нет программы для этого ребёнка.'), findsNothing);
    });
  });
}
