import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingFindInstructionText = 'Найди в тексте';
const readingFindInstructionMs = 2400;

String readingFindMode(Object? raw) {
  return raw == 'answer' ? 'answer' : 'word';
}

List<String> readingFindWords(String text) {
  return text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
}

List<int> readingFindTargetIndexes(List<String> words, List<String> targets) {
  final indexes = <int>[];
  var cursor = 0;
  for (final target in targets) {
    var at = -1;
    for (var index = cursor; index < words.length; index++) {
      if (words[index] == target) {
        at = index;
        break;
      }
    }
    if (at < 0) {
      throw StateError('В тексте нет «$target».');
    }
    indexes.add(at);
    cursor = at + 1;
  }
  return indexes;
}

String? validateReadingFindSpanRaw(Map<String, dynamic> raw) {
  final id = raw['passageId']?.toString() ?? defaultPassageId;
  if (passageById(id) == null) return 'Выберите текст из банка.';
  return null;
}
