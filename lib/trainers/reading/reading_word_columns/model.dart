import 'package:larnes_mobile/trainers/reading/shared/word_list.dart';

const wordColumnsInstructionText =
    'Сделай глубокий вдох и читай слова, пока полностью не выдохнешь. Когда прочитаешь слово, нажми «Далее». Когда воздух закончится, нажми «Завершить».';
const wordColumnsInstructionMs = 12000;
String? validateReadingWordColumnsRaw(Map<String, dynamic> raw) =>
    validateReadingWordListRaw(raw, allowMultiple: true);
