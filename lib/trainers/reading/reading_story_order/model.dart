import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingStoryInstructionText = 'Собери историю';
const readingStoryInstructionMs = 2400;
const readingStoryCardsMin = 3;
const readingStoryCardsMax = 5;

int readingStoryCards(Object? raw) {
  final value = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? readingStoryCardsMin;
  if (value < readingStoryCardsMin) return readingStoryCardsMin;
  if (value > readingStoryCardsMax) return readingStoryCardsMax;
  return value;
}

List<int> readingStoryOrder(int length) {
  if (length < 2) return List<int>.generate(length, (index) => index);
  return [...List<int>.generate(length - 1, (index) => index + 1), 0];
}

String? validateReadingStoryOrderRaw(Map<String, dynamic> raw) {
  final id = raw['passageId']?.toString() ?? defaultPassageId;
  if (passageById(id) == null) return 'Выберите текст из банка.';
  return null;
}
