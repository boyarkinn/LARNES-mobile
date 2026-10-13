/// Web: `platform/src/trainers/mental-arithmetic/example-visualization/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kExampleVisualizationInstructionPlaybackRate = 1.5;
const kExampleVisualizationInstructionDurationFallbackMs = 2560;
const kExampleVisualizationSolveInstructionDurationFallbackMs = 2080;
const kExampleVisualizationInstructionText = 'Посмотри как решается пример';
const kExampleVisualizationSolveInstructionText = 'А теперь реши его!';

String getExampleVisualizationInstructionAudioAsset() => '';

String getExampleVisualizationSolveInstructionAudioAsset() => '';

Future<void> playExampleVisualizationInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:example-visualization',
    legacyRate: kExampleVisualizationInstructionPlaybackRate,
  );
}

Future<void> playExampleVisualizationSolveInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:example-visualization:solve',
    legacyRate: kExampleVisualizationInstructionPlaybackRate,
  );
}

Future<void> cancelExampleVisualizationAudio() {
  return getSharedClipPlayer().cancel();
}
