/// Web: `platform/src/trainers/math/digit-trace/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kDigitTraceAudioAssetBase = 'audio/ru/math/digit-trace';
const kDigitTraceInstructionPlaybackRate = 1.5;
const kDigitTraceInstructionDurationFallbackMs = 2048;

const kDigitTraceInstructionText = 'Обведи цифру';

String get digitTraceInstructionText => kDigitTraceInstructionText;

String getDigitTraceInstructionAudioAsset() =>
    '$kDigitTraceAudioAssetBase/instruction.mp3';

Future<void> playDigitTraceInstruction() {
  return getSharedClipPlayer().play(
    [getDigitTraceInstructionAudioAsset()],
    playbackRate: kDigitTraceInstructionPlaybackRate,
  );
}

Future<void> cancelDigitTraceAudio() {
  return getSharedClipPlayer().cancel();
}
