/// Web: `platform/src/trainers/reading/letter-find-by-sound/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kLetterFindBySoundAudioAssetBase = 'audio/ru/reading/letter-find-by-sound';
const kLetterFindBySoundInstructionPlaybackRate = 1.5;
const kLetterFindBySoundInstructionDurationFallbackMs = 1552;

String getLetterFindBySoundInstructionAudioAsset() =>
    '$kLetterFindBySoundAudioAssetBase/instruction.mp3';

Future<void> playLetterFindBySoundInstruction() {
  return getSharedClipPlayer().play(
    [getLetterFindBySoundInstructionAudioAsset()],
    playbackRate: kLetterFindBySoundInstructionPlaybackRate,
  );
}

Future<void> cancelLetterFindBySoundAudio() {
  return getSharedClipPlayer().cancel();
}
