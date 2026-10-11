import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/time/user_time_zone.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_time_zone_picker.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_time_zone_picker.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

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
        final session = AuthSession();
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
      },
    );
  }
}
