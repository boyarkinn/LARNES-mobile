import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/screens/register_type_screen.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_register_type_card.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('RegisterTypeScreen shows three Morning Desk type cards', (tester) async {
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

    expect(find.byType(AuthRegisterTypeCard), findsNWidgets(3));
    expect(find.byType(ParentScaleTap), findsWidgets);
    expect(find.text('Parent'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Network owner'), findsOneWidget);
  });
}
