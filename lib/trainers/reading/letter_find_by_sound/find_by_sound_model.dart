import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-find-by-sound/model.ts`

class BuildSoundFindFieldInput {
  const BuildSoundFindFieldInput({
    required this.distractorCount,
    required this.letterCase,
    required this.rng,
    required this.targetLetter,
  });

  final int distractorCount;
  final String letterCase;
  final double Function() rng;
  final String targetLetter;
}

List<LetterToken> buildSoundFindTokens(BuildSoundFindFieldInput input) {
  return buildLetterTokens(
    BuildLetterFieldInput(
      distractorCount: input.distractorCount,
      letterCase: input.letterCase,
      rng: input.rng,
      targetCount: 1,
      targetLetter: input.targetLetter,
    ),
  );
}

String getSoundStubMessage(String displayLetter) {
  return 'Заглушка аудио: буква «$displayLetter»';
}

const maxSoundPracticeLetters = maxPracticeLettersNameAloud;

List<String> resolveSoundPracticeLetters([
  String? practiceLettersRaw,
  String? legacyLetter,
]) {
  final raw = (practiceLettersRaw != null && practiceLettersRaw.trim().isNotEmpty)
      ? practiceLettersRaw.trim()
      : (legacyLetter?.trim() ?? '');
  return parsePracticeLetters(raw);
}

bool isValidSoundPracticeLetters([
  String? practiceLettersRaw,
  String? legacyLetter,
]) {
  final letters = resolveSoundPracticeLetters(practiceLettersRaw, legacyLetter);
  return letters.isNotEmpty && letters.length <= maxSoundPracticeLetters;
}

int buildSoundFindRoundSeed({
  required String targetLetter,
  required String letterCase,
  required int distractorCount,
  required int layoutSalt,
  required int roundIndex,
}) {
  return hashParamsSeed([
    targetLetter,
    letterCase,
    distractorCount,
    layoutSalt,
    roundIndex,
    'sound',
  ]);
}
