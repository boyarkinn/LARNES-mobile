import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_background.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_language_picker.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_legal_footer.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('web AuthScaffold uses auth background, kicker area and legal footer', (
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
            variant: AuthScaffoldVariant.web,
            child: const AuthCompactKicker(text: 'Sign in'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthBackground), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.byType(AuthLegalFooter), findsOneWidget);
    expect(find.byType(AuthLanguageFooterLink), findsOneWidget);
    expect(find.text('Legal information'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
  });

  testWidgets('legacy AuthScaffold keeps Morning Desk parchment', (tester) async {
    final localeController = LocaleController();

    await tester.pumpWidget(
      LocaleScope(
        localeController: localeController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AuthScaffold(
            title: 'Sign in',
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthBackground), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
