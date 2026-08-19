import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/otp_input.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  test('DeskTextField focused border uses ParentColors.shell', () {
    final decoration = DeskTextField.inputDecoration();
    final focusedBorder = decoration.focusedBorder! as OutlineInputBorder;

    expect(focusedBorder.borderSide.color, ParentColors.shell);
  });

  testWidgets('AuthInput focused border uses AuthColors.cobalt', (tester) async {
    final localeController = LocaleController();
    final controller = TextEditingController();

    await tester.pumpWidget(
      LocaleScope(
        localeController: localeController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AuthInput(controller: controller, label: 'Password'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    final focusedBorder = field.decoration!.focusedBorder! as OutlineInputBorder;
    expect(focusedBorder.borderSide.color, AuthColors.cobalt);
  });

  testWidgets('AuthInput password toggle switches visibility', (tester) async {
    final localeController = LocaleController();
    final controller = TextEditingController(text: 'secret');

    await tester.pumpWidget(
      LocaleScope(
        localeController: localeController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AuthInput(
              controller: controller,
              label: 'Password',
              obscureText: true,
              enablePasswordToggle: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('OtpInput renders six digit cells', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpInput(controller: controller),
        ),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('AuthPrimaryButton web style renders label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthPrimaryButton(
            label: 'Continue',
            useWebAuthStyle: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('AuthPrimaryButton legacy uses ParentScaleTap when enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthPrimaryButton(
            label: 'Continue',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(ParentScaleTap), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
