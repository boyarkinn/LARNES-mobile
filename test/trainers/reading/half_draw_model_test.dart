import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/reading/letter_half_draw/half_draw_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_half_draw/half_draw_pad_size.dart';

void main() {
  group('clipSegmentToRightHalf', () {
    test('keeps only the right portion of a segment', () {
      final clipped = clipSegmentToRightHalf([
        const TracePoint(x: 0.2, y: 0.2),
        const TracePoint(x: 0.5, y: 0.5),
        const TracePoint(x: 0.8, y: 0.8),
      ]);

      expect(clipped.length, greaterThanOrEqualTo(2));
      expect(clipped.every((point) => point.x >= halfSplit), isTrue);
      expect(clipped.first.x, halfSplit);
      expect(clipped.last.x, 0.8);
    });
  });

  group('getRightHalfReferencePoints', () {
    test('returns reference points for asymmetric letters', () {
      final points = getRightHalfReferencePoints('А');

      expect(points.length, greaterThanOrEqualTo(2));
      expect(points.every((point) => point.x >= halfSplit), isTrue);
    });
  });

  group('filterStrokesToRightHalf', () {
    test('drops ink drawn on the left side', () {
      final filtered = filterStrokesToRightHalf([
        [
          const TracePoint(x: 0.2, y: 0.5),
          const TracePoint(x: 0.55, y: 0.5),
          const TracePoint(x: 0.7, y: 0.6),
        ],
      ]);

      expect(filtered.length, 1);
      expect(filtered.first.every((point) => point.x >= halfSplit), isTrue);
    });
  });

  group('isPointInDrawableHalf', () {
    test('accepts only the right side of the pad', () {
      expect(isPointInDrawableHalf(const Offset(40, 50)), isFalse);
      expect(isPointInDrawableHalf(const Offset(60, 50)), isTrue);
    });
  });

  group('scoreLetterHalfDraw', () {
    test('requires enough ink on the right half', () {
      final score = scoreLetterHalfDraw('А', [
        [const TracePoint(x: 0.2, y: 0.5)],
      ]);

      expect(score.hasEnoughInk, isFalse);
      expect(score.similarityPercent, isNull);
    });

    test('marks a close right-half trace as successful', () {
      final reference = getRightHalfReferencePoints('А');
      final score = scoreLetterHalfDraw('А', [reference]);

      expect(score.hasEnoughInk, isTrue);
      expect(score.similarityPercent, isNotNull);
      expect(score.similarityPercent!, greaterThanOrEqualTo(passSimilarityPercent));
      expect(isSuccessfulHalfDraw(score), isTrue);
    });

    test('scores low for a misplaced right-half trace', () {
      final score = scoreLetterHalfDraw('А', [
        [
          const TracePoint(x: 0.55, y: 0.25),
          const TracePoint(x: 0.7, y: 0.25),
          const TracePoint(x: 0.85, y: 0.25),
        ],
      ]);

      expect(score.similarityPercent, isNotNull);
      expect(score.similarityPercent!, lessThan(passSimilarityPercent));
      expect(isSuccessfulHalfDraw(score), isFalse);
    });

    test('ignores ink drawn only on the left side', () {
      final score = scoreLetterHalfDraw('А', [
        [
          const TracePoint(x: 0.25, y: 0.22),
          const TracePoint(x: 0.28, y: 0.5),
          const TracePoint(x: 0.32, y: 0.78),
        ],
      ]);

      expect(score.hasEnoughInk, isFalse);
      expect(score.similarityPercent, isNull);
    });
  });

  group('half draw pad sizing', () {
    test('matches trace pad square sizing', () {
      expect(halfDrawPadSize(800, 400), 340);
      expect(halfDrawPadSize(400, 800), 288);
    });

    test('uses centered split line in viewbox', () {
      expect(halfDrawSplitLineViewboxX(), halfDrawViewboxSize / 2);
    });
  });
}
