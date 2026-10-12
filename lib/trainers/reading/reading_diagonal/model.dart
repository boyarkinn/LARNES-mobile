import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingDiagonalLineTarget = 12;
const readingDiagonalStepCount = 4;

class ReadingDiagonalLine {
  const ReadingDiagonalLine({required this.step, required this.text});

  final int step;
  final String text;
}

List<ReadingDiagonalLine> readingDiagonalLines(String text) {
  final words = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  final lines = <ReadingDiagonalLine>[];
  var cursor = 0;
  while (cursor < words.length) {
    var end = cursor + 1;
    while (end < words.length && words.sublist(cursor, end + 1).join(' ').length <= readingDiagonalLineTarget) {
      end += 1;
    }
    lines.add(ReadingDiagonalLine(
      step: lines.length % readingDiagonalStepCount,
      text: words.sublist(cursor, end).join(' '),
    ));
    cursor = end;
  }
  return lines;
}

String? validateReadingDiagonalRaw(Map<String, dynamic> raw) {
  return validatePassageAssignment(raw);
}
