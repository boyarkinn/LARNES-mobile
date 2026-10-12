import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

List<String> readingBlockLines(String text, int wordsPerLine) {
  final words = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  final size = wordsPerLine.clamp(1, 10);
  final lines = <String>[];
  for (var index = 0; index < words.length; index += size) {
    final end = index + size > words.length ? words.length : index + size;
    lines.add(words.sublist(index, end).join(' '));
  }
  return lines;
}

int readingBlocksWordsPerLine(Object? raw) {
  final value = passageIntValue(raw);
  if (value == null || value < 1 || value > 10) return 3;
  return value;
}

String? validateReadingBlocksRaw(Map<String, dynamic> raw) {
  return validatePassageAssignment(raw);
}
