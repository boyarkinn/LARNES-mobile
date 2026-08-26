import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_sound/letter_first_by_sound_audio.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_sound/letter_first_by_sound_trainer.dart';
import 'package:larnes_mobile/trainers/reading/sound_play_button.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterFirstBySoundTrainer', () {
    testWidgets('starts in instruction phase inside TrainerScene', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterFirstBySoundTrainer(
                params: {
                  'practiceLetters': 'А,Д,Н',
                  'rounds': 6,
                  'distractorCount': 3,
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
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-first-by-sound-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterFirstBySoundTrainer(
                params: {
                  'practiceLetters': 'Н,Д',
                  'rounds': 4,
                  'distractorCount': 2,
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

    test('keeps instruction, countdown and first-words audio wiring', () {
      expect(kLetterFirstBySoundInstructionPlaybackRate, 1.5);
      expect(
        File('assets/audio/ru/reading/letter-first-by-sound/instruction.mp3')
            .existsSync(),
        isTrue,
      );

      final trainerSource = File(
        'lib/trainers/reading/letter_first_by_sound/letter_first_by_sound_trainer.dart',
      ).readAsStringSync();

      expect(trainerSource, contains('LetterFirstBySoundPhase.countdown'));
      expect(trainerSource, contains('_countdownStepMs = 750'));
      expect(trainerSource, contains('TrainerInstructionScene'));
      expect(
        trainerSource,
        contains('Прослушай слово и нажми на первую букву этого слова'),
      );
      expect(trainerSource, contains('playFirstWordAudio'));
      expect(trainerSource, contains('playLetterFirstBySoundInstruction'));
      expect(trainerSource, contains('getFirstWordImageWidgetAsset'));
      expect(trainerSource, contains('SoundPlayButtonVariant.chrome'));
      expect(trainerSource, contains('Positioned'));
      expect(trainerSource, contains('_advanceRound'));
      expect(trainerSource, isNot(contains('displayWord')));
      expect(trainerSource, isNot(contains('Заглушка аудио')));
    });
  });
}
