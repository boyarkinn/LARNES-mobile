import 'package:characters/characters.dart';

class ReadingPassage {
  const ReadingPassage({required this.id, required this.text});

  final String id;
  final String text;
}

const readingPassages = <ReadingPassage>[
  ReadingPassage(
    id: 'short-window',
    text: 'Утром кот сел на окно и смотрел на тихий двор.',
  ),
  ReadingPassage(
    id: 'short-ball',
    text: 'Маша нашла красный мяч под старым кустом.',
  ),
  ReadingPassage(
    id: 'medium-puddles',
    text:
        'После дождя на дорожке блестели лужи. Дети пускали бумажные кораблики и громко смеялись.',
  ),
  ReadingPassage(
    id: 'medium-market',
    text:
        'На рынке бабушка купила яблоки, тёплый хлеб и кувшин молока. Домой она шла медленно и смотрела по сторонам.',
  ),
  ReadingPassage(
    id: 'long-apple-tree',
    text:
        'В саду за домом росла старая яблоня. Летом под ней ставили стол, пили чай и слушали, как в ветках поёт дрозд. Вечером солнце садилось за крышу, и сад становился тихим.',
  ),
];

const defaultPassageId = 'short-window';

ReadingPassage? passageById(String id) {
  for (final passage in readingPassages) {
    if (passage.id == id) return passage;
  }
  return null;
}

class VanishUnit {
  const VanishUnit({required this.grapheme, required this.order});

  final String grapheme;
  final int order;
}

final _letterPattern = RegExp(r'\p{L}', unicode: true);

List<VanishUnit> buildVanishUnits(String text) {
  final units = <VanishUnit>[];
  final leading = <String>[];
  var order = 0;

  for (final grapheme in text.characters) {
    if (!_letterPattern.hasMatch(grapheme)) {
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

class ReadingShutterPlan {
  const ReadingShutterPlan({
    required this.cover,
    required this.edge,
    required this.letterPauseMs,
    required this.text,
    required this.units,
  });

  final String cover;
  final String edge;
  final int letterPauseMs;
  final String text;
  final List<VanishUnit> units;

  int get letterCount => vanishLetterCount(units);
}

int? _intValue(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}

/// Returns an error message, or null when [raw] is a valid shutter assignment.
String? validateReadingShutterRaw(Map<String, dynamic> raw) {
  final source = raw['source'] == 'custom' ? 'custom' : 'bank';
  final pause = _intValue(raw['letterPauseMs']) ?? 180;
  if (pause < 80 || pause > 800) return 'Пауза на букву от 80 до 800 мс.';

  final edge = raw['edge']?.toString() ?? 'top';
  if (edge != 'top' && edge != 'bottom') return 'Выберите край шторки.';

  final cover = raw['cover']?.toString() ?? 'quarter';
  if (cover != 'quarter' && cover != 'half') return 'Выберите, сколько текста закрыто.';

  if (source == 'custom') {
    final text = raw['customText']?.toString().trim() ?? '';
    if (text.isEmpty) return 'Впишите текст.';
    if (text.length > 600) return 'Свой текст не длиннее 600 знаков.';
  } else if (passageById(raw['passageId']?.toString() ?? defaultPassageId) == null) {
    return 'Выберите текст из банка.';
  }

  return null;
}

ReadingShutterPlan readingShutterPlanFromParams(Map<String, dynamic> raw) {
  final source = raw['source'] == 'custom' ? 'custom' : 'bank';
  final customText = raw['customText']?.toString().trim() ?? '';
  final passageId = raw['passageId']?.toString() ?? defaultPassageId;
  final text = source == 'custom'
      ? customText
      : (passageById(passageId)?.text ?? '');
  final pause = _intValue(raw['letterPauseMs']) ?? 180;
  final edge = raw['edge'] == 'bottom' ? 'bottom' : 'top';
  final cover = raw['cover'] == 'half' ? 'half' : 'quarter';

  return ReadingShutterPlan(
    cover: cover,
    edge: edge,
    letterPauseMs: pause.clamp(80, 800),
    text: text,
    units: buildVanishUnits(text),
  );
}

ReadingShutterPlan? readingShutterPlanFromSnapshot(Map<String, dynamic>? payload) {
  if (payload == null) return null;
  final text = payload['text']?.toString() ?? '';
  final pause = _intValue(payload['letterPauseMs']);
  final edge = payload['edge']?.toString();
  final cover = payload['cover']?.toString();
  if (text.isEmpty || pause == null) return null;
  if (edge != 'top' && edge != 'bottom') return null;
  if (cover != 'quarter' && cover != 'half') return null;

  return ReadingShutterPlan(
    cover: cover!,
    edge: edge!,
    letterPauseMs: pause,
    text: text,
    units: buildVanishUnits(text),
  );
}
