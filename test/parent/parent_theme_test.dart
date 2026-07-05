import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_theme_preview.dart';

void main() {
  group('ParentColors', () {
    test('matches web parent.css tokens', () {
      expect(ParentColors.parchment, const Color(0xFFF0EBE3));
      expect(ParentColors.parchmentDeep, const Color(0xFFE4DDD2));
      expect(ParentColors.ink, const Color(0xFF1A1D2E));
      expect(ParentColors.inkMuted, const Color(0xFF4A5068));
      expect(ParentColors.surface, const Color(0xFFFFFCF8));
      expect(ParentColors.shell, const Color(0xFF2B59C3));
      expect(ParentColors.shellDeep, const Color(0xFF1E429F));
      expect(ParentColors.shellSoft, const Color(0xFFDCE8FF));
      expect(ParentColors.line, const Color(0xFFD5CFC4));
      expect(ParentColors.lineHover, const Color(0xFFC9C2B8));
    });

    test('card radius matches 1.125rem', () {
      expect(ParentRadii.card, 18);
    });
  });

  group('ChildCardColorTokens', () {
    test('all six slugs match web child-card-colors.ts', () {
      const expected = <ChildCardColor, List<int>>{
        ChildCardColor.orange: [0xFFFF6B35, 0xFFE04F1A, 0xFFFFF0E8],
        ChildCardColor.emerald: [0xFF1B8A6B, 0xFF126B52, 0xFFE3F5EF],
        ChildCardColor.violet: [0xFF6B4EAA, 0xFF523A88, 0xFFF0EBFA],
        ChildCardColor.sky: [0xFF0C8BD6, 0xFF07689F, 0xFFE3F2FC],
        ChildCardColor.rose: [0xFFE84855, 0xFFC91D38, 0xFFFFE8EA],
        ChildCardColor.amber: [0xFFF2A022, 0xFFC97704, 0xFFFFF4E0],
      };

      for (final entry in expected.entries) {
        final tokens = childCardColorTokens(entry.key);
        expect(tokens.tag.toARGB32(), entry.value[0]);
        expect(tokens.tagDeep.toARGB32(), entry.value[1]);
        expect(tokens.soft.toARGB32(), entry.value[2]);
      }
    });

    test('parseChildCardColor accepts web slugs', () {
      expect(parseChildCardColor('orange'), ChildCardColor.orange);
      expect(parseChildCardColor('unknown'), isNull);
      expect(
        childCardColorTokensFromSlug(null).tag,
        childCardColorTokens(defaultChildCardColor).tag,
      );
    });
  });

  testWidgets('ParentThemePreview renders token samples', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ParentThemePreview()),
    );
    await tester.pumpAndSettle();

    expect(find.text('parentCardDecoration()'), findsOneWidget);
    expect(find.text('Fredoka display'), findsOneWidget);
    expect(find.text('orange'), findsOneWidget);
  });
}
