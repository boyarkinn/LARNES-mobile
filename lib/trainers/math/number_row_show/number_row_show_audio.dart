/// Web: `platform/src/trainers/math/number-row-show/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';

const kNumberRowShowInstructionPlaybackRate = 1.5;
const kNumberRowShowInstructionDurationFallbackMs = 2048;
const kNumberRowShowInstructionText = 'Собери числовой ряд';

String getNumberRowShowInstructionAudioAsset() =>
    spokenCueAsset('instruction:number-row-show') ?? '';

Future<void> playNumberRowShowInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:number-row-show',
    legacyRate: kNumberRowShowInstructionPlaybackRate,
  );
}

Future<void> playNumberRowDigitAudio(int digit) {
  final asset = getAmountAudioAsset(digit);
  if (asset == null) {
    return Future<void>.value();
  }

  return getSharedClipPlayer().play([asset]);
}

Future<void> cancelNumberRowShowAudio() {
  return getSharedClipPlayer().cancel();
}
