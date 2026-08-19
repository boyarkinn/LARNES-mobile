import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/screens/register_type_screen.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_role_card.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('RegisterTypeScreen shows three web auth role cards', (tester) async {
    final localeController = LocaleController();

    await tester.pumpWidget(
      LocaleScope(
        localeController: localeController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RegisterTypeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthRoleCard), findsNWidgets(3));
    expect(find.text("I'm a parent / guardian"), findsOneWidget);
    expect(find.text("I'm a teacher / tutor"), findsOneWidget);
    expect(find.text('I represent a school / center network'), findsOneWidget);
  });
}
