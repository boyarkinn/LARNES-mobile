/// Web: `platform/src/trainers/reading/stroop-colors/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kStroopColorsInstructionPlaybackRate = 1.5;
const kStroopColorsInstructionDurationFallbackMs = 1392;

String getStroopColorsInstructionAudioAsset() => '';

Future<void> playStroopColorsInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:stroop-colors',
    legacyRate: kStroopColorsInstructionPlaybackRate,
  );
}

Future<void> cancelStroopColorsAudio() {
  return getSharedClipPlayer().cancel();
}
