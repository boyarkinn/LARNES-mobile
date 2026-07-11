import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/reading/letter_connect_dots/connect_dots_model.dart';

ConnectDot _findDotNear(ConnectDotsPuzzle puzzle, double x, double y) {
  ConnectDot? dot;

  for (final item in puzzle.dots) {
    final dx = item.x - x;
    final dy = item.y - y;
    if (dx * dx + dy * dy < 0.0001) {
      dot = item;
      break;
    }
  }

  expect(dot, isNotNull, reason: 'dot near $x,$y');
  return dot!;
}

void main() {
  group('sampleConnectSegmentPoints', () {
    test('keeps only endpoints for straight segments', () {
      final sampled = sampleConnectSegmentPoints([
        const TracePoint(x: 0.2, y: 0.2),
        const TracePoint(x: 0.2, y: 0.5),
        const TracePoint(x: 0.2, y: 0.8),
      ]);

      expect(sampled.length, 2);
      expect(sampled[0].x, 0.2);
      expect(sampled[0].y, 0.2);
      expect(sampled[1].x, 0.2);
      expect(sampled[1].y, 0.8);
    });
  });

  group('buildLetterDotPuzzle', () {
    test('builds guide strokes and dots for letter E', () {
      final puzzle = buildLetterDotPuzzle('Е');

      expect(puzzle.guideStrokes.length, 4);
      expect(puzzle.dots.length, greaterThanOrEqualTo(4));
      expect(puzzle.edges.length, 4);
    });

    test('assigns sequential numbers in numbered mode data', () {
      final puzzle = buildLetterDotPuzzle('Е');
      final numbers = puzzle.dots
          .map((dot) => dot.number)
          .whereType<int>()
          .toList();

      expect(numbers, [...numbers]..sort());
      expect(numbers.first, 1);
    });
  });

  group('evaluateConnectShapeCoverage', () {
    test('accepts canonical edges in any order', () {
      final puzzle = buildLetterDotPuzzle('Е');
      final reversed = [...puzzle.edges.reversed];
      var drawn = <ConnectDrawnLine>[];

      for (final edge in reversed) {
        final result = addConnectDrawnLine(
          puzzle,
          drawn,
          edge.aId,
          edge.bId,
        );
        expect(result.line, isNotNull);
        drawn = result.nextDrawnLines;
      }

      expect(evaluateConnectShapeCoverage(puzzle, drawn).isSuccess, isTrue);
    });

    test('accepts spine split through the middle junction on letter E', () {
      final puzzle = buildLetterDotPuzzle('Е');
      final topLeft = _findDotNear(puzzle, 0.32, 0.22);
      final middleLeft = _findDotNear(puzzle, 0.32, 0.5);
      final bottomLeft = _findDotNear(puzzle, 0.32, 0.78);
      final topRight = _findDotNear(puzzle, 0.68, 0.22);
      final middleRight = _findDotNear(puzzle, 0.62, 0.5);
      final bottomRight = _findDotNear(puzzle, 0.62, 0.78);

      var drawn = addConnectDrawnLine(
        puzzle,
        [],
        topRight.id,
        topLeft.id,
      ).nextDrawnLines;
      drawn = addConnectDrawnLine(
        puzzle,
        drawn,
        topLeft.id,
        middleLeft.id,
      ).nextDrawnLines;
      drawn = addConnectDrawnLine(
        puzzle,
        drawn,
        middleLeft.id,
        bottomLeft.id,
      ).nextDrawnLines;
      drawn = addConnectDrawnLine(
        puzzle,
        drawn,
        middleLeft.id,
        middleRight.id,
      ).nextDrawnLines;
      drawn = addConnectDrawnLine(
        puzzle,
        drawn,
        bottomLeft.id,
        bottomRight.id,
      ).nextDrawnLines;

      expect(evaluateConnectShapeCoverage(puzzle, drawn).isSuccess, isTrue);
    });

    test('rejects extra diagonal lines', () {
      final puzzle = buildLetterDotPuzzle('Е');
      final topRight = _findDotNear(puzzle, 0.68, 0.22);
      final bottomLeft = _findDotNear(puzzle, 0.32, 0.78);
      final withWrong = addConnectDrawnLine(
        puzzle,
        [],
        topRight.id,
        bottomLeft.id,
      ).nextDrawnLines;

      expect(withWrong.first.onGuide, isFalse);
      expect(evaluateConnectShapeCoverage(puzzle, withWrong).isSuccess, isFalse);
    });

    test('rejects incomplete letter shape', () {
      final puzzle = buildLetterDotPuzzle('Е');
      final firstEdge = puzzle.edges.first;
      final partial = addConnectDrawnLine(
        puzzle,
        [],
        firstEdge.aId,
        firstEdge.bId,
      ).nextDrawnLines;

      expect(evaluateConnectShapeCoverage(puzzle, partial).isSuccess, isFalse);
      expect(
        evaluateConnectShapeCoverage(puzzle, partial).missingStrokeIds,
        isNotEmpty,
      );
    });
  });

  group('addConnectDrawnLinesFromPath', () {
    test('adds consecutive segments from a pattern path', () {
      final puzzle = buildLetterDotPuzzle('Е');
      final topLeft = _findDotNear(puzzle, 0.32, 0.22);
      final middleLeft = _findDotNear(puzzle, 0.32, 0.5);
      final bottomLeft = _findDotNear(puzzle, 0.32, 0.78);

      final drawn = addConnectDrawnLinesFromPath(puzzle, [], [
        topLeft.id,
        middleLeft.id,
        bottomLeft.id,
      ]);

      expect(drawn.length, 2);
      expect(drawn.every((line) => line.onGuide), isTrue);
    });
  });

  group('projectPointToConnectPolyline', () {
    test('projects junction points onto the spine stroke', () {
      final puzzle = buildLetterDotPuzzle('Е');
      ConnectGuideStroke? spine;
      for (final stroke in puzzle.guideStrokes) {
        if (stroke.id == 'guide-1') {
          spine = stroke;
          break;
        }
      }

      expect(spine, isNotNull);

      final projection = projectPointToConnectPolyline(
        const TracePoint(x: 0.32, y: 0.5),
        spine!.points,
      );

      expect(projection, isNotNull);
      expect(projection!.distance, lessThan(0.01));
    });
  });

  group('isNearlyStraightConnectSegment', () {
    test('detects straight polylines', () {
      expect(
        isNearlyStraightConnectSegment([
          const TracePoint(x: 0.1, y: 0.1),
          const TracePoint(x: 0.1, y: 0.5),
          const TracePoint(x: 0.1, y: 0.9),
        ]),
        isTrue,
      );
    });
  });

  group('getConnectEdgeKey', () {
    test('uses stable edge keys', () {
      expect(
        getConnectEdgeKey('dot-1', 'dot-2'),
        getConnectEdgeKey('dot-2', 'dot-1'),
      );
    });
  });
}
