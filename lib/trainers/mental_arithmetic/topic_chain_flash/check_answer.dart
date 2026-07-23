/// Web: `platform/src/trainers/mental-arithmetic/topic-chain-flash/check-answer.ts`

/// Парсит ввод ребёнка; пусто / мусор → null.
int? parseAnswerInput(String raw) {
  final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), '');

  if (trimmed.isEmpty || !RegExp(r'^-?\d+$').hasMatch(trimmed)) {
    return null;
  }

  return int.tryParse(trimmed);
}

bool isCorrectAnswer(String raw, int expected) {
  final parsed = parseAnswerInput(raw);
  return parsed != null && parsed == expected;
}
