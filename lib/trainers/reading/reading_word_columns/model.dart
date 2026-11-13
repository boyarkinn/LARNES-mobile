import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';

const wordColumnsInstructionText =
    'Сделай глубокий вдох и читай слова, пока полностью не выдохнешь. Когда прочитаешь слово, нажми «Далее». Когда воздух закончится, нажми «Завершить».';
const wordColumnsInstructionMs = 12000;
String? validateReadingWordColumnsRaw(Map<String, dynamic> raw) {
  if (raw['__runtimeSnapshot'] is Map) return null;
  final selection = raw['contentBank'];
  return selection is Map &&
          selection['libraryId'] == readingContentBankLibraryId &&
          selection['categoryId'] is String &&
          (selection['categoryId'] as String).isNotEmpty
      ? null
      : 'Выберите тему и подтему.';
}
