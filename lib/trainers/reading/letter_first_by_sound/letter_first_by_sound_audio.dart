/// Web: `platform/src/trainers/reading/letter-first-by-sound/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kLetterFirstBySoundAudioAssetBase = 'audio/ru/reading/letter-first-by-sound';
const kLetterFirstBySoundInstructionPlaybackRate = 1.5;
const kLetterFirstBySoundInstructionDurationFallbackMs = 3584;

String getLetterFirstBySoundInstructionAudioAsset() =>
    '$kLetterFirstBySoundAudioAssetBase/instruction.mp3';

Future<void> playLetterFirstBySoundInstruction() {
  return getSharedClipPlayer().play(
    [getLetterFirstBySoundInstructionAudioAsset()],
    playbackRate: kLetterFirstBySoundInstructionPlaybackRate,
  );
}

Future<void> cancelLetterFirstBySoundAudio() {
  return getSharedClipPlayer().cancel();
}
