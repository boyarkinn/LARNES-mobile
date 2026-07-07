import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/otp_input.dart';

void main() {
  test('DeskTextField focused border uses ParentColors.shell', () {
    final decoration = DeskTextField.inputDecoration();
    final focusedBorder = decoration.focusedBorder! as OutlineInputBorder;

    expect(focusedBorder.borderSide.color, ParentColors.shell);
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

  testWidgets('AuthPrimaryButton uses ParentScaleTap when enabled', (tester) async {
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
