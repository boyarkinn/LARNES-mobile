/// Web: `platform/src/trainers/math/fruit-count-tap/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_model.dart';

const kFruitCountTapAudioAssetBase = 'audio/ru/math/fruit-count-tap';
const kFruitCountTapInstructionPlaybackRate = 1.5;
const kFruitCountTapInstructionDurationFallbackMs = 1712;

const kFruitCountTapInstructionText = 'Посчитай сколько на экране';

const _fruitTargetAudioAssets = <String, String>{
  'apple': '$kFruitCountTapAudioAssetBase/targets/apple.mp3',
  'banana': '$kFruitCountTapAudioAssetBase/targets/banana.mp3',
  'cherry': '$kFruitCountTapAudioAssetBase/targets/cherry.mp3',
  'grape': '$kFruitCountTapAudioAssetBase/targets/grape.mp3',
  'orange': '$kFruitCountTapAudioAssetBase/targets/orange.mp3',
  'peach': '$kFruitCountTapAudioAssetBase/targets/peach.mp3',
  'pear': '$kFruitCountTapAudioAssetBase/targets/pear.mp3',
  'plum': '$kFruitCountTapAudioAssetBase/targets/plum.mp3',
  'strawberry': '$kFruitCountTapAudioAssetBase/targets/strawberry.mp3',
  'watermelon': '$kFruitCountTapAudioAssetBase/targets/watermelon.mp3',
};

String get fruitCountTapInstructionText => kFruitCountTapInstructionText;

String getFruitCountTapInstructionAudioAsset() =>
    '$kFruitCountTapAudioAssetBase/instruction.mp3';

String getFruitCountTapTargetAudioAsset(String fruit) {
  final slug = normalizeFruitSlug(fruit);
  return _fruitTargetAudioAssets[slug] ??
      _fruitTargetAudioAssets['watermelon']!;
}

Future<void> playFruitCountTapInstruction() {
  return getSharedClipPlayer().play(
    [getFruitCountTapInstructionAudioAsset()],
    playbackRate: kFruitCountTapInstructionPlaybackRate,
  );
}

Future<void> playFruitCountTapTargetFruit(String fruit) {
  return getSharedClipPlayer().play(
    [getFruitCountTapTargetAudioAsset(fruit)],
    playbackRate: kFruitCountTapInstructionPlaybackRate,
  );
}

Future<void> cancelFruitCountTapAudio() {
  return getSharedClipPlayer().cancel();
}
