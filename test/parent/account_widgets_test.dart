import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';

void main() {
  group('AccountDeskCard', () {
    testWidgets('renders band title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountDeskCard(
              bandTitle: 'Профиль',
              child: const AccountEmptyText(text: 'Empty'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Профиль'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });
  });

  group('AccountFieldGroup', () {
    testWidgets('invokes onTap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountDeskCard(
              child: AccountFieldGroup(
                label: 'Email',
                value: 'test@example.com',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.text('›'), findsOneWidget);
    });
  });

  group('AccountContactBadge', () {
    testWidgets('renders verified badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccountContactBadge(label: 'Verified', verified: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verified'), findsOneWidget);
    });
  });
}
