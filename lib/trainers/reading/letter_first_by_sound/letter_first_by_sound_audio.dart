/// Web: `platform/src/trainers/reading/letter-first-by-sound/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kLetterFirstBySoundInstructionPlaybackRate = 1.5;
const kLetterFirstBySoundInstructionDurationFallbackMs = 3584;

String getLetterFirstBySoundInstructionAudioAsset() => '';

Future<void> playLetterFirstBySoundInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:letter-first-by-sound',
    legacyRate: kLetterFirstBySoundInstructionPlaybackRate,
  );
}

Future<void> cancelLetterFirstBySoundAudio() {
  return getSharedClipPlayer().cancel();
}
