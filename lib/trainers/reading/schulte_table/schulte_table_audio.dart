/// Web: `platform/src/trainers/reading/schulte-table/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kSchulteTableInstructionPlaybackRate = 1.5;
const kSchulteTableInstructionDurationFallbackMs = 9038;

String getSchulteTableInstructionAudioAsset() => '';

Future<void> playSchulteTableInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:schulte-table',
    legacyRate: kSchulteTableInstructionPlaybackRate,
  );
}

Future<void> cancelSchulteTableAudio() {
  return getSharedClipPlayer().cancel();
}
