import 'package:characters/characters.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingFlashLetterGroup = 3;
const readingFlashLineTarget = 18;

String readingFlashKind(Object? raw) => raw == 'line' ? 'line' : 'letters';

int readingFlashDurationMs(Object? raw) {
  final value = passageIntValue(raw);
  if (value == null || value < 200 || value > 1500) return 600;
  return value;
}

int readingFlashShows(Object? raw) {
  final value = passageIntValue(raw);
  if (value == null || value < 1 || value > 12) return 5;
  return value;
}

List<String> readingFlashChunks(String text, String kind) {
  if (kind == 'line') {
    final words = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final lines = <String>[];
    var cursor = 0;
    while (cursor < words.length) {
      var end = cursor + 1;
      while (end < words.length && words.sublist(cursor, end + 1).join(' ').length <= readingFlashLineTarget) {
        end += 1;
      }
      lines.add(words.sublist(cursor, end).join(' '));
      cursor = end;
    }
    return lines;
  }

  final letters = text.characters.where(isLetterGrapheme).toList();
  final groups = <String>[];
  for (var index = 0; index < letters.length; index += readingFlashLetterGroup) {
    final end = index + readingFlashLetterGroup > letters.length ? letters.length : index + readingFlashLetterGroup;
    groups.add(letters.sublist(index, end).join());
  }
  return groups;
}

List<String> takeReadingFlashShows(List<String> chunks, int shows) {
  final count = shows.clamp(1, 12);
  if (chunks.length <= count) return chunks;
  return chunks.sublist(0, count);
}

String? validateReadingFlashRaw(Map<String, dynamic> raw) {
  return validatePassageAssignment(raw);
}
