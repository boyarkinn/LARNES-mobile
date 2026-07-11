/// Детерминированный RNG для раскладки полей (порт web `createSeededRng` / `hashParamsSeed`).
import 'dart:math';

double Function() createSeededRng(int seed) {
  var state = _toUint32(seed);

  return () {
    state = _toUint32(state * 1664525 + 1013904223);
    return state / 4294967296;
  };
}

int hashParamsSeed(List<Object> parts) {
  var hash = 2166136261;

  for (final part in parts) {
    final text = part.toString();
    for (var index = 0; index < text.length; index++) {
      hash = _toUint32(hash ^ text.codeUnitAt(index));
      hash = _toUint32(hash * 16777619);
    }
  }

  return _toUint32(hash);
}

/// Соль раскладки — новое поле при каждом mount play-сцены (web `createLayoutSalt`).
int createLayoutSalt() {
  return (Random.secure().nextDouble() * 0x100000000).floor() & 0xFFFFFFFF;
}

int _toUint32(int value) => value & 0xFFFFFFFF;
