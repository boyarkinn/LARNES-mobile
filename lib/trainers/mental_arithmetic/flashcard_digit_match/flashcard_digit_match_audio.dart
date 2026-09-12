// Web: `platform/src/trainers/mental-arithmetic/flashcard-digit-match/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kFlashcardDigitMatchAudioAssetBase =
    'audio/ru/mental-arithmetic/flashcard-digit-match';
const kFlashcardDigitMatchInstructionPlaybackRate = 1.5;
const kFlashcardDigitMatchInstructionDurationFallbackMs = 3552;
const kFlashcardDigitMatchInstructionText =
    'Найди пару флеш-карте и соедини их линиями!';

String getFlashcardDigitMatchInstructionAudioAsset() =>
    '$kFlashcardDigitMatchAudioAssetBase/instruction.mp3';

Future<void> playFlashcardDigitMatchInstruction() {
  return getSharedClipPlayer().play([
    getFlashcardDigitMatchInstructionAudioAsset(),
  ], playbackRate: kFlashcardDigitMatchInstructionPlaybackRate);
}

Future<void> cancelFlashcardDigitMatchAudio() {
  return getSharedClipPlayer().cancel();
}
