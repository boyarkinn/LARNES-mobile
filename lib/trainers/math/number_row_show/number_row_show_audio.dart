/// Web: `platform/src/trainers/math/number-row-show/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kNumberRowShowAudioAssetBase = 'audio/ru/math/number-row-show';
const kNumberRowShowInstructionPlaybackRate = 1.5;
const kNumberRowShowInstructionDurationFallbackMs = 2048;
const kNumberRowShowInstructionText = 'Собери числовой ряд';

String getNumberRowShowInstructionAudioAsset() =>
    '$kNumberRowShowAudioAssetBase/instruction.mp3';

Future<void> playNumberRowShowInstruction() {
  return getSharedClipPlayer().play(
    [getNumberRowShowInstructionAudioAsset()],
    playbackRate: kNumberRowShowInstructionPlaybackRate,
  );
}

Future<void> playNumberRowDigitAudio(int digit) {
  return getSharedClipPlayer().play(
    ['audio/ru/mental-arithmetic/numbers/$digit.mp3'],
  );
}

Future<void> cancelNumberRowShowAudio() {
  return getSharedClipPlayer().cancel();
}
