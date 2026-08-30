import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/screens/trainers/trainers_directions_screen.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

Dio trainersCatalogDio({required List<Map<String, dynamic>> groups}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.endsWith('/children/child-1/trainers/catalog')) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'status': 'success',
                'locale': 'ru',
                'directionLabels': {
                  'mental': 'МЕНТАЛЬНАЯ АРИФМЕТИКА',
                  'reading': 'ЧТЕНИЕ',
                },
                'groups': groups,
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

Widget wrapCatalogScreen({
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
  group('TrainersDirectionsScreen catalog', () {
    testWidgets('renders published direction labels from catalog API', (tester) async {
      final authSession = AuthSession(
        apiClient: ApiClient(
          dio: trainersCatalogDio(
            groups: [
              {
                'direction': 'mental',
                'trainers': [
                  {
                    'direction': 'mental',
                    'key': 'topic-chain-flash',
                    'title': 'Topic chain flash',
                  },
                ],
              },
              {
                'direction': 'reading',
                'trainers': [
                  {
                    'direction': 'reading',
                    'key': 'letter-first-by-sound',
                    'title': 'Letter first',
                  },
                ],
              },
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        wrapCatalogScreen(
          authSession: authSession,
          child: const TrainersDirectionsScreen(childId: 'child-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('МЕНТАЛЬНАЯ АРИФМЕТИКА'), findsOneWidget);
      expect(find.text('ЧТЕНИЕ'), findsOneWidget);
    });

    testWidgets('shows empty state when catalog groups are empty', (tester) async {
      final authSession = AuthSession(
        apiClient: ApiClient(dio: trainersCatalogDio(groups: const [])),
      );

      await tester.pumpWidget(
        wrapCatalogScreen(
          authSession: authSession,
          child: const TrainersDirectionsScreen(childId: 'child-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Опубликованных тренажёров пока нет.'), findsOneWidget);
    });
  });
}
