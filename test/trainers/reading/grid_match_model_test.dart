import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_model.dart';

void main() {
  group('buildGridCells', () {
    test('creates a square grid', () {
      expect(buildGridCells(3).length, 9);
      expect(buildGridCells(2).length, 4);
    });
  });

  group('isValidFilledCount', () {
    test('accepts counts within the grid', () {
      expect(isValidFilledCount(3, 5), isTrue);
      expect(isValidFilledCount(2, 4), isTrue);
    });

    test('rejects overflow', () {
      expect(isValidFilledCount(2, 5), isFalse);
    });
  });

  group('buildGridRound', () {
    test('fills the requested number of cells and builds a matching pool', () {
      final round = buildGridRound(
        filledCount: 4,
        gridSize: 3,
        letterCase: 'upper',
        practiceLetters: ['А', 'М', 'К'],
        seed: 42,
      );

      final filledReference =
          round.reference.values.where((letter) => letter != null).toList();

      expect(getCellCount(round.gridSize), 9);
      expect(filledReference.length, 4);
      expect(round.poolTiles.length, 4);
      expect(
        round.poolTiles.map((tile) => tile.letter).toList()..sort(),
        filledReference.cast<String>().toList()..sort(),
      );
    });

    test('is deterministic for the same seed', () {
      final first = buildGridRound(
        filledCount: 3,
        gridSize: 2,
        letterCase: 'lower',
        practiceLetters: ['А', 'Б'],
        seed: 7,
      );
      final second = buildGridRound(
        filledCount: 3,
        gridSize: 2,
        letterCase: 'lower',
        practiceLetters: ['А', 'Б'],
        seed: 7,
      );

      expect(first.reference, second.reference);
      expect(
        first.poolTiles.map((tile) => tile.letter).toList(),
        second.poolTiles.map((tile) => tile.letter).toList(),
      );
    });
  });

  group('isGridMatch', () {
    test('returns true only for identical cell maps', () {
      const reference = {
        'cell-0-0': 'А',
        'cell-0-1': null,
        'cell-1-0': 'М',
        'cell-1-1': null,
      };

      expect(
        isGridMatch(reference, {
          'cell-0-0': 'А',
          'cell-0-1': null,
          'cell-1-0': 'М',
          'cell-1-1': null,
        }),
        isTrue,
      );
      expect(
        isGridMatch(reference, {
          'cell-0-0': 'А',
          'cell-0-1': null,
          'cell-1-0': null,
          'cell-1-1': 'М',
        }),
        isFalse,
      );
    });
  });

  group('buildRoundSeed', () {
    test('includes trainer key in hash', () {
      expect(
        buildRoundSeed(['А', 3, 4]),
        buildRoundSeed(['А', 3, 4]),
      );
      expect(
        buildRoundSeed(['А', 3, 4]),
        isNot(buildRoundSeed(['Б', 3, 4])),
      );
    });
  });
}
