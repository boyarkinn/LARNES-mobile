/// Web: `platform/src/trainers/mental-arithmetic/example-visualization/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kExampleVisualizationAudioAssetBase =
    'audio/ru/mental-arithmetic/example-visualization';
const kExampleVisualizationInstructionPlaybackRate = 1.5;
const kExampleVisualizationInstructionDurationFallbackMs = 2560;
const kExampleVisualizationSolveInstructionDurationFallbackMs = 2080;
const kExampleVisualizationInstructionText = 'Посмотри как решается пример';
const kExampleVisualizationSolveInstructionText = 'А теперь реши его!';

String getExampleVisualizationInstructionAudioAsset() =>
    '$kExampleVisualizationAudioAssetBase/instruction.mp3';

String getExampleVisualizationSolveInstructionAudioAsset() =>
    '$kExampleVisualizationAudioAssetBase/solve-instruction.mp3';

Future<void> playExampleVisualizationInstruction() {
  return getSharedClipPlayer().play(
    [getExampleVisualizationInstructionAudioAsset()],
    playbackRate: kExampleVisualizationInstructionPlaybackRate,
  );
}

Future<void> playExampleVisualizationSolveInstruction() {
  return getSharedClipPlayer().play(
    [getExampleVisualizationSolveInstructionAudioAsset()],
    playbackRate: kExampleVisualizationInstructionPlaybackRate,
  );
}

Future<void> cancelExampleVisualizationAudio() {
  return getSharedClipPlayer().cancel();
}
