import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_orientation_pick/orientation_pick_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('isOrientationPickableLetter', () {
    test('rejects round letters', () {
      expect(isOrientationPickableLetter('О'), isFalse);
      expect(isOrientationPickableLetter('о'), isFalse);
    });

    test('accepts asymmetric letters', () {
      expect(isOrientationPickableLetter('А'), isTrue);
      expect(isOrientationPickableLetter('Л'), isTrue);
    });
  });

  group('getWrongRotationPool', () {
    test('includes diagonal rotations for regular letters', () {
      expect(getWrongRotationPool('А'), baseWrongRotationAngles);
      expect(getWrongRotationPool('А'), contains(45));
      expect(getWrongRotationPool('А'), contains(135));
      expect(getWrongRotationPool('А'), contains(315));
    });

    test('skips 180 for symmetric letters but keeps diagonals', () {
      expect(getWrongRotationPool('Т'), [45, 90, 135, 225, 270, 315]);
    });
  });

  group('buildOrientationOptions', () {
    test('creates one upright option and rotated distractors', () {
      final options = buildOrientationOptions(
        BuildOrientationOptionsInput(
          letter: 'А',
          letterCase: 'upper',
          optionCount: 4,
          rng: createSeededRng(21),
        ),
      );

      expect(options.length, 4);
      expect(options.where((option) => option.isUpright).length, 1);
      expect(options.where((option) => !option.isUpright).length, 3);
      expect(options.every((option) => option.letter == 'А'), isTrue);
      expect(
        options.firstWhere((option) => option.isUpright).rotationDeg,
        0,
      );
      expect(
        options.every((option) => option.isUpright || option.rotationDeg != 0),
        isTrue,
      );
    });

    test('can use 45-degree distractors', () {
      final options = buildOrientationOptions(
        BuildOrientationOptionsInput(
          letter: 'К',
          letterCase: 'upper',
          optionCount: 6,
          rng: createSeededRng(42),
        ),
      );
      final wrongRotations = options
          .where((option) => !option.isUpright)
          .map((option) => option.rotationDeg)
          .toList();

      expect(wrongRotations.any((rotation) => rotation % 45 == 0), isTrue);
      expect(wrongRotations.every((rotation) => rotation != 0), isTrue);
    });

    test('is deterministic for the same seed', () {
      final first = buildOrientationOptions(
        BuildOrientationOptionsInput(
          letter: 'М',
          letterCase: 'lower',
          optionCount: 5,
          rng: createSeededRng(88),
        ),
      );
      final second = buildOrientationOptions(
        BuildOrientationOptionsInput(
          letter: 'М',
          letterCase: 'lower',
          optionCount: 5,
          rng: createSeededRng(88),
        ),
      );

      expect(
        first.map((option) => [option.id, option.rotationDeg, option.isUpright]),
        second.map((option) => [option.id, option.rotationDeg, option.isUpright]),
      );
    });
  });

  group('isUprightOptionSelected', () {
    test('returns true only for the upright option id', () {
      final options = buildOrientationOptions(
        BuildOrientationOptionsInput(
          letter: 'К',
          letterCase: 'upper',
          optionCount: 4,
          rng: createSeededRng(5),
        ),
      );
      final uprightId = options.firstWhere((option) => option.isUpright).id;
      final wrongId = options.firstWhere((option) => !option.isUpright).id;

      expect(isUprightOptionSelected(wrongId, options), isFalse);
      expect(isUprightOptionSelected(uprightId, options), isTrue);
    });
  });

  group('buildOrientationPickRoundSeed', () {
    test('includes letter-orientation-pick trainer key in hash', () {
      final withKey = buildOrientationPickRoundSeed(['А', 4, 'upper', 123]);
      final withoutKey = hashParamsSeed(['А', 4, 'upper', 123]);

      expect(withKey, isNot(withoutKey));
      expect(
        buildOrientationPickRoundSeed(['А', 4, 'upper', 123]),
        buildOrientationPickRoundSeed(['А', 4, 'upper', 123]),
      );
    });
  });
}
