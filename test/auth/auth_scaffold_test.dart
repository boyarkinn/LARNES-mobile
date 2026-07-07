import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_language_picker.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('AuthScaffold uses Morning Desk parchment and footer language link', (
    tester,
  ) async {
    final localeController = LocaleController();

    await tester.pumpWidget(
      LocaleScope(
        localeController: localeController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AuthScaffold(
            title: 'Sign in',
            child: const AuthHeader(subtitle: 'Phone or email'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ParentParchmentBackground), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Phone or email'), findsOneWidget);
    expect(find.byType(AuthLanguageFooterLink), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('RU'), findsNothing);
  });
}
