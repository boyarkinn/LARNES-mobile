/// Web: `platform/src/trainers/reading/wedge-tables/model.ts`

import 'dart:math';

import 'package:larnes_mobile/trainers/reading/wedge_tables/definition.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_syllables.dart';

const kWedgeDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

const kWedgeLettersLatin = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

const kWedgeSyllablesLatin = [
  'BA', 'BE', 'BI', 'BO', 'BU', 'DA', 'DE', 'DI', 'DO', 'DU',
  'FA', 'FE', 'FI', 'FO', 'FU', 'GA', 'GE', 'GI', 'GO', 'GU',
  'KA', 'KE', 'KI', 'KO', 'KU', 'LA', 'LE', 'LI', 'LO', 'LU',
  'MA', 'ME', 'MI', 'MO', 'MU', 'NA', 'NE', 'NI', 'NO', 'NU',
  'PA', 'PE', 'PI', 'PO', 'PU', 'RA', 'RE', 'RI', 'RO', 'RU',
  'SA', 'SE', 'SI', 'SO', 'SU', 'TA', 'TE', 'TI', 'TO', 'TU',
  'VA', 'VE', 'VI', 'VO', 'VU', 'ZA', 'ZE', 'ZI', 'ZO', 'ZU',
  'BAM', 'BEM', 'BIM', 'BOM', 'DAL', 'DEL', 'DIL', 'DOL',
  'FAM', 'FEM', 'FIM', 'FOM', 'GAL', 'GEL', 'GIL', 'GOL',
  'KAN', 'KEN', 'KIN', 'KON', 'LAS', 'LES', 'LIS', 'LOS',
  'MAR', 'MER', 'MIR', 'MOR', 'NAP', 'NEP', 'NIP', 'NOP',
  'RAM', 'REM', 'RIM', 'ROM', 'TAL', 'TEL', 'TIL', 'TOL',
];

String wedgeScriptForLocale(String? locale) {
  final normalized = (locale ?? '').toLowerCase();
  if (normalized == 'en' ||
      normalized.startsWith('en-') ||
      normalized.startsWith('en_') ||
      normalized == 'ar' ||
      normalized.startsWith('ar-') ||
      normalized.startsWith('ar_')) {
    return 'latin';
  }
  return 'ru';
}

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
    this.locale,
    this.random,
  });

  final String category;
  final int rowCount;
  final String? locale;
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

List<String> wedgeLettersForLocale(String? locale) {
  return wedgeScriptForLocale(locale) == 'latin'
      ? List<String>.from(kWedgeLettersLatin)
      : List<String>.from(kWedgeLetters);
}

List<String> wedgeSyllablesForLocale(String? locale) {
  return wedgeScriptForLocale(locale) == 'latin'
      ? List<String>.from(kWedgeSyllablesLatin)
      : List<String>.from(kWedgeSyllables);
}

List<String> getWedgePool(String category, [String? locale]) {
  switch (category) {
    case 'digits':
      return List<String>.from(kWedgeDigits);
    case 'letters':
      return wedgeLettersForLocale(locale);
    case 'syllables':
      return wedgeSyllablesForLocale(locale);
    case 'all':
      return {
        ...kWedgeDigits,
        ...wedgeLettersForLocale(locale),
        ...wedgeSyllablesForLocale(locale),
      }.toList();
    default:
      throw ArgumentError('Unknown wedge category: $category');
  }
}

String classifyWedgeToken(String token) {
  if (kWedgeDigits.contains(token)) {
    return 'digits';
  }
  if (kWedgeLetters.contains(token) || kWedgeLettersLatin.contains(token)) {
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

  final pool = getWedgePool(input.category, input.locale);
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
