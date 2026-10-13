/// Web: `platform/src/trainers/reading/letter-find-by-sound/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kLetterFindBySoundInstructionPlaybackRate = 1.5;
const kLetterFindBySoundInstructionDurationFallbackMs = 1552;

String getLetterFindBySoundInstructionAudioAsset() => '';

Future<void> playLetterFindBySoundInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:letter-find-by-sound',
    legacyRate: kLetterFindBySoundInstructionPlaybackRate,
  );
}

Future<void> cancelLetterFindBySoundAudio() {
  return getSharedClipPlayer().cancel();
}
