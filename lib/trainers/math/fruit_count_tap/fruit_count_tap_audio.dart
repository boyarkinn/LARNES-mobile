/// Web: `platform/src/trainers/math/fruit-count-tap/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kFruitCountTapAudioAssetBase = 'audio/ru/math/fruit-count-tap';
const kFruitCountTapInstructionPlaybackRate = 1.5;
const kFruitCountTapInstructionDurationFallbackMs = 2048;

const kFruitCountTapInstructionText = 'Посчитай фрукты';

String get fruitCountTapInstructionText => kFruitCountTapInstructionText;

String getFruitCountTapInstructionAudioAsset() =>
    '$kFruitCountTapAudioAssetBase/instruction.mp3';

Future<void> playFruitCountTapInstruction() {
  return getSharedClipPlayer().play(
    [getFruitCountTapInstructionAudioAsset()],
    playbackRate: kFruitCountTapInstructionPlaybackRate,
  );
}

Future<void> cancelFruitCountTapAudio() {
  return getSharedClipPlayer().cancel();
}
