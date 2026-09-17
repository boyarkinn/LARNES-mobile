const minStudyDigit = 1;
const maxStudyDigit = 9;

const minStepPauseSec = 0.5;
const maxStepPauseSec = 3.0;
const defaultStepPauseSec = 1.0;

class ScatterPosition {
  const ScatterPosition({required this.xPercent, required this.yPercent});

  final double xPercent;
  final double yPercent;
}

const scatterChipMinWidthPercent = 20.0;
const scatterChipMinHeightPercent = 32.0;
const _scatterPlacementMaxAttempts = 48;

({double height, double width}) scatterChipFootprint(int count) {
  if (count <= 5) {
    return (width: scatterChipMinWidthPercent, height: scatterChipMinHeightPercent);
  }
  if (count <= 7) {
    return (width: 18, height: 28);
  }
  return (width: 14, height: 22);
}

List<T> _shuffleScatterCandidates<T>(List<T> items, double Function() rng) {
  final next = [...items];

  for (var index = next.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = next[index];
    next[index] = next[swapIndex];
    next[swapIndex] = temp;
  }

  return next;
}

List<ScatterPosition> _buildReserveScatterCandidates(
  int count,
  double Function() rng,
) {
  final footprint = scatterChipFootprint(count);
  final candidates = <ScatterPosition>[];

  for (var y = 10.0; y <= 86.0; y += footprint.height * 0.92) {
    for (var x = 12.0; x <= 88.0; x += footprint.width * 0.92) {
      candidates.add(
        ScatterPosition(
          xPercent: x + (rng() - 0.5) * 5,
          yPercent: y + (rng() - 0.5) * 5,
        ),
      );
    }
  }

  return _shuffleScatterCandidates(candidates, rng);
}

bool scatterPositionsOverlap(
  ScatterPosition first,
  ScatterPosition second, {
  double chipWidthPercent = scatterChipMinWidthPercent,
  double chipHeightPercent = scatterChipMinHeightPercent,
}) {
  return (first.xPercent - second.xPercent).abs() < chipWidthPercent &&
      (first.yPercent - second.yPercent).abs() < chipHeightPercent;
}

bool _hasScatterOverlap(
  ScatterPosition candidate,
  List<ScatterPosition> placed,
  double chipWidthPercent,
  double chipHeightPercent,
) {
  for (final position in placed) {
    if (scatterPositionsOverlap(
      candidate,
      position,
      chipWidthPercent: chipWidthPercent,
      chipHeightPercent: chipHeightPercent,
    )) {
      return true;
    }
  }
  return false;
}

bool _pickScatterBand(int index, List<ScatterPosition> placed) {
  final aboveCount = placed.where((position) => position.yPercent < 50).length;
  final belowCount = placed.length - aboveCount;

  if (aboveCount < belowCount) {
    return true;
  }
  if (belowCount < aboveCount) {
    return false;
  }
  return index.isEven;
}

ScatterPosition _randomScatterPosition(bool above, double Function() rng) {
  return ScatterPosition(
    xPercent: 10 + rng() * 80,
    yPercent: above ? 8 + rng() * 24 : 68 + rng() * 20,
  );
}

ScatterPosition? _tryRandomScatterPosition(
  bool above,
  List<ScatterPosition> placed,
  double Function() rng,
  double chipWidthPercent,
  double chipHeightPercent,
) {
  for (var attempt = 0; attempt < _scatterPlacementMaxAttempts; attempt++) {
    final candidate = _randomScatterPosition(above, rng);
    if (!_hasScatterOverlap(
      candidate,
      placed,
      chipWidthPercent,
      chipHeightPercent,
    )) {
      return candidate;
    }
  }
  return null;
}

ScatterPosition? _forceScatterPosition(
  List<ScatterPosition> placed,
  List<ScatterPosition> reserveCandidates,
  double chipWidthPercent,
  double chipHeightPercent,
) {
  for (final candidate in reserveCandidates) {
    if (!_hasScatterOverlap(
      candidate,
      placed,
      chipWidthPercent,
      chipHeightPercent,
    )) {
      return candidate;
    }
  }

  for (var y = 8.0; y <= 88.0; y += 1) {
    for (var x = 10.0; x <= 90.0; x += 1) {
      final candidate = ScatterPosition(xPercent: x, yPercent: y);
      if (!_hasScatterOverlap(
        candidate,
        placed,
        chipWidthPercent,
        chipHeightPercent,
      )) {
        return candidate;
      }
    }
  }

  return null;
}

int normalizeStudyDigit(num digit) {
  if (!digit.isFinite) {
    return minStudyDigit;
  }
  final value = digit.truncate();
  if (value <= minStudyDigit) {
    return minStudyDigit;
  }
  if (value >= maxStudyDigit) {
    return maxStudyDigit;
  }
  return value;
}

double normalizeStepPauseSec(Object? value) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) {
    return defaultStepPauseSec;
  }
  return parsed.clamp(minStepPauseSec, maxStepPauseSec);
}

List<int> getRowDigits(int studyDigit) {
  final end = normalizeStudyDigit(studyDigit);
  return List<int>.generate(end + 1, (index) => index);
}

bool isStudyDigit(int value, int studyDigit) {
  return value == normalizeStudyDigit(studyDigit);
}

int _hashParamsSeed(List<Object> parts) {
  var hash = 2166136261;
  for (final part in parts) {
    final text = '$part';
    for (var index = 0; index < text.length; index++) {
      hash ^= text.codeUnitAt(index);
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
  }
  return hash;
}

List<ScatterPosition> buildScatterPositions(int count, int seed) {
  if (count <= 0) {
    return const [];
  }

  var rngState = seed;
  double rng() {
    rngState = (rngState * 1664525 + 1013904223) & 0xFFFFFFFF;
    return rngState / 4294967296;
  }

  final positions = <ScatterPosition>[];
  final footprint = scatterChipFootprint(count);
  final reserveCandidates = _buildReserveScatterCandidates(count, rng);
  final usedReserve = <int>{};

  for (var index = 0; index < count; index++) {
    final above = _pickScatterBand(index, positions);
    var candidate =
        _tryRandomScatterPosition(
          above,
          positions,
          rng,
          footprint.width,
          footprint.height,
        ) ??
        _forceScatterPosition(
          positions,
          [
            for (var reserveIndex = 0; reserveIndex < reserveCandidates.length; reserveIndex++)
              if (!usedReserve.contains(reserveIndex))
                reserveCandidates[reserveIndex],
          ],
          footprint.width,
          footprint.height,
        );

    if (candidate == null) {
      for (var reserveIndex = 0; reserveIndex < reserveCandidates.length; reserveIndex++) {
        final reserve = reserveCandidates[reserveIndex];
        if (!usedReserve.contains(reserveIndex) &&
            !_hasScatterOverlap(
              reserve,
              positions,
              footprint.width,
              footprint.height,
            )) {
          candidate = reserve;
          break;
        }
      }
      candidate ??= reserveCandidates[index % reserveCandidates.length];
    }

    final reserveIndex = reserveCandidates.indexOf(candidate);
    if (reserveIndex >= 0) {
      usedReserve.add(reserveIndex);
    }

    positions.add(candidate);
  }

  return positions;
}

int buildScatterSeed(int studyDigit, double stepPauseSec) {
  return _hashParamsSeed([studyDigit, stepPauseSec, 'number-row-show-scatter']);
}

bool isRowComplete(Set<int> placedDigits, int studyDigit) {
  final row = getRowDigits(studyDigit);
  return row.every(placedDigits.contains);
}
