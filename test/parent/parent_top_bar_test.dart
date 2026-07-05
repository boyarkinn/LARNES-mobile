import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_top_bar.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    final localeController = LocaleController();
    return LocaleScope(
      localeController: localeController,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: ParentParchmentBackground(child: child),
        ),
      ),
    );
  }

  group('ParentHeader', () {
    testWidgets('shows centered title without back on root screens', (tester) async {
      await tester.pumpWidget(
        wrap(const ParentHeader(title: 'Кто сегодня занимается')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Кто сегодня занимается'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(find.text('Назад'), findsNothing);
      expect(find.text('Аккаунт'), findsNothing);
    });

    testWidgets('shows back chevron when showBack is true', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ParentHeader(
            title: 'Профиль',
            showBack: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    });

    testWidgets('back tap pops navigator when stack allows', (tester) async {
      await tester.pumpWidget(
        LocaleScope(
          localeController: LocaleController(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ru'),
            home: Navigator(
              pages: const [
                MaterialPage(
                  key: ValueKey('root'),
                  child: ParentParchmentBackground(
                    child: SizedBox(key: Key('root-body')),
                  ),
                ),
                MaterialPage(
                  key: ValueKey('detail'),
                  child: ParentParchmentBackground(
                    child: ParentHeader(title: 'Детали'),
                  ),
                ),
              ],
              onPopPage: (route, result) {
                if (!route.didPop(result)) {
                  return false;
                }
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byKey(const Key('root-body')), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('root-body')), findsOneWidget);
    });
  });

  group('ParentScaffold', () {
    testWidgets('renders header and body', (tester) async {
      await tester.pumpWidget(
        wrap(
          ParentScaffold(
            title: 'Test',
            body: const Text('Body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });
  });
}
