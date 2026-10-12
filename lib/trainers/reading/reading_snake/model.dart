import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingSnakeInstructionText = 'Смотри на головку';
const readingSnakeTail = 3;

int snakeHeadOrder(int hiddenOrder, int letterCount) {
  if (letterCount < 1) return 0;
  final next = hiddenOrder + 1;
  return next > letterCount ? letterCount : next;
}

bool isSnakeHead(VanishUnit unit, int hiddenOrder, int letterCount) {
  return unit.order == snakeHeadOrder(hiddenOrder, letterCount) && isLetterGrapheme(unit.grapheme);
}

bool isSnakeTail(VanishUnit unit, int hiddenOrder, int letterCount) {
  final head = snakeHeadOrder(hiddenOrder, letterCount);
  return isLetterGrapheme(unit.grapheme) && unit.order < head && head - unit.order <= readingSnakeTail;
}

String? validateReadingSnakeRaw(Map<String, dynamic> raw) {
  return validatePassageAssignment(raw);
}
