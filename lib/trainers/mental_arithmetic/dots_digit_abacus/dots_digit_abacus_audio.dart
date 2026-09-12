// Web: `platform/src/trainers/mental-arithmetic/dots-digit-abacus/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_sizes.dart';

const kDotsDigitAbacusAudioAssetBase =
    'audio/ru/mental-arithmetic/dots-digit-abacus';
const kDotsDigitAbacusAudioPlaybackRate = 1.5;
const kDotsDigitAbacusInstructionDurationFallbackMs = 1968;
const kDotsDigitAbacusTaskInstructionDurationFallbackMs = 5568;
const kDotsDigitAbacusEqualsDigitDurationFallbackMs = 2000;
const kDotsDigitAbacusAbacusMatchDurationFallbackMs = 2272;
const kDotsDigitAbacusInstructionText = 'Считай точки вместе со мной!';
const kDotsDigitAbacusTaskInstructionText =
    'А теперь посчитай точки, соедини их с соответствующей цифрой, а цифру с абакусом';

String getDotsDigitAbacusInstructionAudioAsset() =>
    '$kDotsDigitAbacusAudioAssetBase/instruction.mp3';

String getDotsDigitAbacusTaskInstructionAudioAsset() =>
    '$kDotsDigitAbacusAudioAssetBase/task-instruction.mp3';

String getDotsDigitAbacusEqualsDigitAudioAsset() =>
    '$kDotsDigitAbacusAudioAssetBase/equals-digit.mp3';

String getDotsDigitAbacusAbacusMatchAudioAsset() =>
    '$kDotsDigitAbacusAudioAssetBase/abacus-match.mp3';

Future<void> playDotsDigitAbacusInstruction() {
  return getSharedClipPlayer().play([
    getDotsDigitAbacusInstructionAudioAsset(),
  ], playbackRate: kDotsDigitAbacusAudioPlaybackRate);
}

Future<void> playDotsDigitAbacusTaskInstruction() {
  return getSharedClipPlayer().play([
    getDotsDigitAbacusTaskInstructionAudioAsset(),
  ], playbackRate: kDotsDigitAbacusAudioPlaybackRate);
}

Future<void> playDotsDigitAbacusCountDigitAudio(int digit) {
  final asset = getAmountAudioAsset(digit);
  if (asset == null) {
    return Future<void>.delayed(const Duration(milliseconds: 500));
  }

  return getSharedClipPlayer().play([
    asset,
  ], playbackRate: kDotsDigitAbacusAudioPlaybackRate);
}

Future<void> playDotsDigitAbacusEqualsDigitBridge({
  void Function()? onStarted,
}) {
  return getSharedClipPlayer().play(
    [getDotsDigitAbacusEqualsDigitAudioAsset()],
    playbackRate: kDotsDigitAbacusAudioPlaybackRate,
    onStarted: onStarted,
  );
}

Future<void> playDotsDigitAbacusAbacusMatchBridge({
  void Function()? onStarted,
}) {
  return getSharedClipPlayer().play(
    [getDotsDigitAbacusAbacusMatchAudioAsset()],
    playbackRate: kDotsDigitAbacusAudioPlaybackRate,
    onStarted: onStarted,
  );
}

Future<void> cancelDotsDigitAbacusAudio() {
  return getSharedClipPlayer().cancel();
}

int get dotsDigitAbacusActiveBeadColor => kDotsDigitAbacusActiveBeadColor;

int get dotsDigitAbacusCountPauseMs => kDotsDigitAbacusCountPauseMs;

int get dotsDigitAbacusPulseMs => kDotsDigitAbacusPulseMs;

int get dotsDigitAbacusPulseCycleMs => kDotsDigitAbacusPulseCycleMs;
