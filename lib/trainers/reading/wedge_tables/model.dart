/// Web: `platform/src/trainers/reading/wedge-tables/model.ts`

import 'dart:math';

import 'package:larnes_mobile/trainers/reading/wedge_tables/definition.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_syllables.dart';

const kWedgeDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

const kWedgeLetters = [
  'А',
  'Б',
  'В',
  'Г',
  'Д',
  'Е',
  'Ё',
  'Ж',
  'З',
  'И',
  'Й',
  'К',
  'Л',
  'М',
  'Н',
  'О',
  'П',
  'Р',
  'С',
  'Т',
  'У',
  'Ф',
  'Х',
  'Ц',
  'Ч',
  'Ш',
  'Щ',
  'Ъ',
  'Ы',
  'Ь',
  'Э',
  'Ю',
  'Я',
];

class WedgeRow {
  const WedgeRow({required this.left, required this.right});

  final String left;
  final String right;
}

class GenerateWedgeRowsInput {
  const GenerateWedgeRowsInput({
    required this.category,
    required this.rowCount,
    this.random,
  });

  final String category;
  final int rowCount;
  final double Function()? random;
}

double _normalizeRandom(double value) {
  if (value < 0) {
    return 0;
  }
  if (value > 0.999999999) {
    return 0.999999999;
  }
  return value;
}

List<String> getWedgePool(String category) {
  switch (category) {
    case 'digits':
      return List<String>.from(kWedgeDigits);
    case 'letters':
      return List<String>.from(kWedgeLetters);
    case 'syllables':
      return List<String>.from(kWedgeSyllables);
    case 'all':
      return {...kWedgeDigits, ...kWedgeLetters, ...kWedgeSyllables}.toList();
    default:
      throw ArgumentError('Unknown wedge category: $category');
  }
}

String classifyWedgeToken(String token) {
  if (kWedgeDigits.contains(token)) {
    return 'digits';
  }
  if (kWedgeLetters.contains(token)) {
    return 'letters';
  }
  return 'syllables';
}

String _pickToken(List<String> pool, double Function() random) {
  return pool[(_normalizeRandom(random()) * pool.length).floor()];
}

List<WedgeRow> generateWedgeRows(GenerateWedgeRowsInput input) {
  if (!kWedgeRowCounts.contains(input.rowCount)) {
    throw ArgumentError('rowCount must be 5, 10, … 50.');
  }

  final pool = getWedgePool(input.category);
  if (pool.isEmpty) {
    throw StateError('Empty ${input.category} pool.');
  }

  final random = input.random ?? () => Random().nextDouble();

  return List<WedgeRow>.generate(input.rowCount, (_) {
    return WedgeRow(
      left: _pickToken(pool, random),
      right: _pickToken(pool, random),
    );
  });
}
