/// Web: `platform/src/trainers/math/digit-find-tap/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_model.dart';

const kDigitFindTapAudioAssetBase = 'audio/ru/math/digit-find-tap';
const kDigitFindTapInstructionPlaybackRate = 1.5;
const kDigitFindTapInstructionDurationFallbackMs = 1120;

const kDigitFindTapInstructionText = 'Найди цифру';

String get digitFindTapInstructionText => kDigitFindTapInstructionText;

String getDigitFindTapInstructionAudioAsset() =>
    '$kDigitFindTapAudioAssetBase/instruction.mp3';

Future<void> playDigitFindTapInstruction() {
  return getSharedClipPlayer().play(
    [getDigitFindTapInstructionAudioAsset()],
    playbackRate: kDigitFindTapInstructionPlaybackRate,
  );
}

Future<void> playDigitFindTapTargetDigit(int digit) {
  final asset = getAmountAudioAsset(normalizeTargetDigit(digit));
  if (asset == null) {
    return Future<void>.value();
  }

  return getSharedClipPlayer().play(
    [asset],
    playbackRate: kDigitFindTapInstructionPlaybackRate,
  );
}

Future<void> cancelDigitFindTapAudio() {
  return getSharedClipPlayer().cancel();
}
