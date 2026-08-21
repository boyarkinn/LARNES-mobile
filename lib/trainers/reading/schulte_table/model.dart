/// Web: `platform/src/trainers/reading/schulte-table/model.ts`

import 'dart:math' as math;

const kSchulteLettersGridSizeMax = 8;

final schulteDigits = List<String>.generate(100, (index) => '${index + 1}');

const schulteLetters = [
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
  'а',
  'б',
  'в',
  'г',
  'д',
  'е',
  'ё',
  'ж',
  'з',
  'и',
  'й',
  'к',
  'л',
  'м',
  'н',
  'о',
  'п',
  'р',
  'с',
  'т',
  'у',
  'ф',
  'х',
  'ц',
  'ч',
  'ш',
  'щ',
  'ъ',
  'ы',
  'ь',
  'э',
  'ю',
  'я',
];

typedef SchulteCategory = String;
typedef SchulteOrder = String;

class SchulteCell {
  const SchulteCell({
    required this.col,
    required this.row,
    required this.value,
  });

  final int col;
  final int row;
  final String value;
}

class SchulteTable {
  const SchulteTable({
    required this.cells,
    required this.sequence,
    required this.size,
  });

  final List<SchulteCell> cells;
  final List<String> sequence;
  final int size;
}

class SchulteCenterCell {
  const SchulteCenterCell({required this.col, required this.row});

  final int col;
  final int row;
}

class GenerateSchulteTableInput {
  const GenerateSchulteTableInput({
    required this.category,
    required this.gridSize,
    required this.order,
    this.random,
  });

  final SchulteCategory category;
  final int gridSize;
  final SchulteOrder order;
  final double Function()? random;
}

double _normalizeRandom(double Function() random) {
  return random().clamp(0.0, 0.999999999);
}

List<String> getSchultePool(SchulteCategory category) {
  return category == 'letters' ? schulteLetters : schulteDigits;
}

List<SchulteCenterCell> getSchulteCenterCells(int gridSize) {
  final center = gridSize ~/ 2;

  if (gridSize.isOdd) {
    return [SchulteCenterCell(col: center, row: center)];
  }

  return [
    SchulteCenterCell(col: center - 1, row: center - 1),
    SchulteCenterCell(col: center, row: center - 1),
    SchulteCenterCell(col: center - 1, row: center),
    SchulteCenterCell(col: center, row: center),
  ];
}

int _compareSchulteValues(
  String left,
  String right,
  SchulteCategory category,
) {
  if (category == 'digits') {
    return int.parse(left) - int.parse(right);
  }

  return schulteLetters.indexOf(left) - schulteLetters.indexOf(right);
}

List<String> buildSchulteSequence(
  List<String> values,
  SchulteCategory category,
  SchulteOrder order,
) {
  final sorted = [...values]
    ..sort((left, right) => _compareSchulteValues(left, right, category));
  return order == 'backward' ? sorted.reversed.toList() : sorted;
}

List<T> _shuffleInPlace<T>(List<T> items, double Function() random) {
  for (var index = items.length - 1; index > 0; index -= 1) {
    final swapIndex = (_normalizeRandom(random) * (index + 1)).floor();
    final current = items[index];
    items[index] = items[swapIndex];
    items[swapIndex] = current;
  }

  return items;
}

bool isNextSchulteTarget(
  String value,
  List<String> sequence,
  int foundCount,
) {
  if (foundCount < 0 || foundCount >= sequence.length) {
    return false;
  }

  return sequence[foundCount] == value;
}

SchulteTable generateSchulteTable(GenerateSchulteTableInput input) {
  final gridSize = input.gridSize;
  final cellCount = gridSize * gridSize;
  final pool = getSchultePool(input.category);

  if (gridSize < 3 || gridSize > 10) {
    throw ArgumentError('gridSize must be an integer from 3 to 10.');
  }

  if (cellCount > pool.length) {
    throw ArgumentError(
      'Not enough ${input.category} tokens for a $gridSize×$gridSize table.',
    );
  }

  final random = input.random ?? _defaultRandom;
  final values = pool.sublist(0, cellCount);
  final sequence = buildSchulteSequence(values, input.category, input.order);
  final first = sequence.first;
  final rest = sequence.sublist(1);
  final centers = getSchulteCenterCells(gridSize);
  final center = centers[(_normalizeRandom(random) * centers.length).floor()];
  final shuffledRest = _shuffleInPlace([...rest], random);

  final cells = <SchulteCell>[];
  var restIndex = 0;

  for (var row = 0; row < gridSize; row += 1) {
    for (var col = 0; col < gridSize; col += 1) {
      final isCenter = row == center.row && col == center.col;
      cells.add(
        SchulteCell(
          col: col,
          row: row,
          value: isCenter ? first : shuffledRest[restIndex++],
        ),
      );
    }
  }

  return SchulteTable(
    cells: cells,
    sequence: sequence,
    size: gridSize,
  );
}

String schulteCellId(SchulteCell cell) => '${cell.row}-${cell.col}';

final _defaultRng = math.Random();

double _defaultRandom() => _defaultRng.nextDouble();
