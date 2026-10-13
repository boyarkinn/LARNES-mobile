/// Web: `platform/src/trainers/math/digit-find-tap/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_model.dart';

const kDigitFindTapInstructionPlaybackRate = 1.5;
const kDigitFindTapInstructionDurationFallbackMs = 1120;

const kDigitFindTapInstructionText = 'Найди цифру';

String get digitFindTapInstructionText => kDigitFindTapInstructionText;

String getDigitFindTapInstructionAudioAsset() => '';

Future<void> playDigitFindTapInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:digit-find-tap',
    legacyRate: kDigitFindTapInstructionPlaybackRate,
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
