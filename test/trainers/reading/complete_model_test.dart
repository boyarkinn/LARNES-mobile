import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/reading/letter_complete/complete_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_complete/complete_pad_size.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('isCompletableLetter', () {
    test('allows letters with multiple strokes', () {
      expect(isCompletableLetter('А'), isTrue);
      expect(isCompletableLetter('М'), isTrue);
    });

    test('rejects single-stroke letters', () {
      expect(isCompletableLetter('О'), isFalse);
      expect(isCompletableLetter('С'), isFalse);
    });
  });

  group('resolveMissingSegmentIndex', () {
    test('returns the requested segment when valid', () {
      expect(resolveMissingSegmentIndex('А', 2, 1), 2);
    });

    test('picks a deterministic random segment', () {
      final seed = buildLetterCompleteRoundSeed(['А', 'upper', 'random']);
      final first = resolveMissingSegmentIndex('А', 'random', seed);
      final second = resolveMissingSegmentIndex('А', 'random', seed);

      expect(first >= 0 && first < 3, isTrue);
      expect(first, second);
    });
  });

  group('scoreLetterSegmentTrace', () {
    test('scores high when tracing the target segment', () {
      final reference = getLetterGuideSegmentPoints('А', 2);
      final result = scoreLetterSegmentTrace('А', 2, [reference]);

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, greaterThanOrEqualTo(passSimilarityPercent));
    });

    test('scores high for left leg segment 0 when traced', () {
      final reference = getLetterGuideSegmentPoints('А', 0);
      final result = scoreLetterSegmentTrace('А', 0, [reference]);

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, greaterThanOrEqualTo(passSimilarityPercent));
    });

    test('scores partial coverage for half of segment 0', () {
      final reference = getLetterGuideSegmentPoints('А', 0);
      final topHalf = reference.sublist(8);
      final result = scoreLetterSegmentTrace('А', 0, [topHalf]);

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, inInclusiveRange(40, 75));
    });

    test('scores low for wrong segment', () {
      final wrong = getLetterGuideSegmentPoints('А', 1);
      final result = scoreLetterSegmentTrace('А', 0, [wrong]);

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, lessThan(passSimilarityPercent));
    });

    test('returns null for empty input', () {
      final result = scoreLetterSegmentTrace('А', 0, const []);

      expect(result.similarityPercent, isNull);
    });
  });

  group('isValidMissingSegment', () {
    test('accepts random and valid indexes', () {
      expect(isValidMissingSegment('А', 'random'), isTrue);
      expect(isValidMissingSegment('А', 1), isTrue);
      expect(isValidMissingSegment('А', 9), isFalse);
    });
  });

  group('buildLetterCompleteRoundSeed', () {
    test('includes letter-complete trainer key in hash', () {
      final withKey = buildLetterCompleteRoundSeed(['А', 'upper', 'random']);
      final withoutKey = hashParamsSeed(['А', 'upper', 'random']);

      expect(withKey, isNot(withoutKey));
    });
  });

  group('complete pad sizing', () {
    test('matches trace pad square sizing', () {
      expect(completePadSize(800, 400), 340);
      expect(completePadSize(400, 800), 288);
    });
  });
}
