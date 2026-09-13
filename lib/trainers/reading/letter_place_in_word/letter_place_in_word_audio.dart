import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kLetterPlaceInWordAudioAssetBase =
    'audio/ru/reading/letter-place-in-word';
const kLetterPlaceInWordInstructionPlaybackRate = 1.5;
const kLetterPlaceInWordInstructionDurationFallbackMs = 2400;
const kLetterPlaceInWordInstructionText = 'Поставь пропущенную букву на место';

String getLetterPlaceInWordInstructionAudioAsset() =>
    '$kLetterPlaceInWordAudioAssetBase/instruction.mp3';

Future<void> playLetterPlaceInWordInstruction() {
  return getSharedClipPlayer().play([
    getLetterPlaceInWordInstructionAudioAsset(),
  ], playbackRate: kLetterPlaceInWordInstructionPlaybackRate);
}

Future<void> cancelLetterPlaceInWordAudio() {
  return getSharedClipPlayer().cancel();
}
