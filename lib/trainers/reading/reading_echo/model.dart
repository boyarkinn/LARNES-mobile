import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingEchoInstructionText = 'Повторяй за текстом';
const readingEchoInstructionMs = 2400;

String readingEchoSwitch(Object? raw, {String fallback = 'on'}) {
  return raw == 'off' ? 'off' : fallback;
}

int readingEchoSpan(Object? raw) {
  final value = raw is num ? raw.round() : int.tryParse(raw?.toString() ?? '') ?? 1;
  if (value < 1 || value > 3) return 1;
  return value;
}

int readingEchoPauseMs(Object? raw) {
  final value = raw is num ? raw.round() : int.tryParse(raw?.toString() ?? '') ?? 1200;
  if (value < 400 || value > 3000) return 1200;
  return value;
}

List<String> splitReadingEchoSentences(String text) {
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

List<String> readingEchoFragment(String text, int span) {
  final sentences = splitReadingEchoSentences(text);
  if (sentences.isEmpty) return const [];
  final count = span.clamp(1, sentences.length);
  return sentences.take(count).toList();
}

String? validateReadingEchoRaw(Map<String, dynamic> raw) {
  return validatePassageAssignment(raw);
}
