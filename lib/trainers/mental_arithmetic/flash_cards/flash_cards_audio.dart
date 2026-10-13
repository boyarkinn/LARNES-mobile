/// Web: `platform/src/trainers/mental-arithmetic/flash-cards/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kFlashCardsInstructionPlaybackRate = 1.5;
const kFlashCardsInstructionDurationFallbackMs = 3392;
const kFlashCardsInstructionText =
    'Выбери число, которому соответствует эта флеш-карта';
const kFlashCardsActiveBeadColor = 0xFF22C55E;

String getFlashCardsInstructionAudioAsset() => '';

Future<void> playFlashCardsInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:flash-cards',
    legacyRate: kFlashCardsInstructionPlaybackRate,
  );
}

Future<void> cancelFlashCardsAudio() {
  return getSharedClipPlayer().cancel();
}
