/// Web: `platform/src/trainers/reading/wedge-tables/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kWedgeTablesAudioAssetBase = 'audio/ru/reading/wedge-tables';
const kWedgeTablesInstructionPlaybackRate = 1.5;
const kWedgeTablesInstructionDurationFallbackMs = 5881;

String getWedgeTablesInstructionAudioAsset() =>
    '$kWedgeTablesAudioAssetBase/instruction.mp3';

Future<void> playWedgeTablesInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:wedge-tables',
    legacyAsset: getWedgeTablesInstructionAudioAsset(),
    legacyRate: kWedgeTablesInstructionPlaybackRate,
  );
}

Future<void> cancelWedgeTablesAudio() {
  return getSharedClipPlayer().cancel();
}
