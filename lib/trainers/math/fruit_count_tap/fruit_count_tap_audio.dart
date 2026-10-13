/// Web: `platform/src/trainers/math/fruit-count-tap/audio.ts`

import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_model.dart';

const kFruitCountTapInstructionPlaybackRate = 1.5;
const kFruitCountTapInstructionDurationFallbackMs = 1712;

const kFruitCountTapInstructionText = 'Посчитай сколько на экране';

String get fruitCountTapInstructionText => kFruitCountTapInstructionText;

String getFruitCountTapInstructionAudioAsset() =>
    spokenCueAsset('instruction:fruit-count-tap') ?? '';

String getFruitCountTapTargetAudioAsset(String fruit) {
  return speechPlaybackPath(fruitAudioKey(normalizeFruitSlug(fruit))) ?? '';
}

Future<void> playFruitCountTapInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:fruit-count-tap',
    legacyRate: kFruitCountTapInstructionPlaybackRate,
  );
}

Future<void> playFruitCountTapTargetFruit(String fruit) {
  final path = speechPlaybackPath(fruitAudioKey(normalizeFruitSlug(fruit)));

  if (path == null) {
    return Future<void>.value();
  }

  return getSharedClipPlayer().play([path]);
}

Future<void> cancelFruitCountTapAudio() {
  return getSharedClipPlayer().cancel();
}
