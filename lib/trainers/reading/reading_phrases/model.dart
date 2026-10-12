import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingPhraseInstructionText = 'Читай по смыслу';
const readingPhraseInstructionMs = 2400;
const readingPhraseHoldMs = 1400;

String readingPhraseMode(Object? raw) {
  return raw == 'place' ? 'place' : 'fade';
}

String joinReadingPhrases(List<String> phrases) => phrases.join(' ');

List<String> readingPhraseWords(List<String> phrases) {
  return phrases
      .expand((phrase) => phrase.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty))
      .toList();
}

List<int> readingPhraseGaps(List<String> phrases) {
  final gaps = <int>[];
  var words = 0;
  for (var index = 0; index < phrases.length - 1; index++) {
    words += phrases[index].trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    gaps.add(words - 1);
  }
  return gaps;
}

bool readingPhraseBoundaryVisible(int boundaryIndex, int hiddenCount) {
  return boundaryIndex >= hiddenCount;
}

String? validateReadingPhrasesRaw(Map<String, dynamic> raw) {
  final id = raw['passageId']?.toString() ?? defaultPassageId;
  if (passageById(id) == null) return 'Выберите текст из банка.';
  return null;
}
