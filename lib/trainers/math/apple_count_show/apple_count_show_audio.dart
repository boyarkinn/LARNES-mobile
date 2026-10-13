/// Web: `platform/src/trainers/math/apple-count-show/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kAppleCountShowAudioAssetBase = 'audio/ru/math/apple-count-show';
const kAppleCountShowInstructionPlaybackRate = 1.5;
const kAppleCountShowInstructionDurationFallbackMs = 2048;
const kAppleCountShowInstructionText = 'Положи яблоки в корзину';

String getAppleCountShowInstructionAudioAsset() =>
    '$kAppleCountShowAudioAssetBase/instruction.mp3';

Future<void> playAppleCountShowInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:apple-count-show',
    legacyAsset: getAppleCountShowInstructionAudioAsset(),
    legacyRate: kAppleCountShowInstructionPlaybackRate,
  );
}

Future<void> playAppleTargetCountAudio(int targetCount) {
  return getSharedClipPlayer().play(
    ['audio/ru/mental-arithmetic/numbers/$targetCount.mp3'],
  );
}

Future<void> cancelAppleCountShowAudio() {
  return getSharedClipPlayer().cancel();
}
