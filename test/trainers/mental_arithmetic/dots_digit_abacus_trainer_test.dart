import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/match_task_board.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/abacus_match_card.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/match_task_model.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_experience_scene.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/theme/trainer_direction_theme.dart';

void main() {
  group('DotsDigitAbacusTrainer', () {
    testWidgets('starts with visible instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: DotsDigitAbacusTrainer(params: {'value': 3}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerInstructionScene), findsOneWidget);
      expect(find.byType(MatchTaskBoard), findsNothing);
      expect(find.byType(TripleScene), findsNothing);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('dots-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: DotsDigitAbacusTrainer(params: {'value': 5}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));
    });
  });

  group('TripleScene', () {
    for (final value in [0, 1, 5, 9]) {
      testWidgets('lays out value $value with reduced motion', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: SizedBox(
                width: 320,
                height: 480,
                child: TripleScene(
                  value: value,
                  visibility: TripleSceneVisibility(
                    showAbacus: true,
                    showAbacusEquals: true,
                    showAbacusValue: true,
                    showDigit: true,
                    showDigitEquals: true,
                    showDots: true,
                    visibleDotCount: value,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('triple-digit')), findsOneWidget);
        expect(find.byKey(const Key('triple-equals-sign')), findsNWidgets(2));
        expect(find.byType(AbacusWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows the target abacus immediately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripleScene(
            value: 5,
            visibility: TripleSceneVisibility(
              showAbacus: true,
              showAbacusValue: true,
            ),
          ),
        ),
      );

      final abacus = tester.widget<AbacusWidget>(find.byType(AbacusWidget));
      expect(beadsToDigit(abacus.rods.single), 5);
    });
  });

  group('MatchTaskBoard', () {
    testWidgets(
      'keeps target options visible in overlay preview on narrow layouts',
      (tester) async {
        final plan = buildMatchTaskPlan(9, 42);

        await tester.pumpWidget(
          MaterialApp(
            home: TrainerDirectionThemeScope(
              direction: TrainerDirection.mental,
              child: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: SizedBox(
                  width: 240,
                  height: 360,
                  child: MatchTaskBoard(
                    plan: plan,
                    connections: const [],
                    disabled: true,
                    preview: true,
                    onConnect: (_) {},
                    onAllConnected: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(AbacusMatchCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('reveals all deterministic options after instruction', (
      tester,
    ) async {
      final plan = buildMatchTaskPlan(0, 17);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SizedBox(
              width: 320,
              height: 480,
              child: MatchTaskBoard(
                plan: plan,
                connections: const [],
                onConnect: (_) {},
                onAllConnected: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AbacusMatchCard), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  group('DotsDigitAbacusExperienceScene', () {
    testWidgets(
      'keeps shared objects mounted while moving explain into practice',
      (tester) async {
        final plan = buildMatchTaskPlan(5, 42);
        const visibility = TripleSceneVisibility(
          showAbacus: true,
          showAbacusEquals: true,
          showAbacusValue: true,
          showDigit: true,
          showDigitEquals: true,
          showDots: true,
          visibleDotCount: 5,
        );

        Widget scene({required bool practice, required bool instruction}) {
          return MaterialApp(
            home: TrainerDirectionThemeScope(
              direction: TrainerDirection.mental,
              child: SizedBox(
                width: 360,
                height: 640,
                child: DotsDigitAbacusExperienceScene(
                  completed: false,
                  connections: const [],
                  disabled: instruction,
                  onAllConnected: () {},
                  onConnect: (_) {},
                  plan: plan,
                  practice: practice,
                  taskInstructionLength: instruction ? 8 : 0,
                  taskInstructionVisible: instruction,
                  visibility: visibility,
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(scene(practice: false, instruction: false));
        final dotsElement = tester.element(
          find.byKey(const Key('shared-dots-object')),
        );
        final digitElement = tester.element(
          find.byKey(const Key('shared-digit-object')),
        );
        final abacusElement = tester.element(
          find.byKey(const Key('shared-abacus-object')),
        );
        final explainDots = tester.widget<AnimatedPositioned>(
          find.byKey(const Key('shared-dots-object')),
        );

        await tester.pumpWidget(scene(practice: true, instruction: true));
        final practiceDots = tester.widget<AnimatedPositioned>(
          find.byKey(const Key('shared-dots-object')),
        );

        expect(
          tester.element(find.byKey(const Key('shared-dots-object'))),
          same(dotsElement),
        );
        expect(
          tester.element(find.byKey(const Key('shared-digit-object'))),
          same(digitElement),
        );
        expect(
          tester.element(find.byKey(const Key('shared-abacus-object'))),
          same(abacusElement),
        );
        expect(practiceDots.left, isNot(explainDots.left));
        expect(find.byType(DotsDigitAbacusExperienceScene), findsOneWidget);
        expect(find.byType(MatchTaskBoard), findsOneWidget);
        expect(find.byType(TrainerInstructionScene), findsOneWidget);
        expect(find.byType(AbacusMatchCard), findsNWidgets(2));
      },
    );

    testWidgets('uses zero-duration object movement with reduced motion', (
      tester,
    ) async {
      final plan = buildMatchTaskPlan(1, 7);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SizedBox(
              width: 320,
              height: 480,
              child: DotsDigitAbacusExperienceScene(
                completed: false,
                connections: const [],
                disabled: true,
                onAllConnected: () {},
                onConnect: (_) {},
                plan: plan,
                practice: true,
                taskInstructionLength: 0,
                taskInstructionVisible: true,
                visibility: const TripleSceneVisibility(
                  showAbacus: true,
                  showDigit: true,
                  showDots: true,
                  visibleDotCount: 1,
                ),
              ),
            ),
          ),
        ),
      );

      final dots = tester.widget<AnimatedPositioned>(
        find.byKey(const Key('shared-dots-object')),
      );
      expect(dots.duration, Duration.zero);
      expect(tester.takeException(), isNull);
    });
  });
}
