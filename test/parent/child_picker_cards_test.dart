import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/theme/child_avatar_catalog.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/add_child_card.dart';
import 'package:larnes_mobile/features/parent/widgets/child_avatar.dart';
import 'package:larnes_mobile/features/parent/widgets/child_profile_card.dart';

ParentChild _sampleChild({
  ChildCardColor cardColor = ChildCardColor.violet,
  ChildAvatarSlug avatarSlug = ChildAvatarSlug.owl,
}) {
  return ParentChild(
    id: 'c1',
    firstName: 'Анна',
    lastName: 'Иванова',
    patronymic: 'Петровна',
    cardColor: cardColor,
    avatarSlug: avatarSlug,
    ageYears: 7,
  );
}

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

  group('ChildProfileCard', () {
    testWidgets('shows avatar, names and age pill', (tester) async {
      await tester.pumpWidget(
        wrap(
          ChildProfileCard(
            child: _sampleChild(),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Иванова'), findsOneWidget);
      expect(find.text('Анна Петровна'), findsOneWidget);
      expect(find.textContaining('7'), findsOneWidget);
      expect(find.byType(ChildAvatar), findsOneWidget);
    });

    testWidgets('uses card color band', (tester) async {
      await tester.pumpWidget(
        wrap(
          ChildProfileCard(
            child: _sampleChild(cardColor: ChildCardColor.emerald),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final band = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(ChildProfileCard),
          matching: find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.height == ParentChildCardMetrics.bandHeight,
          ),
        ).first,
      );
      expect(band.height, ParentChildCardMetrics.bandHeight);
    });
  });

  group('AddChildCard', () {
    testWidgets('shows cobalt plus icon and label', (tester) async {
      await tester.pumpWidget(
        wrap(
          AddChildCard(
            label: 'Добавить ребёнка',
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+'), findsOneWidget);
      expect(find.text('Добавить ребёнка'), findsOneWidget);
    });

    testWidgets('matches child card list height', (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              ChildProfileCard(
                child: _sampleChild(),
                onTap: () {},
              ),
              AddChildCard(
                label: 'Добавить ребёнка',
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final childHeight = tester.getSize(find.byType(ChildProfileCard)).height;
      final addHeight = tester.getSize(find.byType(AddChildCard)).height;
      expect(childHeight, ParentChildCardMetrics.pickerListCardHeight);
      expect(addHeight, childHeight);
    });
  });
}
