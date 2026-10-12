import 'package:characters/characters.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingSprintInstructionText = 'Читай слова';
const readingSprintInstructionMs = 2400;

String readingSprintBare(String token) {
  return token.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '').toLowerCase();
}

int readingSprintLength(String word) => word.characters.length;

bool readingSprintTextHasWord(String text, String word) {
  final needle = readingSprintBare(word);
  return text.trim().split(RegExp(r'\s+')).any((token) => token.isNotEmpty && readingSprintBare(token) == needle);
}

List<String> readingSprintQueueAfter(List<String> queue, String mark) {
  if (queue.isEmpty) return queue;
  final rest = queue.sublist(1);
  if (mark == 'ok') return rest;
  return [...rest, queue.first];
}

String? validateReadingWordSprintRaw(Map<String, dynamic> raw) {
  final id = raw['passageId']?.toString() ?? defaultPassageId;
  if (passageById(id) == null) return 'Выберите текст из банка.';
  return null;
}
