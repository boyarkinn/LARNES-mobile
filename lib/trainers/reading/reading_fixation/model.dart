import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

String readingFixationFragment(Object? raw) {
  if (raw == 'word' || raw == 'sentence') return raw as String;
  return 'pair';
}

int readingFixationPauseMs(Object? raw) {
  final value = passageIntValue(raw);
  if (value == null || value < 400 || value > 2000) return 800;
  return value;
}

List<String> _words(String text) {
  return text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
}

List<String> _sentences(String text) {
  final sentences = <String>[];
  final current = StringBuffer();
  for (final char in text.trim().split('')) {
    current.write(char);
    if (char == '.' || char == '!' || char == '?') {
      final piece = current.toString().trim();
      if (piece.isNotEmpty) sentences.add(piece);
      current.clear();
    }
  }
  final tail = current.toString().trim();
  if (tail.isNotEmpty) sentences.add(tail);
  return sentences;
}

List<String> readingFixationFragments(String text, String fragment) {
  if (fragment == 'sentence') return _sentences(text);
  final words = _words(text);
  if (fragment == 'word') return words;
  final pairs = <String>[];
  for (var index = 0; index < words.length; index += 2) {
    final end = index + 2 > words.length ? words.length : index + 2;
    pairs.add(words.sublist(index, end).join(' '));
  }
  return pairs;
}

String? validateReadingFixationRaw(Map<String, dynamic> raw) {
  return validatePassageAssignment(raw);
}
