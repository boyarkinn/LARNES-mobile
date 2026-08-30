import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/screens/study_hub_screen.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

Dio studyHubDio({
  required bool trainersAvailable,
  bool coursesAvailable = false,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;

        if (path.endsWith('/larnes-courses/available')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'hasPublishedCourses': coursesAvailable,
              },
            ),
          );
          return;
        }

        if (path.endsWith('/trainers/available')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'available': trainersAvailable,
              },
            ),
          );
          return;
        }

        if (path.endsWith('/children/child-1') && !path.contains('/rewards')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'child': {
                  'id': 'child-1',
                  'firstName': 'Аня',
                  'lastName': 'Иванова',
                  'cardColor': 'sky',
                },
                'homeworkCount': 0,
                'education': {'tutors': [], 'networks': []},
              },
            ),
          );
          return;
        }

        if (path.endsWith('/children/child-1/rewards')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'visible': false,
                'shops': [],
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

Widget wrapStudyHub({
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
  group('StudyHubScreen trainers hub card', () {
    testWidgets('shows trainers card when published trainers are available', (tester) async {
      final authSession = AuthSession(
        apiClient: ApiClient(dio: studyHubDio(trainersAvailable: true)),
      );

      await tester.pumpWidget(
        wrapStudyHub(
          authSession: authSession,
          child: const StudyHubScreen(childId: 'child-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Тренажёры'), findsOneWidget);
      expect(find.text('Домашние задания'), findsOneWidget);
    });

    testWidgets('hides trainers card when none are published', (tester) async {
      final authSession = AuthSession(
        apiClient: ApiClient(dio: studyHubDio(trainersAvailable: false)),
      );

      await tester.pumpWidget(
        wrapStudyHub(
          authSession: authSession,
          child: const StudyHubScreen(childId: 'child-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Тренажёры'), findsNothing);
      expect(find.text('Домашние задания'), findsOneWidget);
    });

    testWidgets('places trainers card after homework and before courses', (tester) async {
      final authSession = AuthSession(
        apiClient: ApiClient(
          dio: studyHubDio(
            trainersAvailable: true,
            coursesAvailable: true,
          ),
        ),
      );

      await tester.pumpWidget(
        wrapStudyHub(
          authSession: authSession,
          child: const StudyHubScreen(childId: 'child-1'),
        ),
      );
      await tester.pumpAndSettle();

      final homeworkOffset = tester.getTopLeft(find.text('Домашние задания')).dy;
      final trainersOffset = tester.getTopLeft(find.text('Тренажёры')).dy;
      final coursesOffset = tester.getTopLeft(find.text('Курсы LARNES')).dy;

      expect(trainersOffset, greaterThan(homeworkOffset));
      expect(coursesOffset, greaterThan(trainersOffset));
    });
  });
}
