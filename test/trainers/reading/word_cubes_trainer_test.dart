import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/word_cubes/word_cubes_trainer.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

void main() {
  testWidgets('a frozen cube with custom faces renders and completes once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordCubesTrainer(
            params: const {
              '__runtimeSnapshot': {
                'version': 1,
                'trainerKey': 'word-cubes',
                'mode': 'materialized',
                'payload': {
                  'rounds': [
                    {
                      'word': {
                        'slug': 'new',
                        'word': 'ЛУ',
                        'parts': [
                          {'cubeId': 'custom', 'target': 'ЛУ'},
                        ],
                      },
                      'cubes': [
                        {
                          'cube': {
                            'id': 'custom',
                            'kind': 'voiced',
                            'small': false,
                            'faces': ['Л', 'ЛУ'],
                          },
                          'target': 'ЛУ',
                          'initialFace': 0,
                        },
                      ],
                    },
                  ],
                },
              },
            },
            onComplete: () => completed++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final cube = find.bySemanticsLabel(
      'Кубик 1, склад Л. Нажми, чтобы изменить склад',
    );
    expect(cube, findsOneWidget);
    await tester.tap(cube);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 430));
    await tester.pump();
    expect(find.text('Верно!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox());
    await resetSharedClipPlayerForTests();
    semantics.dispose();
  });
  testWidgets('a historical seed cannot rebuild a retired word catalogue', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WordCubesTrainer(
            params: {
              'wordSlug': 'all',
              '__runtimeSnapshot': {
                'version': 1,
                'trainerKey': 'word-cubes',
                'mode': 'materialized',
                'payload': {'seed': 42},
              },
            },
          ),
        ),
      ),
    );
    expect(find.text('Материалы упражнения не подготовлены.'), findsOneWidget);
    expect(find.byType(TrainerInstructionScene), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await resetSharedClipPlayerForTests();
  });
}
