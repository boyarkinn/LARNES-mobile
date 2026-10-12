import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingTreeTargets = [5, 10, 15, 10, 5];

List<String> readingTreeLines(String text) {
  final words = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  final lines = <String>[];
  var cursor = 0;
  var step = 0;
  while (cursor < words.length) {
    final target = readingTreeTargets[step % readingTreeTargets.length];
    var end = cursor + 1;
    while (end < words.length && words.sublist(cursor, end + 1).join(' ').length <= target) {
      end += 1;
    }
    lines.add(words.sublist(cursor, end).join(' '));
    cursor = end;
    step += 1;
  }
  return lines;
}

String? validateReadingTreeRaw(Map<String, dynamic> raw) {
  return validatePassageAssignment(raw);
}
