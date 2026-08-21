/// Web: `platform/src/trainers/reading/stroop-colors/model.ts`

import 'dart:math' as math;

const stroopColorIds = [
  'red',
  'orange',
  'yellow',
  'green',
  'cyan',
  'blue',
  'violet',
];

typedef StroopColorId = String;

class StroopColorSwatch {
  const StroopColorSwatch({required this.hex, required this.label});

  final String hex;
  final String label;
}

class StroopColorItem {
  const StroopColorItem({required this.ink, required this.word});

  final StroopColorId ink;
  final StroopColorId word;
}

const stroopColors = <StroopColorId, StroopColorSwatch>{
  'red': StroopColorSwatch(hex: '#E53935', label: 'Красный'),
  'orange': StroopColorSwatch(hex: '#FB8C00', label: 'Оранжевый'),
  'yellow': StroopColorSwatch(hex: '#F9A825', label: 'Жёлтый'),
  'green': StroopColorSwatch(hex: '#43A047', label: 'Зелёный'),
  'cyan': StroopColorSwatch(hex: '#29B6F6', label: 'Голубой'),
  'blue': StroopColorSwatch(hex: '#1565C0', label: 'Синий'),
  'violet': StroopColorSwatch(hex: '#8E24AA', label: 'Фиолетовый'),
};

class GenerateStroopItemsInput {
  const GenerateStroopItemsInput({
    required this.wordCount,
    this.random,
  });

  final int wordCount;
  final double Function()? random;
}

int _chooseIndex(int length, double Function() random) {
  final normalized = random().clamp(0.0, 0.999999999);
  return (normalized * length).floor();
}

StroopColorId _pickColorId(
  double Function() random, [
  List<StroopColorId> exclude = const [],
]) {
  final pool = stroopColorIds.where((id) => !exclude.contains(id)).toList();
  final source = pool.isNotEmpty ? pool : stroopColorIds;
  return source[_chooseIndex(source.length, random)];
}

bool _isSamePair(StroopColorItem? left, StroopColorItem right) {
  return left?.ink == right.ink && left?.word == right.word;
}

List<StroopColorItem> generateStroopItems(GenerateStroopItemsInput input) {
  final random = input.random ?? _defaultRandom;
  final wordCount = input.wordCount;

  if (wordCount < 1) {
    throw ArgumentError('wordCount must be a positive integer.');
  }

  final items = <StroopColorItem>[];

  for (var index = 0; index < wordCount; index++) {
    late StroopColorItem next;
    var attempts = 0;

    do {
      final ink = _pickColorId(random);
      final word = _pickColorId(random, [ink]);
      next = StroopColorItem(ink: ink, word: word);
      attempts += 1;
    } while (items.isNotEmpty &&
        _isSamePair(items[index - 1], next) &&
        attempts < 24);

    if (items.isNotEmpty && _isSamePair(items[index - 1], next)) {
      final previous = items[index - 1];
      next = StroopColorItem(
        ink: previous.ink,
        word: _pickColorId(random, [previous.ink, previous.word]),
      );
    }

    items.add(next);
  }

  return items;
}

final _defaultRng = math.Random();

double _defaultRandom() => _defaultRng.nextDouble();
