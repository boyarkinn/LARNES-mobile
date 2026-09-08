/// Web: `platform/src/trainers/mental-arithmetic/flash-cards/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kFlashCardsAudioAssetBase = 'audio/ru/mental-arithmetic/flash-cards';
const kFlashCardsInstructionPlaybackRate = 1.5;
const kFlashCardsInstructionDurationFallbackMs = 3392;
const kFlashCardsInstructionText =
    'Напиши число, которому соответствует эта флеш-карта';
const kFlashCardsActiveBeadColor = 0xFF22C55E;

String getFlashCardsInstructionAudioAsset() =>
    '$kFlashCardsAudioAssetBase/instruction.mp3';

Future<void> playFlashCardsInstruction() {
  return getSharedClipPlayer().play(
    [getFlashCardsInstructionAudioAsset()],
    playbackRate: kFlashCardsInstructionPlaybackRate,
  );
}

Future<void> cancelFlashCardsAudio() {
  return getSharedClipPlayer().cancel();
}
