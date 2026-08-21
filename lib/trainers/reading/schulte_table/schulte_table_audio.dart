/// Web: `platform/src/trainers/reading/schulte-table/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kSchulteTableAudioAssetBase = 'audio/ru/reading/schulte-table';
const kSchulteTableInstructionPlaybackRate = 1.5;

String getSchulteTableInstructionAudioAsset() =>
    '$kSchulteTableAudioAssetBase/instruction.mp3';

Future<void> playSchulteTableInstruction() {
  return getSharedClipPlayer().play(
    [getSchulteTableInstructionAudioAsset()],
    playbackRate: kSchulteTableInstructionPlaybackRate,
  );
}

Future<void> cancelSchulteTableAudio() {
  return getSharedClipPlayer().cancel();
}
