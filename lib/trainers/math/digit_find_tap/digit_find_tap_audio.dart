/// Web: `platform/src/trainers/math/digit-find-tap/audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kDigitFindTapAudioAssetBase = 'audio/ru/math/digit-find-tap';
const kDigitFindTapInstructionPlaybackRate = 1.5;
const kDigitFindTapInstructionDurationFallbackMs = 2048;

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

Future<void> cancelDigitFindTapAudio() {
  return getSharedClipPlayer().cancel();
}
