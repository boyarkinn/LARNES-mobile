import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';

const readingClozeInstructionText = 'Выбери слово';
const readingClozeInstructionMs = 2400;

String readingClozeMode(Object? raw) {
  return raw == 'story' ? 'story' : 'simple';
}

String? validateReadingClozeRaw(Map<String, dynamic> raw) {
  return validateReadingContentSelection(raw);
}
