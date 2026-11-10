// Web: `platform/src/trainers/shared/numeric-answer.ts`

/// Парсит ввод ребёнка; пусто / мусор → null.
int? parseNumericAnswerInput(String raw) {
  final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), '');

  if (trimmed.isEmpty || !RegExp(r'^-?\d+$').hasMatch(trimmed)) {
    return null;
  }

  return int.tryParse(trimmed);
}

bool isCorrectNumericAnswer(String raw, int expected) {
  final parsed = parseNumericAnswerInput(raw);
  return parsed != null && parsed == expected;
}
