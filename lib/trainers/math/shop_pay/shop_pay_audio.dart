/// Web: `platform/src/trainers/math/shop-pay/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kShopPayAudioAssetBase = 'audio/ru/math/shop-pay';
const kShopPayInstructionPlaybackRate = 1.5;
const kShopPayInstructionDurationFallbackMs = 2048;

String getShopPayInstructionAudioAsset() =>
    '$kShopPayAudioAssetBase/instruction.mp3';

Future<void> playShopPayInstruction() {
  return getSharedClipPlayer().play(
    [getShopPayInstructionAudioAsset()],
    playbackRate: kShopPayInstructionPlaybackRate,
  );
}

Future<void> cancelShopPayAudio() {
  return getSharedClipPlayer().cancel();
}
