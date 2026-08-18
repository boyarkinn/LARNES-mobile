import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/model.dart';

void main() {
  group('fly-track model', () {
    test('returns only movements that remain inside the grid', () {
      const gridSize = 3;
      final round = generateFlyTrackRound(
        GenerateFlyTrackRoundInput(
          gridSize: gridSize,
          random: seededRandom(42),
          stepCount: 20,
        ),
      );

      expect(round.steps.length, 20);
      expect(round.path.length, 21);
      expect(round.start, round.path.first);
      expect(round.finish, round.path.last);
      expect(
        round.path.every((cell) => isFlyCellInGrid(cell, gridSize)),
        isTrue,
      );

      for (var index = 0; index < round.steps.length; index++) {
        final step = round.steps[index];
        expect(
          moveFly(round.path[index], step.direction, step.distance),
          round.path[index + 1],
        );
        expect(step.distance, inInclusiveRange(1, 4));
      }
    });

    test('allows returning to a previously visited cell', () {
      const cell = FlyCell(row: 1, column: 1);

      expect(validFlyDirections(cell, 3), ['up', 'down', 'left', 'right']);
      expect(moveFly(moveFly(cell, 'up'), 'down'), cell);
    });

    test('offers only jump distances that remain inside the grid', () {
      expect(
        validFlyDistances(const FlyCell(row: 4, column: 1), 'up', 5),
        [1, 2, 3, 4],
      );
      expect(
        validFlyDistances(const FlyCell(row: 3, column: 1), 'up', 4),
        [1, 2, 3],
      );
      expect(
        validFlyDistances(const FlyCell(row: 1, column: 1), 'up', 4),
        [1],
      );
      expect(
        validFlyDistances(const FlyCell(row: 0, column: 0), 'right', 3),
        [1, 2],
      );
    });

    test('can generate jumps longer than one cell', () {
      final round = generateFlyTrackRound(
        GenerateFlyTrackRoundInput(
          gridSize: 8,
          random: seededRandom(7),
          stepCount: 50,
        ),
      );

      expect(round.steps.any((step) => step.distance > 1), isTrue);
      expect(
        round.path.every((cell) => isFlyCellInGrid(cell, 8)),
        isTrue,
      );
    });

    test('can generate a four-cell jump on a large grid', () {
      final round = generateFlyTrackRound(
        GenerateFlyTrackRoundInput(
          gridSize: 8,
          random: seededRandom(11),
          stepCount: 80,
        ),
      );

      expect(round.steps.any((step) => step.distance == 4), isTrue);
      expect(
        round.path.every((cell) => isFlyCellInGrid(cell, 8)),
        isTrue,
      );
    });

    test('creates distinct random rounds for one trainer run', () {
      final rounds = generateFlyTrackRounds(
        GenerateFlyTrackRoundsInput(
          gridSize: 4,
          random: seededRandom(20260817),
          rounds: 5,
          stepCount: 5,
        ),
      );
      final signatures = rounds
          .map(
            (round) =>
                '${round.start.row}:${round.start.column}:${round.steps.map((step) => '${step.direction}:${step.distance}').join(',')}',
          )
          .toList();

      expect(rounds.length, 5);
      expect(signatures.toSet().length, 5);
    });
  });
}
