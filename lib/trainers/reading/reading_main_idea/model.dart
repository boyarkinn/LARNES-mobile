import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingMainIdeaInstructionText = 'Выбери мысль';
const readingMainIdeaInstructionMs = 2400;

List<String> readingMainIdeaSentences(String text) {
  final sentences = <String>[];
  var current = '';
  for (final char in text.trim().split('')) {
    current += char;
    if (char == '.' || char == '!' || char == '?') {
      final piece = current.trim();
      if (piece.isNotEmpty) sentences.add(piece);
      current = '';
    }
  }
  final tail = current.trim();
  if (tail.isNotEmpty) sentences.add(tail);
  return sentences;
}

String? validateReadingMainIdeaRaw(Map<String, dynamic> raw) {
  final id = raw['passageId']?.toString() ?? defaultPassageId;
  if (passageById(id) == null) return 'Выберите текст из банка.';
  return null;
}
