import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/auth/token_storage.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/time/user_time_zone.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_time_zone_picker.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_time_zone_picker.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class _MemoryTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => 'synthetic-account-session';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_timezone');
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'America/New_York');
    await UserTimeZone.initialize();
  });
  tearDown(() {
    UserTimeZone.manualZone = null;
    UserTimeZone.cityZone = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  for (final admin in [false, true]) {
    testWidgets(
      '${admin ? 'admin' : 'parent'} selects a zone from a searchable list',
      (tester) async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
        final session = AuthSession(
          apiClient: ApiClient(dio: dio, tokenStorage: _MemoryTokenStorage()),
        );
        final saves = <Map<String, dynamic>>[];
        String? savedZone;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/api/account/time-zone') {
                saves.add(Map<String, dynamic>.from(options.data as Map));
                savedZone = saves.last['timeZone'] as String?;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: options.path == '/api/mobile/auth/session'
                      ? {
                          'status': 'success',
                          'user': {
                            'id': 'sample',
                            'accountType': admin ? 'admin' : 'parent',
                            'city': 'Тбилиси',
                            'cityTimeZone': 'Asia/Tbilisi',
                            'timeZone': savedZone,
                          },
                        }
                      : {'status': 'success', 'suggestions': []},
                ),
              );
            },
          ),
        );
        final locales = LocaleController();
        session.applyUser(
          AuthUser(
            id: 'sample',
            accountType: admin ? 'admin' : 'parent',
            city: 'Тбилиси',
            cityTimeZone: 'Asia/Tbilisi',
          ),
        );
        await tester.pumpWidget(
          AuthScope(
            authSession: session,
            child: LocaleScope(
              localeController: locales,
              child: MaterialApp(
                locale: const Locale('ru'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: admin
                        ? const AdminAccountTimeZonePicker()
                        : const AccountTimeZonePicker(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('По городу: Тбилиси'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Екатеринбург');
        await tester.pumpAndSettle();
        final results = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(ListTile),
        );
        expect(results, findsOneWidget);
        await tester.tap(results);
        await tester.pumpAndSettle();
        expect(find.textContaining('Екатеринбург'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(
          saves,
          isEmpty,
          reason: 'selecting a result only updates the account draft',
        );
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(saves.single['mode'], 'manual');
        expect(saves.single['timeZone'], 'Asia/Yekaterinburg');
        expect(saves.single.containsKey('city'), isFalse);
        expect(saves.single.containsKey('mapboxId'), isFalse);
        expect(session.user!.city, 'Тбилиси');
        expect(UserTimeZone.manualZone, 'Asia/Yekaterinburg');
        // A saved city update replaces the draft and immediately updates the source.
        session.applyUser(
          AuthUser(
            id: 'sample',
            accountType: admin ? 'admin' : 'parent',
            city: 'Москва',
            cityTimeZone: 'Europe/Moscow',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('По городу: Москва'), findsOneWidget);
        expect(find.byType(OutlinedButton), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        session.dispose();
        locales.dispose();
        dio.close();
      },
    );
  }
}
