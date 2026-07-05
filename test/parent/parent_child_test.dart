import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/theme/child_avatar_catalog.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/child_profile_appearance_fields.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('ParentChild.fromJson', () {
    test('parses cardColor and avatarSlug', () {
      final child = ParentChild.fromJson({
        'id': 'c1',
        'firstName': 'Anna',
        'cardColor': 'violet',
        'avatarSlug': 'owl',
      });

      expect(child.cardColor, ChildCardColor.violet);
      expect(child.avatarSlug, ChildAvatarSlug.owl);
    });

    test('falls back to orange and fox when fields missing or invalid', () {
      final child = ParentChild.fromJson({
        'id': 'c1',
        'firstName': 'Anna',
        'cardColor': 'unknown',
        'avatarSlug': 'dragon',
      });

      expect(child.cardColor, defaultChildCardColor);
      expect(child.avatarSlug, defaultChildAvatarSlug);
    });
  });

  group('CreateChildPayload.toJson', () {
    test('includes appearance slugs', () {
      const payload = CreateChildPayload(
        firstName: 'Anna',
        lastName: 'Ivanova',
        dateOfBirth: '2018-05-01',
        gender: 'female',
        cardColor: ChildCardColor.emerald,
        avatarSlug: ChildAvatarSlug.bear,
      );

      expect(payload.toJson('ru'), {
        'firstName': 'Anna',
        'lastName': 'Ivanova',
        'dateOfBirth': '2018-05-01',
        'gender': 'female',
        'cardColor': 'emerald',
        'avatarSlug': 'bear',
        'locale': 'ru',
      });
    });
  });

  group('ChildProfileAppearanceFields', () {
    Widget wrap({
      required ChildCardColor cardColor,
      required ChildAvatarSlug avatarSlug,
      required ValueChanged<ChildCardColor> onCardColorChanged,
      required ValueChanged<ChildAvatarSlug> onAvatarSlugChanged,
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
            avatarSlug: avatarSlug,
            onCardColorChanged: onCardColorChanged,
            onAvatarSlugChanged: onAvatarSlugChanged,
          ),
        ),
      );
    }

    testWidgets('tap color swatch calls onCardColorChanged', (tester) async {
      ChildCardColor? picked;

      await tester.pumpWidget(
        wrap(
          cardColor: defaultChildCardColor,
          avatarSlug: defaultChildAvatarSlug,
          onCardColorChanged: (color) => picked = color,
          onAvatarSlugChanged: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Изумрудный'));
      await tester.pumpAndSettle();

      expect(picked, ChildCardColor.emerald);
    });

    testWidgets('tap avatar option calls onAvatarSlugChanged', (tester) async {
      ChildAvatarSlug? picked;

      await tester.pumpWidget(
        wrap(
          cardColor: defaultChildCardColor,
          avatarSlug: defaultChildAvatarSlug,
          onCardColorChanged: (_) {},
          onAvatarSlugChanged: (slug) => picked = slug,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Мишка'));
      await tester.pumpAndSettle();

      expect(picked, ChildAvatarSlug.bear);
    });
  });
}
