/// Web: `platform/src/trainers/mental-arithmetic/example-visualization/example-parser.ts`

class ExampleAction {
  const ExampleAction({
    required this.sign,
    required this.digit,
  });

  final String sign;
  final int digit;
}

int maxValueForExampleRods(int totalRods) {
  if (totalRods < 1) {
    return 0;
  }
  var result = 1;
  for (var i = 0; i < totalRods; i++) {
    result *= 10;
  }
  return result - 1;
}

String normalizeExampleString(String example) {
  return example
      .trim()
      .replaceAll('\u2212', '-')
      .replaceAll('\uFE63', '-')
      .replaceAllMapped(
        RegExp(r'([+-])\s+(?=\d)'),
        (match) => match.group(1)!,
      );
}

List<ExampleAction> parseExampleActions(String example) {
  final normalized = normalizeExampleString(example);
  final tokenPattern = RegExp(r'[+-]\d+');
  final tokens = tokenPattern.allMatches(normalized).map((m) => m.group(0)!).toList();

  if (tokens.isEmpty) {
    throw FormatException(
      'Пример должен содержать хотя бы одно действие, например "+2 -1".',
    );
  }

  final compact = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  final reconstructed = tokens.join(' ');

  if (reconstructed != compact) {
    throw FormatException(
      'Неверный формат примера "${example.trim()}". Ожидается строка ±цифра, например "+2 -1".',
    );
  }

  return tokens.map(_parseExampleToken).toList();
}

ExampleAction _parseExampleToken(String token) {
  final match = RegExp(r'^([+-])(\d+)$').firstMatch(token);
  if (match == null) {
    throw FormatException(
      'Неверный формат действия "$token". Ожидается ±цифра, например "+2".',
    );
  }

  final sign = match.group(1)!;
  final digit = int.parse(match.group(2)!);

  if (digit < 1) {
    throw FormatException('Цифра в "$token" должна быть целым числом от 1.');
  }

  return ExampleAction(sign: sign, digit: digit);
}

String formatExampleAction(ExampleAction action) {
  return '${action.sign}${action.digit}';
}

String formatExample(List<ExampleAction> actions) {
  return actions.map(formatExampleAction).join(' ');
}

List<int> simulateExampleValues(List<ExampleAction> actions) {
  var value = 0;
  final values = <int>[0];

  for (final action in actions) {
    value = action.sign == '+' ? value + action.digit : value - action.digit;
    values.add(value);
  }

  return values;
}

String? validateExampleForRods(String example, int totalRods) {
  final List<ExampleAction> actions;

  try {
    actions = parseExampleActions(example);
  } catch (error) {
    if (error is FormatException) {
      return error.message;
    }
    return 'Неверный формат примера.';
  }

  final maxValue = maxValueForExampleRods(totalRods);
  var value = 0;

  for (final action in actions) {
    value = action.sign == '+' ? value + action.digit : value - action.digit;

    if (value < 0) {
      return 'После ${formatExampleAction(action)} значение отрицательное.';
    }

    if (value > maxValue) {
      return 'После ${formatExampleAction(action)} значение больше $maxValue для $totalRods разряд(ов).';
    }
  }

  return null;
}
