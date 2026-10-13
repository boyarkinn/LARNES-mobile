/// Web: `platform/src/trainers/math/shop-pay/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kShopPayInstructionPlaybackRate = 1.5;
const kShopPayInstructionDurationFallbackMs = 2048;

String getShopPayInstructionAudioAsset() => '';

Future<void> playShopPayInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:shop-pay',
    legacyRate: kShopPayInstructionPlaybackRate,
  );
}

Future<void> cancelShopPayAudio() {
  return getSharedClipPlayer().cancel();
}
