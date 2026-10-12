import 'package:larnes_mobile/trainers/reading/reading_blocks/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingLinePaceInstructionText = 'Успей прочитать строку';
const readingLinePaceDefaultMs = 1600;

String readingLineKeep(Object? raw) => raw == 'drop' ? 'drop' : 'keep';

int readingLinePaceMs(Object? raw) {
  final value = passageIntValue(raw);
  if (value == null || value < 400 || value > 4000) return readingLinePaceDefaultMs;
  return value;
}

String? validateReadingLinePaceRaw(Map<String, dynamic> raw) {
  return validatePassageAssignment(raw);
}

List<String> readingLinePaceLines(String text, int wordsPerLine) {
  return readingBlockLines(text, wordsPerLine);
}
