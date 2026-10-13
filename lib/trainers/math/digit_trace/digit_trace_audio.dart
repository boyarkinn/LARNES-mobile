/// Web: `platform/src/trainers/math/digit-trace/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kDigitTraceInstructionPlaybackRate = 1.5;
const kDigitTraceInstructionDurationFallbackMs = 2048;

const kDigitTraceInstructionText = 'Обведи цифру';

String get digitTraceInstructionText => kDigitTraceInstructionText;

String getDigitTraceInstructionAudioAsset() => '';

Future<void> playDigitTraceInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:digit-trace',
    legacyRate: kDigitTraceInstructionPlaybackRate,
  );
}

Future<void> cancelDigitTraceAudio() {
  return getSharedClipPlayer().cancel();
}
