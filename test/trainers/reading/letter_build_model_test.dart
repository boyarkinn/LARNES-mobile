import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/letter_build_model.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/path_geometry.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_sticks.dart';

void main() {
  group('letter-build zaitsev catalog', () {
    test('keeps Tse and De bases flush with their vertical corner strokes', () {
      for (final letter in ['Ц', 'Д']) {
        final pieces = getLetterBuildPieces(letter);
        final left = pieces[letter == 'Ц' ? 0 : 3];
        final right = pieces[letter == 'Ц' ? 3 : 4];
        final base = pieces[2];
        expect(base.bounds.minX, closeTo(left.bounds.minX, 1e-7));
        expect(base.bounds.maxX, closeTo(right.bounds.minX, 1e-7));
        expect(base.bounds.minY, closeTo(right.bounds.minY, 1e-7));
      }
    });

    test('ends the U branch on its main quadratic curve', () {
      final pieces = getLetterBuildPieces('У');
      final branch = sampleSvgPath(pieces[1].path);
      final curve = sampleSvgPath(pieces[0].path, curveSteps: 1000);
      final distance = curve.map((point) => distancePoint(point, branch.last))
          .reduce((a, b) => a < b ? a : b);
      expect(distance, lessThan(1e-7));
      expect(branch.first.y, closeTo(curve.first.y, 1e-7));
    });

    test('draws O as one centered closed ellipse', () {
      final piece = getLetterBuildPieces('О').single;
      final points = sampleSvgPath(piece.path, curveSteps: 64);
      for (final point in points) {
        final x = (point.x * zaitsevCoordSize - 175) / 110;
        final y = (point.y * zaitsevCoordSize - 190) / 130;
        expect(x * x + y * y, closeTo(1, 1e-7));
      }
      expect(points.first.x, closeTo(points.last.x, 1e-7));
      expect(points.first.y, closeTo(points.last.y, 1e-7));
      expect(piece.bounds.minY, closeTo(60, 1e-7));
      expect(piece.bounds.maxY, closeTo(320, 1e-7));
    });

    test('keeps every initial piece inside the field and beside the outline', () {
      for (final letter in listSupportedBuildLetters()) {
        final pieces = getLetterBuildPieces(letter);
        final layout = getBuildLayout(letter)!;
        final outlineMin = pieces.map((piece) => piece.bounds.minX).reduce((a, b) => a < b ? a : b);
        final outlineMax = pieces.map((piece) => piece.bounds.maxX).reduce((a, b) => a > b ? a : b);
        for (final piece in pieces) {
          final left = piece.bounds.minX + piece.paletteOffset.x * zaitsevCoordSize - layout.padding;
          final right = piece.bounds.maxX + piece.paletteOffset.x * zaitsevCoordSize + layout.padding;
          final top = piece.bounds.minY + piece.paletteOffset.y * zaitsevCoordSize - layout.padding;
          final bottom = piece.bounds.maxY + piece.paletteOffset.y * zaitsevCoordSize + layout.padding;
          expect(left >= layout.minX && right <= layout.maxX, isTrue);
          expect(top >= layout.minY && bottom <= layout.maxY, isTrue);
          expect(right < outlineMin || left > outlineMax, isTrue);
          final constrained = constrainBuildPlacement(piece,
              PiecePlacement(id: piece.id, offset: const TracePoint(x: 100, y: -100), snapped: false), layout);
          expect(piece.bounds.maxX + constrained.offset.x * zaitsevCoordSize,
              lessThanOrEqualTo(layout.maxX - layout.padding + 1e-6));
          expect(piece.bounds.minY + constrained.offset.y * zaitsevCoordSize,
              greaterThanOrEqualTo(layout.minY + layout.padding - 1e-6));
        }
      }
    });

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
    test('keeps the corrected Ve lobes interchangeable', () {
      final pieces = getLetterBuildPieces('В');
      expect(areBuildPiecesInterchangeable(pieces[1], pieces[2]), isTrue);
    });

    List<PiecePlacement> moveToTarget(
      List<StickPieceDef> pieces,
      List<PiecePlacement> placements,
      int source,
      int target,
    ) {
      return [
        for (final placement in placements)
          if (placement.id == pieces[source].id)
            placement.copyWith(offset: TracePoint(
              x: pieces[target].centroid.x - pieces[source].centroid.x,
              y: pieces[target].centroid.y - pieces[source].centroid.y,
            ))
          else
            placement,
      ];
    }

    test('accepts each E horizontal piece in every horizontal slot', () {
      final pieces = getLetterBuildPieces('Е');
      for (final source in [1, 2, 3]) {
        for (final target in [1, 2, 3]) {
          final initial = createInitialPlacements(pieces);
          final moved = moveToTarget(pieces, initial, source, target);
          final result = snapBuildPiece(pieces, moved, pieces[source].id);
          expect(result.where((placement) => placement.snapped).length, 1);
          expect(result[target].snapped, isTrue);
          expect(result[target].offset.x, 0);
          expect(result[target].offset.y, 0);
          if (source != target) {
            expect(result[source].snapped, isFalse);
            expect(result[source].offset.x + pieces[source].centroid.x,
                closeTo(initial[target].offset.x + pieces[target].centroid.x, 1e-6));
            expect(result[source].offset.y + pieces[source].centroid.y,
                closeTo(initial[target].offset.y + pieces[target].centroid.y, 1e-6));
          }
        }
      }
    });

    test('finishes E in every order of horizontal slots', () {
      final pieces = getLetterBuildPieces('Е');
      for (final targets in [
        [1, 2, 3], [1, 3, 2], [2, 1, 3],
        [2, 3, 1], [3, 1, 2], [3, 2, 1],
      ]) {
        var placements = snapBuildPiece(pieces,
            moveToTarget(pieces, createInitialPlacements(pieces), 0, 0), pieces[0].id);
        for (final target in targets) {
          final source = placements.indexWhere((placement) =>
              placement.id != pieces[0].id && !placement.snapped);
          placements = snapBuildPiece(pieces,
              moveToTarget(pieces, placements, source, target), pieces[source].id);
        }
        expect(isGuidePhaseComplete(pieces, placements), isTrue);
      }
    });

    test('swaps Yo dots without accepting an occupied slot twice', () {
      final pieces = getLetterBuildPieces('Ё');
      var placements = createInitialPlacements(pieces);
      expect(areBuildPiecesInterchangeable(pieces[4], pieces[5]), isTrue);
      placements = snapBuildPiece(pieces,
          moveToTarget(pieces, placements, 4, 5), pieces[4].id);
      expect(placements[5].snapped, isTrue);
      final duplicate = moveToTarget(pieces, placements, 4, 5);
      expect(snapBuildPiece(pieces, duplicate, pieces[4].id), same(duplicate));
      placements = snapBuildPiece(pieces,
          moveToTarget(pieces, placements, 4, 4), pieces[4].id);
      expect(placements.where((placement) => placement.snapped).length, 2);
      expect(isGuidePhaseComplete(pieces, placements), isFalse);
    });

    test('rejects a vertical E stroke on a horizontal slot and distant drops', () {
      final pieces = getLetterBuildPieces('Е');
      expect(areBuildPiecesInterchangeable(pieces[0], pieces[1]), isFalse);
      final initial = createInitialPlacements(pieces);
      expect(snapBuildPiece(pieces, initial, pieces[1].id), same(initial));
      final moved = moveToTarget(pieces, initial, 0, 1);
      expect(snapBuildPiece(pieces, moved, pieces[0].id), same(moved));
    });

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
