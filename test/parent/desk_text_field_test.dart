import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';

void main() {
  test('DeskTextField focused border uses ParentColors.shell', () {
    final decoration = DeskTextField.inputDecoration();
    final focusedBorder = decoration.focusedBorder! as OutlineInputBorder;

    expect(focusedBorder.borderSide.color, ParentColors.shell);
  });

  testWidgets('DeskTextField renders label and field', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeskTextField(
            controller: controller,
            label: 'Login',
          ),
        ),
      ),
    );

    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
