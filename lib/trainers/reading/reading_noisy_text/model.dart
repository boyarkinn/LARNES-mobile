import 'package:characters/characters.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingNoiseValues = [
  'strokes',
  'extra-letters',
  'extra-words',
  'zigzag',
  'circle',
  'wave',
  'flip',
];

const _extraLetters = ['х', 'щ', 'ъ', 'э'];
const _extraWords = ['ну', 'вот', 'же'];

class NoisyUnit {
  const NoisyUnit({
    required this.grapheme,
    required this.noise,
    required this.order,
    required this.turned,
  });

  final String grapheme;
  final bool noise;
  final int order;
  final bool turned;
}

List<NoisyUnit> buildNoisyUnits(String text, String noise) {
  final source = buildVanishUnits(text)
      .map(
        (unit) => NoisyUnit(
          grapheme: unit.grapheme,
          noise: false,
          order: unit.order,
          turned: false,
        ),
      )
      .toList();

  if (noise == 'extra-letters') {
    final mixed = <NoisyUnit>[];
    var extra = 0;
    for (final unit in source) {
      mixed.add(unit);
      if (isLetterGrapheme(unit.grapheme)) {
        mixed.add(
          NoisyUnit(
            grapheme: _extraLetters[extra % _extraLetters.length],
            noise: true,
            order: 0,
            turned: false,
          ),
        );
        extra += 1;
      }
    }
    return mixed;
  }

  if (noise == 'extra-words') {
    final mixed = <NoisyUnit>[];
    var extra = 0;
    for (final unit in source) {
      mixed.add(unit);
      if (unit.grapheme == ' ') {
        final word = _extraWords[extra % _extraWords.length];
        extra += 1;
        for (final grapheme in word.characters) {
          mixed.add(NoisyUnit(grapheme: grapheme, noise: true, order: 0, turned: false));
        }
        mixed.add(const NoisyUnit(grapheme: ' ', noise: true, order: 0, turned: false));
      }
    }
    return mixed;
  }

  if (noise != 'flip') return source;

  var word = 0;
  var atWordStart = true;
  return [
    for (final unit in source)
      () {
        if (unit.grapheme.trim().isEmpty) {
          atWordStart = true;
          return unit;
        }
        if (atWordStart) {
          word += 1;
          atWordStart = false;
        }
        return NoisyUnit(
          grapheme: unit.grapheme,
          noise: false,
          order: unit.order,
          turned: word.isEven,
        );
      }(),
  ];
}

int noisyLetterCount(List<NoisyUnit> units) {
  var maxOrder = 0;
  for (final unit in units) {
    if (!unit.noise && unit.order > maxOrder) maxOrder = unit.order;
  }
  return maxOrder;
}

class ReadingNoisyTextPlan {
  const ReadingNoisyTextPlan({
    required this.letterPauseMs,
    required this.noise,
    required this.text,
    required this.units,
  });

  final int letterPauseMs;
  final String noise;
  final String text;
  final List<NoisyUnit> units;

  int get letterCount => noisyLetterCount(units);
}

String normalizeNoise(Object? raw) {
  final noise = raw?.toString() ?? 'strokes';
  return readingNoiseValues.contains(noise) ? noise : 'strokes';
}

String? validateReadingNoisyTextRaw(Map<String, dynamic> raw) {
  final passageError = validatePassageAssignment(raw);
  if (passageError != null) return passageError;
  final noise = raw['noise']?.toString() ?? 'strokes';
  if (!readingNoiseValues.contains(noise)) return 'Выберите помеху.';
  return null;
}

ReadingNoisyTextPlan readingNoisyTextPlanFromText({
  required int letterPauseMs,
  required String noise,
  required String text,
}) {
  return ReadingNoisyTextPlan(
    letterPauseMs: letterPauseMs,
    noise: noise,
    text: text,
    units: buildNoisyUnits(text, noise),
  );
}

ReadingNoisyTextPlan readingNoisyTextPlanFromParams(Map<String, dynamic> raw) {
  final play = passagePlayFromParams(raw);
  return readingNoisyTextPlanFromText(
    letterPauseMs: play.letterPauseMs,
    noise: normalizeNoise(raw['noise']),
    text: play.text,
  );
}

ReadingNoisyTextPlan? readingNoisyTextPlanFromSnapshot(Map<String, dynamic>? payload) {
  final play = passagePlayFromSnapshot(payload);
  if (play == null || payload == null) return null;
  final noise = payload['noise']?.toString();
  if (noise == null || !readingNoiseValues.contains(noise)) return null;
  return readingNoisyTextPlanFromText(
    letterPauseMs: play.letterPauseMs,
    noise: noise,
    text: play.text,
  );
}
