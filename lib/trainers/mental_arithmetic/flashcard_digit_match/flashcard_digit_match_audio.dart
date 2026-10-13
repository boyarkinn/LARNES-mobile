// Web: `platform/src/trainers/mental-arithmetic/flashcard-digit-match/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kFlashcardDigitMatchInstructionPlaybackRate = 1.5;
const kFlashcardDigitMatchInstructionDurationFallbackMs = 3552;
const kFlashcardDigitMatchInstructionText =
    'Найди пару флеш-карте и соедини их линиями!';

String getFlashcardDigitMatchInstructionAudioAsset() => '';

Future<void> playFlashcardDigitMatchInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:flashcard-digit-match',
    legacyRate: kFlashcardDigitMatchInstructionPlaybackRate,
  );
}

Future<void> cancelFlashcardDigitMatchAudio() {
  return getSharedClipPlayer().cancel();
}
