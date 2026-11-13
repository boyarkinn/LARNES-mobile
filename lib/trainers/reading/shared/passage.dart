import 'package:characters/characters.dart';
import 'content_bank.dart';

class ReadingPassageQuestion {
  const ReadingPassageQuestion({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> choices;
  final int correctIndex;
}

// Material bodies are resolved by the server and read from frozen snapshots.
const defaultPassageId = '';

class VanishUnit {
  const VanishUnit({required this.grapheme, required this.order});

  final String grapheme;
  final int order;
}

final letterGraphemePattern = RegExp(r'\p{L}', unicode: true);

bool isLetterGrapheme(String grapheme) =>
    letterGraphemePattern.hasMatch(grapheme);

List<VanishUnit> buildVanishUnits(String text) {
  final units = <VanishUnit>[];
  final leading = <String>[];
  var order = 0;

  for (final grapheme in text.characters) {
    if (!isLetterGrapheme(grapheme)) {
      if (order == 0) {
        leading.add(grapheme);
      } else {
        units.add(VanishUnit(grapheme: grapheme, order: order));
      }
      continue;
    }

    order += 1;
    if (leading.isNotEmpty) {
      for (final pending in leading) {
        units.add(VanishUnit(grapheme: pending, order: order));
      }
      leading.clear();
    }
    units.add(VanishUnit(grapheme: grapheme, order: order));
  }

  if (leading.isNotEmpty) {
    for (final pending in leading) {
      units.add(VanishUnit(grapheme: pending, order: 1));
    }
  }

  return units;
}

int vanishLetterCount(List<VanishUnit> units) {
  var maxOrder = 0;
  for (final unit in units) {
    if (unit.order > maxOrder) maxOrder = unit.order;
  }
  return maxOrder;
}

int? passageIntValue(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}

String resolvePassageText(Map<String, dynamic> raw) {
  final snapshot = raw['__runtimeSnapshot'];
  final payload = snapshot is Map ? snapshot['payload'] : null;
  return payload is Map ? payload['text']?.toString() ?? '' : '';
}

String? validatePassageAssignment(Map<String, dynamic> raw) {
  final pause = passageIntValue(raw['letterPauseMs']) ?? 180;
  if (pause < 80 || pause > 800) return 'Пауза на букву от 80 до 800 мс.';
  if (raw['source'] == 'custom') {
    final text = raw['customText']?.toString().trim() ?? '';
    if (text.isEmpty) return 'Впишите текст.';
    if (text.length > 600) return 'Свой текст не длиннее 600 знаков.';
    return null;
  }
  return validateReadingContentSelection(raw);
}

class PassagePlay {
  const PassagePlay({
    required this.letterPauseMs,
    required this.text,
    required this.units,
  });

  final int letterPauseMs;
  final String text;
  final List<VanishUnit> units;

  int get letterCount => vanishLetterCount(units);
}

PassagePlay passagePlayFromParams(Map<String, dynamic> raw) {
  final pause = passageIntValue(raw['letterPauseMs']) ?? 180;
  final text = resolvePassageText(raw);
  return PassagePlay(
    letterPauseMs: pause.clamp(80, 800),
    text: text,
    units: buildVanishUnits(text),
  );
}

PassagePlay? passagePlayFromSnapshot(Map<String, dynamic>? payload) {
  if (payload == null) return null;
  final text = payload['text']?.toString() ?? '';
  final pause = passageIntValue(payload['letterPauseMs']);
  if (text.isEmpty || pause == null) return null;
  return PassagePlay(
    letterPauseMs: pause,
    text: text,
    units: buildVanishUnits(text),
  );
}
