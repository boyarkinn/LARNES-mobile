import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/shared/theme/trainer_direction_theme.dart';

void main() {
  group('trainer direction theme', () {
    test('keeps one canonical base-color map', () {
      expect(
        trainerDirectionThemes.map(
          (direction, theme) => MapEntry(direction, theme.base),
        ),
        const {
          TrainerDirection.math: Color(0xFFE4573D),
          TrainerDirection.reading: Color(0xFF249B73),
          TrainerDirection.mental: Color(0xFF7759D6),
          TrainerDirection.intel: Color(0xFF2F66D0),
        },
      );
      expect(
        trainerDirectionThemes[TrainerDirection.mental]!.secondary,
        const Color(0xFF5BC4D6),
      );
    });

    testWidgets('provides direction and disables ambient motion', (
      tester,
    ) async {
      late TrainerDirection direction;
      late TrainerDirectionTheme theme;

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: TrainerDirectionThemeScope(
              direction: TrainerDirection.mental,
              child: TrainerDirectionStage(child: _ScopeProbe()),
            ),
          ),
        ),
      );

      final probeContext = tester.element(find.byType(_ScopeProbe));
      final scope = TrainerDirectionThemeScope.of(probeContext);
      direction = scope.direction;
      theme = scope.theme;

      expect(direction, TrainerDirection.mental);
      expect(theme, same(trainerDirectionThemes[TrainerDirection.mental]));
      expect(
        find.byKey(const ValueKey('trainer-direction-stage-static')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('trainer-direction-stage-ambient')),
        findsOneWidget,
      );
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    });
  });
}

class _ScopeProbe extends StatelessWidget {
  const _ScopeProbe();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
