import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('validateTrainerParams', () {
    test('topic explanation accepts all simple lessons and known speeds', () {
      const lessons = [
        'simple-1', 'simple-2', 'simple-3', 'simple-4', 'simple-5',
        'simple-6', 'simple-7', 'simple-8', 'simple-9',
        'simple-tens', 'simple-11-19',
        'simple-44', 'simple-55', 'simple-66', 'simple-77', 'simple-88', 'simple-99',
        'simple-hundreds', 'simple-000',
        'brother-4', 'brother-3', 'brother-2', 'brother-1',
        'friend-9', 'friend-8', 'friend-7', 'friend-6', 'friend-5',
        'friend-4', 'friend-3', 'friend-2', 'friend-1',
        'friend-brother-6', 'friend-brother-7',
        'friend-brother-8', 'friend-brother-9',
      ];
      for (final lessonId in lessons) {
        expect(validateTrainerParams('abacus-topic-explanation', {
          'lessonId': lessonId,
          'speed': 'medium',
        }).ok, isTrue, reason: lessonId);
      }
      for (final speed in ['slow', 'medium', 'fast']) {
        final result = validateTrainerParams('abacus-topic-explanation', {
          'lessonId': 'simple-1',
          'speed': speed,
        });
        expect(result.params, {'lessonId': 'simple-1', 'speed': speed});
      }
      expect(validateTrainerParams('abacus-topic-explanation', {
        'lessonId': 'simple-missing',
      }).ok, isFalse);
      expect(validateTrainerParams('abacus-topic-explanation', {
        'speed': 'unknown',
      }).ok, isFalse);
    });

    test('accepts all warm-up recipes and speeds and rejects unknown values', () {
      for (final warmupType in [
        'simple-9', 'simple-tens', 'simple-2digit', 'brothers', 'friends',
      ]) {
        for (final speed in ['slow', 'medium', 'fast']) {
          final result = validateTrainerParams('abacus-warmup', {
            'warmupType': warmupType,
            'speed': speed,
          });
          expect(result.ok, isTrue);
          expect(result.params, {'warmupType': warmupType, 'speed': speed});
        }
      }
      expect(validateTrainerParams('abacus-warmup', {
        'warmupType': 'other', 'speed': 'medium',
      }).ok, isFalse);
      expect(validateTrainerParams('abacus-warmup', {
        'warmupType': 'friends', 'speed': 'other',
      }).ok, isFalse);
    });
    test('accepts number-row-show params', () {
      final result = validateTrainerParams('number-row-show', {'digit': 5});
      expect(result.ok, isTrue);
      expect(result.params, {'digit': 5, 'stepPauseSec': 1});
    });

    test('coerces string digits', () {
      final result = validateTrainerParams('number-row-show', {'digit': '3', 'stepPauseSec': '2'});
      expect(result.ok, isTrue);
      expect(result.params, {'digit': 3, 'stepPauseSec': 2});
    });

    test('accepts apple-count-show params', () {
      final result = validateTrainerParams('apple-count-show', {
        'targetCount': 3,
        'totalApples': 5,
        'targetDisplay': 'audio_only',
      });
      expect(result.ok, isTrue);
      expect(result.params, {
        'targetCount': 3,
        'totalApples': 5,
        'targetDisplay': 'audio_only',
      });
    });

    test('rejects unknown trainer', () {
      final result = validateTrainerParams('missing-trainer', {});
      expect(result.ok, isFalse);
    });

    test('registered reading key is known to registry', () {
      final result = validateTrainerParams('letter-marquee-tap', {
        'practiceLetters': 'А, Б',
        'targetCount': 3,
      });
      expect(result.ok, isTrue);
    });

    test('rejects invalid digit-find-tap field size', () {
      final result = validateTrainerParams('digit-find-tap', {
        'values': '2,5,7',
        'distractorCount': 28,
      });
      expect(result.ok, isFalse);
    });

    test('rejects digit-find-tap values outside 0-9', () {
      final result = validateTrainerParams('digit-find-tap', {
        'values': '2,12,7',
        'distractorCount': 8,
      });
      expect(result.ok, isFalse);
    });

    test('accepts flashcard-digit-match admin form fields', () {
      final result = validateTrainerParams('flashcard-digit-match', {
        'pairCount': '3',
        'rounds': '2',
        'targetMode': 'dots',
        'chainTopicId': 'simple-5',
      });

      expect(result.ok, isTrue);
      expect(result.params, {
        'topicId': 'simple-5',
        'pairCount': 3,
        'rounds': 2,
        'targetMode': 'dots',
      });
    });

    test('accepts legacy flashcard values array as pairCount only', () {
      final result = validateTrainerParams('flashcard-digit-match', {
        'totalRods': 2,
        'values': [3, 7],
      });

      expect(result.ok, isTrue);
      expect(result.params?['pairCount'], 2);
      expect(result.params?['topicId'], 'simple-2digit');
    });

    test('accepts fly-track params with defaults', () {
      final result = validateTrainerParams('fly-track', {});

      expect(result.ok, isTrue);
      expect(result.params?['gridSize'], 4);
      expect(result.params?['rounds'], 1);
      expect(result.params?['stepCount'], 5);
      expect(result.params?['stepPauseSec'], 1.5);
    });
  });
}
