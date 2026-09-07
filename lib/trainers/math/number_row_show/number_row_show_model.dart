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
  final positions = <ScatterPosition>[];

  for (var index = 0; index < count; index++) {
    rngState = (rngState * 1664525 + 1013904223) & 0xFFFFFFFF;
    final xRng = rngState / 4294967296;
    rngState = (rngState * 1664525 + 1013904223) & 0xFFFFFFFF;
    final yRng = rngState / 4294967296;
    final above = index.isEven;

    positions.add(
      ScatterPosition(
        xPercent: 10 + xRng * 80,
        yPercent: above ? 8 + yRng * 24 : 68 + yRng * 20,
      ),
    );
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
