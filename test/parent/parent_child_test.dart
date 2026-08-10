import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/child_profile_appearance_fields.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('ParentChild.fromJson', () {
    test('parses cardColor', () {
      final child = ParentChild.fromJson({
        'id': 'c1',
        'firstName': 'Anna',
        'cardColor': 'violet',
      });

      expect(child.cardColor, ChildCardColor.violet);
    });

    test('falls back to orange when color missing or invalid', () {
      final child = ParentChild.fromJson({
        'id': 'c1',
        'firstName': 'Anna',
        'cardColor': 'unknown',
      });

      expect(child.cardColor, defaultChildCardColor);
    });
  });

  group('CreateChildPayload.toJson', () {
    test('includes card color', () {
      const payload = CreateChildPayload(
        firstName: 'Anna',
        lastName: 'Ivanova',
        dateOfBirth: '2018-05-01',
        gender: 'female',
        cardColor: ChildCardColor.emerald,
      );

      expect(payload.toJson('ru'), {
        'firstName': 'Anna',
        'lastName': 'Ivanova',
        'dateOfBirth': '2018-05-01',
        'gender': 'female',
        'cardColor': 'emerald',
        'locale': 'ru',
      });
    });
  });

  group('ChildProfileAppearanceFields', () {
    Widget wrap({
      required ChildCardColor cardColor,
      required ValueChanged<ChildCardColor> onCardColorChanged,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: ChildProfileAppearanceFields(
            cardColor: cardColor,
            onCardColorChanged: onCardColorChanged,
          ),
        ),
      );
    }

    testWidgets('tap color swatch calls onCardColorChanged', (tester) async {
      ChildCardColor? picked;

      await tester.pumpWidget(
        wrap(
          cardColor: defaultChildCardColor,
          onCardColorChanged: (color) => picked = color,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Изумрудный'));
      await tester.pumpAndSettle();

      expect(picked, ChildCardColor.emerald);
    });
  });
}
