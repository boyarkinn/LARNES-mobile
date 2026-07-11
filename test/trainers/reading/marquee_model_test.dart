import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/marquee_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('buildMarqueeStream', () {
    test('includes many more target letters than the catch goal', () {
      final stream = buildMarqueeStream(
        const BuildMarqueeStreamInput(
          practiceLetters: ['А', 'М', 'К'],
          seed: 12,
          targetCount: 5,
        ),
      );

      final targets = stream.where((token) => token.isTarget).toList();

      expect(targets.length >= 15, isTrue);
      expect(
        targets.every((token) => ['А', 'М', 'К'].contains(token.letter)),
        isTrue,
      );
    });

    test('mixes practice letters throughout the stream', () {
      final stream = buildMarqueeStream(
        const BuildMarqueeStreamInput(
          practiceLetters: ['У', 'С', 'Н'],
          seed: 99,
          targetCount: 2,
        ),
      );

      final targets = stream.where((token) => token.isTarget).toList();
      final uniqueTargetLetters = targets.map((token) => token.letter).toSet();

      expect(targets.length >= 6, isTrue);
      expect(uniqueTargetLetters.length >= 2, isTrue);
    });

    test('is deterministic for the same seed', () {
      const input = BuildMarqueeStreamInput(
        practiceLetters: ['А', 'М'],
        seed: 3,
        targetCount: 4,
      );
      final first = buildMarqueeStream(input);
      final second = buildMarqueeStream(input);

      expect(
        first.map((token) => [token.id, token.isTarget, token.letter]),
        second.map((token) => [token.id, token.isTarget, token.letter]),
      );
    });
  });

  group('getMarqueeMotion', () {
    test('returns slower motion for slow speed', () {
      expect(
        getMarqueeMotion('slow').pixelsPerSecond <
            getMarqueeMotion('fast').pixelsPerSecond,
        isTrue,
      );
    });

    test('matches web speed presets', () {
      expect(getMarqueeMotion('medium').pixelsPerSecond, 120);
      expect(getMarqueeMotion('fast').pixelsPerSecond, 240);
      expect(getMarqueeMotion('slow').pixelsPerSecond, 85);
    });
  });

  group('round helpers', () {
    test('detects successful catch only for targets', () {
      expect(
        isSuccessfulMarqueeCatch(
          const MarqueeTokenSpec(id: '1', isTarget: true, letter: 'А'),
        ),
        isTrue,
      );
      expect(
        isSuccessfulMarqueeCatch(
          const MarqueeTokenSpec(id: '2', isTarget: false, letter: 'Б'),
        ),
        isFalse,
      );
    });

    test('completes after target count', () {
      expect(isMarqueeRoundComplete(5, 5), isTrue);
      expect(isMarqueeRoundComplete(4, 5), isFalse);
    });
  });

  group('getMarqueeDisplayLetter', () {
    test('applies letter case', () {
      expect(getMarqueeDisplayLetter('А', 'lower'), 'а');
    });
  });

  group('buildMarqueeStreamSeed', () {
    test('changes with params', () {
      expect(
        buildMarqueeStreamSeed(['А', 5, 'upper', 'medium']),
        isNot(buildMarqueeStreamSeed(['А', 6, 'upper', 'medium'])),
      );
    });

    test('includes marquee-tap trainer key in hash', () {
      final withKey = buildMarqueeStreamSeed(['А', 5, 'upper', 'medium', 9]);
      final withoutKey = hashParamsSeed(['А', 5, 'upper', 'medium', 9]);

      expect(withKey, isNot(withoutKey));
    });
  });
}
