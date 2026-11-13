import '../shared/content_bank.dart';

const readingAnagramDefaultSlug = '';

const readingAnagramInstructionText = 'Собери слово';
const readingAnagramInstructionMs = 2400;

String readingAnagramHint(Object? raw) {
  return raw == 'definition' || raw == 'sentence' ? raw.toString() : 'picture';
}

List<int> readingAnagramOrder(int length) {
  if (length < 2) return List<int>.generate(length, (index) => index);
  return [...List<int>.generate(length - 1, (index) => index + 1), 0];
}

String? validateReadingAnagramRaw(Map<String, dynamic> raw) =>
    validateReadingContentSelection(raw);
