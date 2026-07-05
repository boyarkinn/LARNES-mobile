import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_language_picker.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  Widget wrap(LocaleController controller, Widget child) {
    return LocaleScope(
      localeController: controller,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: controller.locale,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('highlights active locale and switches on tap', (tester) async {
    final controller = LocaleController();

    await tester.pumpWidget(
      wrap(
        controller,
        const AccountDeskCard(
          bandTitle: 'Язык',
          child: AccountLanguagePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(controller.localeCode, 'en');
  });
}
