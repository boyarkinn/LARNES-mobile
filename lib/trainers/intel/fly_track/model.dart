/// Web: `platform/src/trainers/intel/fly-track/model.ts`

import 'dart:math' as math;

const flyDirections = ['up', 'down', 'left', 'right'];
const flyDistances = [1, 2, 3, 4];

typedef FlyDirection = String;
typedef FlyDistance = int;

class FlyCell {
  const FlyCell({required this.row, required this.column});

  final int row;
  final int column;

  @override
  bool operator ==(Object other) {
    return other is FlyCell && other.row == row && other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}

class FlyStep {
  const FlyStep({required this.direction, required this.distance});

  final FlyDirection direction;
  final FlyDistance distance;
}

class FlyTrackRound {
  const FlyTrackRound({
    required this.finish,
    required this.path,
    required this.start,
    required this.steps,
  });

  final FlyCell start;
  final List<FlyStep> steps;
  final List<FlyCell> path;
  final FlyCell finish;
}

class GenerateFlyTrackRoundInput {
  const GenerateFlyTrackRoundInput({
    required this.gridSize,
    required this.stepCount,
    this.random,
  });

  final int gridSize;
  final int stepCount;
  final double Function()? random;
}

class GenerateFlyTrackRoundsInput extends GenerateFlyTrackRoundInput {
  const GenerateFlyTrackRoundsInput({
    required super.gridSize,
    required super.stepCount,
    required this.rounds,
    super.random,
  });

  final int rounds;
}

const _directionDeltas = <FlyDirection, FlyCell>{
  'up': FlyCell(row: -1, column: 0),
  'down': FlyCell(row: 1, column: 0),
  'left': FlyCell(row: 0, column: -1),
  'right': FlyCell(row: 0, column: 1),
};

const _distanceWeights = <FlyDistance, double>{
  1: 0.52,
  2: 0.26,
  3: 0.14,
  4: 0.08,
};

void _assertPositiveInteger(int value, String label) {
  if (value < 1) {
    throw ArgumentError('$label must be a positive integer.');
  }
}

int _chooseIndex(int length, double Function() random) {
  final normalized = math.min(math.max(random(), 0), 0.999999999);
  return (normalized * length).floor();
}

FlyDistance _chooseWeightedDistance(
  List<FlyDistance> distances,
  double Function() random,
) {
  final totalWeight = distances.fold<double>(
    0,
    (sum, distance) => sum + _distanceWeights[distance]!,
  );
  var threshold = math.min(math.max(random(), 0), 0.999999999) * totalWeight;

  for (final distance in distances) {
    threshold -= _distanceWeights[distance]!;
    if (threshold < 0) {
      return distance;
    }
  }

  return distances.last;
}

bool isFlyCellInGrid(FlyCell cell, int gridSize) {
  return cell.row >= 0 &&
      cell.row < gridSize &&
      cell.column >= 0 &&
      cell.column < gridSize;
}

FlyCell moveFly(
  FlyCell cell,
  FlyDirection direction, [
  FlyDistance distance = 1,
]) {
  final delta = _directionDeltas[direction]!;

  return FlyCell(
    row: cell.row + delta.row * distance,
    column: cell.column + delta.column * distance,
  );
}

List<FlyDirection> validFlyDirections(FlyCell cell, int gridSize) {
  return flyDirections
      .where((direction) => isFlyCellInGrid(moveFly(cell, direction), gridSize))
      .toList(growable: false);
}

List<FlyDistance> validFlyDistances(
  FlyCell cell,
  FlyDirection direction,
  int gridSize,
) {
  return flyDistances
      .where(
        (distance) =>
            isFlyCellInGrid(moveFly(cell, direction, distance), gridSize),
      )
      .toList(growable: false);
}

FlyTrackRound generateFlyTrackRound(GenerateFlyTrackRoundInput input) {
  _assertPositiveInteger(input.gridSize, 'gridSize');
  _assertPositiveInteger(input.stepCount, 'stepCount');

  final random = input.random ?? math.Random().nextDouble;
  final start = FlyCell(
    row: _chooseIndex(input.gridSize, random),
    column: _chooseIndex(input.gridSize, random),
  );
  final steps = <FlyStep>[];
  final path = <FlyCell>[start];
  var current = start;

  for (var index = 0; index < input.stepCount; index++) {
    final directions = validFlyDirections(current, input.gridSize);
    final direction = directions[_chooseIndex(directions.length, random)];
    final distances = validFlyDistances(current, direction, input.gridSize);
    final distance = _chooseWeightedDistance(distances, random);

    current = moveFly(current, direction, distance);
    steps.add(FlyStep(direction: direction, distance: distance));
    path.add(current);
  }

  return FlyTrackRound(
    start: start,
    steps: steps,
    path: path,
    finish: current,
  );
}

String _flyTrackRoundSignature(FlyTrackRound round) {
  final steps = round.steps.map((step) => '${step.direction}:${step.distance}').join(',');
  return '${round.start.row}:${round.start.column}:$steps';
}

List<FlyTrackRound> generateFlyTrackRounds(GenerateFlyTrackRoundsInput input) {
  _assertPositiveInteger(input.rounds, 'rounds');

  final result = <FlyTrackRound>[];
  final seen = <String>{};
  final maxAttempts = input.rounds * 100;
  final random = input.random ?? math.Random().nextDouble;

  for (var attempts = 0; result.length < input.rounds && attempts < maxAttempts; attempts++) {
    final round = generateFlyTrackRound(
      GenerateFlyTrackRoundInput(
        gridSize: input.gridSize,
        stepCount: input.stepCount,
        random: random,
      ),
    );
    final signature = _flyTrackRoundSignature(round);

    if (!seen.contains(signature)) {
      seen.add(signature);
      result.add(round);
    }
  }

  if (result.length != input.rounds) {
    throw StateError('Could not generate unique fly-track rounds.');
  }

  return result;
}

/// Deterministic RNG for tests (port of web model.test.ts seededRandom).
double Function() seededRandom(int seed) {
  var state = seed >>> 0;

  return () {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 4294967296;
  };
}
