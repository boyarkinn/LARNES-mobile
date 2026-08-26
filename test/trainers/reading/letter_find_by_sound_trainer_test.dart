import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_by_sound/letter_find_by_sound_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/sound_play_button.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterFindBySoundTrainer', () {
    testWidgets('starts in instruction phase inside TrainerScene', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterFindBySoundTrainer(
                params: {
                  'letter': 'М',
                  'distractorCount': 8,
                  'letterCase': 'upper',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerInstructionScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(SoundPlayButton), findsNothing);
      expect(find.byType(LetterFieldScene), findsNothing);
      expect(find.textContaining('Послушай'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-find-by-sound-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterFindBySoundTrainer(
                params: {
                  'letter': 'К',
                  'distractorCount': 6,
                  'letterCase': 'lower',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));
      expect(find.byType(TrainerInstructionScene), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });

    test('keeps countdown and shared letter audio wiring', () {
      final trainerSource = File(
        'lib/trainers/reading/letter_find_by_sound/letter_find_by_sound_trainer.dart',
      ).readAsStringSync();

      expect(trainerSource, contains('LetterFindBySoundPhase.countdown'));
      expect(trainerSource, contains("_countdownStepMs = 750"));
      expect(trainerSource, contains('TrainerInstructionScene'));
      expect(trainerSource, contains('Найди букву'));
      expect(trainerSource, contains('playLetterSyllableAudio'));
      expect(trainerSource, contains('playLetterFindBySoundInstruction'));
      expect(trainerSource, contains('SoundPlayButtonVariant.chrome'));
      expect(trainerSource, contains('Positioned'));
      expect(trainerSource, contains('resolveSoundPracticeLetters'));
      expect(trainerSource, contains('_roundIndex'));
      expect(trainerSource, contains('_advanceRound'));
    });
  });
}
