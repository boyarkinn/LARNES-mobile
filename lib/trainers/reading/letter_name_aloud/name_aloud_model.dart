import 'package:larnes_mobile/trainers/reading/letter_model.dart';

/// Web: `platform/src/trainers/reading/letter-name-aloud/model.ts`

const minNameAloudDisplaySeconds = 2;
const maxNameAloudDisplaySeconds = 8;
const maxNameAloudPracticeLetters = maxPracticeLettersNameAloud;

List<String> buildDisplayLetters(String practiceLettersRaw, String letterCase) {
  return parsePracticeLetters(practiceLettersRaw)
      .map((letter) => applyLetterCase(letter, letterCase))
      .toList();
}

bool isValidNameAloudPracticeLetters(String raw) {
  final letters = parsePracticeLetters(raw);

  return letters.isNotEmpty && letters.length <= maxNameAloudPracticeLetters;
}

int getNameAloudTotalDisplayMs(int displaySeconds, int letterCount) {
  final safeSeconds = displaySeconds < 0 ? 0 : displaySeconds;
  return safeSeconds * 1000 * letterCount;
}
