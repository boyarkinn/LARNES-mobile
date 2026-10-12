import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingClozeInstructionText = 'Выбери слово';
const readingClozeInstructionMs = 2400;

String readingClozeMode(Object? raw) {
  return raw == 'story' ? 'story' : 'simple';
}

String? validateReadingClozeRaw(Map<String, dynamic> raw) {
  final id = raw['passageId']?.toString() ?? defaultPassageId;
  if (passageById(id) == null) return 'Выберите текст из банка.';
  return null;
}
