import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';
import 'package:larnes_mobile/features/parent/widgets/study_hub_card.dart';
import 'package:larnes_mobile/features/parent/widgets/study_hub_card_icon.dart';

void main() {
  Widget wrap(Widget child) {
    final localeController = LocaleController();
    return LocaleScope(
      localeController: localeController,
      child: MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  group('StudyHubCard', () {
    testWidgets('shows title and icon without subtitle', (tester) async {
      await tester.pumpWidget(
        wrap(
          StudyHubCard(
            title: 'Домашние задания',
            tokens: homeworkHubCardTokens(),
            icon: HubCardIconKind.homework,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Домашние задания'), findsOneWidget);
      expect(find.byType(StudyHubCardIcon), findsOneWidget);
    });

    testWidgets('shows optional subtitle', (tester) async {
      await tester.pumpWidget(
        wrap(
          StudyHubCard(
            title: 'Урок 1',
            subtitle: 'В процессе · 12.07.2026',
            tokens: homeworkAssignmentCardTokens('in_progress'),
            icon: HubCardIconKind.homework,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Урок 1'), findsOneWidget);
      expect(find.text('В процессе · 12.07.2026'), findsOneWidget);
    });

    testWidgets('static card has no tap handler', (tester) async {
      await tester.pumpWidget(
        wrap(
          StudyHubCard(
            title: 'Завершено',
            tokens: directionHubCardTokens('chtenie'),
            icon: HubCardIconKind.reading,
            staticCard: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ParentScaleTap), findsNothing);
    });

    testWidgets('uses study hub band height', (tester) async {
      await tester.pumpWidget(
        wrap(
          StudyHubCard(
            title: 'Чтение',
            tokens: directionHubCardTokens('chtenie'),
            icon: HubCardIconKind.reading,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final band = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(StudyHubCard),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is SizedBox &&
                widget.height == ParentStudyHubCardMetrics.bandHeight,
          ),
        ).first,
      );
      expect(band.height, ParentStudyHubCardMetrics.bandHeight);
    });
  });
}
