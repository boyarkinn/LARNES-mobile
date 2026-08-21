/// Web: `platform/src/trainers/reading/stroop-colors/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kStroopColorsAudioAssetBase = 'audio/ru/reading/stroop-colors';
const kStroopColorsInstructionPlaybackRate = 1.0;

String getStroopColorsInstructionAudioAsset() =>
    '$kStroopColorsAudioAssetBase/instruction.mp3';

Future<void> playStroopColorsInstruction() {
  return getSharedClipPlayer().play(
    [getStroopColorsInstructionAudioAsset()],
    playbackRate: kStroopColorsInstructionPlaybackRate,
  );
}

Future<void> cancelStroopColorsAudio() {
  return getSharedClipPlayer().cancel();
}
