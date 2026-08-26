import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/reading_param_validators.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('reading validators', () {
    test('accepts letter-find-tap params', () {
      final result = validateTrainerParams('letter-find-tap', {
        'letter': 'а',
        'letterCase': 'upper',
        'targetCount': 3,
        'distractorCount': 5,
      });

      expect(result.ok, isTrue);
      expect(result.params?['letter'], 'А');
      expect(result.params?['targetCount'], 3);
    });

    test('accepts letter-first-by-sound defaults and teacher letter order', () {
      final empty = validateTrainerParams('letter-first-by-sound', {});
      expect(empty.ok, isTrue);
      expect(empty.params?['practiceLetters'], 'А,Д,Н');
      expect(empty.params?['rounds'], 6);
      expect(empty.params?['distractorCount'], 3);
      expect(empty.params?['letterCase'], 'upper');

      final listed = validateTrainerParams('letter-first-by-sound', {
        'practiceLetters': 'н, а, д',
        'rounds': 4,
        'distractorCount': 2,
        'letterCase': 'lower',
      });
      expect(listed.ok, isTrue);
      expect(listed.params?['practiceLetters'], 'Н,А,Д');
      expect(listed.params?['rounds'], 4);

      final missingBank = validateTrainerParams('letter-first-by-sound', {
        'practiceLetters': 'Ъ',
      });
      expect(missingBank.ok, isFalse);

      final tooManyButtons = validateTrainerParams('letter-first-by-sound', {
        'distractorCount': 8,
      });
      expect(tooManyButtons.ok, isFalse);
      expect(validateTrainerParams('letter-first-by-image', {}).ok, isFalse);
    });

    test('accepts letter-find-by-sound practice letters and legacy letter', () {
      final listed = validateTrainerParams('letter-find-by-sound', {
        'practiceLetters': 'к, а, м',
        'distractorCount': 5,
        'letterCase': 'upper',
      });

      expect(listed.ok, isTrue);
      expect(listed.params?['practiceLetters'], 'К,А,М');
      expect(listed.params?.containsKey('letter'), isFalse);

      final legacy = validateTrainerParams('letter-find-by-sound', {
        'letter': 'б',
        'distractorCount': 5,
        'letterCase': 'lower',
      });

      expect(legacy.ok, isTrue);
      expect(legacy.params?['practiceLetters'], 'Б');
    });

    test('rejects letter-find-tap overflow field', () {
      final result = validateTrainerParams('letter-find-tap', {
        'letter': 'М',
        'targetCount': 20,
        'distractorCount': 20,
      });

      expect(result.ok, isFalse);
    });

    test('accepts letter-place-in-word with eligible practice letters', () {
      final result = validateTrainerParams('letter-place-in-word', {
        'practiceLetters': 'а, м',
        'entityCount': 1,
        'distractorCount': 2,
        'letterCase': 'upper',
        'wordCase': 'upper',
      });

      expect(result.ok, isTrue);
      expect(result.params?['practiceLetters'], 'А,М');
    });

    test('accepts letter-word-link for А with enough cards', () {
      final result = validateTrainerParams('letter-word-link', {
        'letter': 'А',
        'entityCount': 4,
        'letterCase': 'upper',
        'wordCase': 'upper',
      });

      expect(result.ok, isTrue);
    });

    test('rejects unsupported letter-build catalog letter', () {
      final result = validateTrainerParams('letter-build', {
        'letter': 'Ё',
        'letterCase': 'upper',
      });

      expect(result.ok, isFalse);
    });

    test('accepts letter-grid-match admin form aliases', () {
      final result = validateTrainerParams('letter-grid-match', {
        'practiceLetters': 'А,М,К',
        'digit': 3,
        'entityCount': 5,
        'letterCase': 'upper',
      });

      expect(result.ok, isTrue);
      expect(result.params?['gridSize'], 3);
      expect(result.params?['filledCount'], 5);
    });

    test('rejects letter-grid-match overflow filled count', () {
      final result = validateTrainerParams('letter-grid-match', {
        'practiceLetters': 'А,М,К',
        'gridSize': 2,
        'filledCount': 5,
        'letterCase': 'upper',
      });

      expect(result.ok, isFalse);
    });

    test('registered reading key validates instead of unknown error', () {
      final result = validateTrainerParams('letter-trace', {
        'letter': 'Б',
        'letterCase': 'lower',
      });

      expect(result.ok, isTrue);
      expect(result.params?['letter'], 'Б');
      expect(result.params?['letterCase'], 'lower');
    });
  });
}
