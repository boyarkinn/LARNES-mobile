import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_invite_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_language_picker.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('AuthInviteShell uses web scaffold with footer language picker', (tester) async {
    final localeController = LocaleController();

    await tester.pumpWidget(
      LocaleScope(
        localeController: localeController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthInviteShell(
            title: 'Family invitation',
            subtitle: 'Accept the invitation',
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthInviteHeader), findsOneWidget);
    expect(find.byType(AuthLanguageFooterLink), findsOneWidget);
    expect(find.text('FAMILY INVITATION'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
  });
}
