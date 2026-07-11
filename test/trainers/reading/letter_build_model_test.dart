import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/letter_build_model.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/path_geometry.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_sticks.dart';

void main() {
  group('letter-build zaitsev catalog', () {
    test('includes all catalog letters', () {
      final letters = listSupportedBuildLetters();

      expect(letters.contains('А'), isTrue);
      expect(letters.contains('О'), isTrue);
      expect(letters.contains('Ё'), isTrue);
      expect(letters.contains('Ъ'), isTrue);
      expect(letters.length, 33);
    });

    test('includes А with three zaitsev sticks', () {
      expect(getLetterBuildPieces('А').length, 3);
    });

    test('includes curved О with one stick path', () {
      expect(getLetterBuildPieces('О').length, 1);
    });

    test('uses legacy apex coordinates for А left leg', () {
      final parsed = parseStraightStrokePath('M 175 40 L 60 320');

      expect(parsed, isNotNull);
      expect(parsed!.a.x, closeTo(0.5, 0.01));
      expect(parsed.a.y, closeTo(40 / 350, 0.01));
    });

    test('computes centroid for arc stroke', () {
      final centroid = getPathCentroid('M 175 40 A 120 130 0 1 1 174.9 40 Z');

      expect(centroid.x, inInclusiveRange(0.2, 0.8));
      expect(centroid.y, inInclusiveRange(0.1, 0.9));
    });
  });

  group('guide snap', () {
    test('snaps when piece is on target', () {
      final pieces = getLetterBuildPieces('А');
      final piece = pieces.first;
      final placement = PiecePlacement(
        id: piece.id,
        offset: TracePoint(x: 0, y: 0),
        snapped: false,
      );

      expect(canSnapPiece(piece, placement), isTrue);

      final allSnapped = [
        for (final stick in pieces)
          snapPiece(
            stick,
            PiecePlacement(
              id: stick.id,
              offset: TracePoint(x: 0, y: 0),
              snapped: false,
            ),
          ),
      ];

      expect(isGuidePhaseComplete(pieces, allSnapped), isTrue);
    });

    test('starts pieces in palette offsets', () {
      final pieces = getLetterBuildPieces('А');
      final placements = createInitialPlacements(pieces);

      expect(placements.first.offset.x == 0 && placements.first.offset.y == 0,
          isFalse);
    });
  });

  group('scoreBuildPlacements', () {
    test('scores a perfect assembly highly', () {
      final pieces = getLetterBuildPieces('А');
      final placements = [
        for (final piece in pieces)
          PiecePlacement(
            id: piece.id,
            offset: TracePoint(x: 0, y: 0),
            snapped: true,
          ),
      ];

      final result = scoreBuildPlacements('А', placements);

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, greaterThanOrEqualTo(95));
    });
  });
}
