import 'dart:math' as math;

Map<String, dynamic>? readTrainerRuntimeSnapshot(
  String trainerKey,
  Map<String, dynamic> params,
) {
  final raw = params['__runtimeSnapshot'];
  if (raw is! Map) return null;
  final snapshot = Map<String, dynamic>.from(raw);
  if (snapshot['version'] != 1 ||
      snapshot['trainerKey'] != trainerKey ||
      snapshot['mode'] != 'materialized') {
    return null;
  }
  final payload = snapshot['payload'];
  return payload is Map ? Map<String, dynamic>.from(payload) : null;
}

int? readTrainerSnapshotSeed(
  String trainerKey,
  Map<String, dynamic> params,
) {
  final payload = readTrainerRuntimeSnapshot(trainerKey, params);
  final seed = payload?['seed'];
  return seed is num ? seed.toInt() & 0xffffffff : null;
}

/// Mulberry32 parity with Web runtime snapshot version 1.
class TrainerSnapshotRandom implements math.Random {
  TrainerSnapshotRandom(int seed) : _state = seed & 0xffffffff;

  int _state;

  double _nextUnit() {
    _state = (_state + 0x6d2b79f5) & 0xffffffff;
    var value = _state;
    value = _imul32(value ^ (value >>> 15), value | 1);
    value ^= value + _imul32(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) & 0xffffffff) / 4294967296;
  }

  static int _imul32(int left, int right) =>
      (left * right).toSigned(32).toUnsigned(32);

  @override
  bool nextBool() => _nextUnit() < 0.5;

  @override
  double nextDouble() => _nextUnit();

  @override
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max');
    return (_nextUnit() * max).floor();
  }
}

