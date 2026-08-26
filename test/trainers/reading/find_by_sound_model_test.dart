import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_by_sound/find_by_sound_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('canFitSoundFindField', () {
    test('accepts valid distractor counts', () {
      expect(canFitSoundFindField(8), isTrue);
      expect(canFitSoundFindField(28), isFalse);
    });
  });

  group('buildSoundFindTokens', () {
    test('creates one target and distractors', () {
      final tokens = buildSoundFindTokens(
        BuildSoundFindFieldInput(
          distractorCount: 5,
          letterCase: 'upper',
          rng: createSeededRng(11),
          targetLetter: 'М',
        ),
      );

      expect(tokens.length, 6);
      expect(tokens.where((token) => token.isTarget).length, 1);
      expect(tokens.firstWhere((token) => token.isTarget).letter, 'М');
    });
  });

  group('getSoundStubMessage', () {
    test('includes the display letter', () {
      expect(getSoundStubMessage('а'), contains('«а»'));
    });
  });

  group('resolveSoundPracticeLetters', () {
    test('parses comma-separated letters and keeps teacher order', () {
      expect(resolveSoundPracticeLetters('К, а, М'), ['К', 'А', 'М']);
      expect(isValidSoundPracticeLetters('А,М,К'), isTrue);
      expect(isValidSoundPracticeLetters(''), isFalse);
    });

    test('falls back to a legacy single letter', () {
      expect(resolveSoundPracticeLetters(null, 'б'), ['Б']);
    });
  });

  group('buildSoundFindRoundSeed', () {
    test('includes sound trainer key and round in hash', () {
      final withKey = buildSoundFindRoundSeed(
        targetLetter: 'М',
        letterCase: 'upper',
        distractorCount: 5,
        layoutSalt: 42,
        roundIndex: 0,
      );
      final withoutKey = hashParamsSeed(['М', 'upper', 5, 42, 0]);

      expect(withKey, isNot(withoutKey));
      expect(
        buildSoundFindRoundSeed(
          targetLetter: 'М',
          letterCase: 'upper',
          distractorCount: 5,
          layoutSalt: 42,
          roundIndex: 0,
        ),
        withKey,
      );
      expect(
        buildSoundFindRoundSeed(
          targetLetter: 'М',
          letterCase: 'upper',
          distractorCount: 5,
          layoutSalt: 42,
          roundIndex: 1,
        ),
        isNot(withKey),
      );
    });
  });
}
