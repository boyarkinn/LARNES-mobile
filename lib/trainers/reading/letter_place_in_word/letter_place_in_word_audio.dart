import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kLetterPlaceInWordInstructionPlaybackRate = 1.5;
const kLetterPlaceInWordInstructionDurationFallbackMs = 2400;
const kLetterPlaceInWordInstructionText = 'Поставь пропущенную букву на место';

String getLetterPlaceInWordInstructionAudioAsset() => '';

Future<void> playLetterPlaceInWordInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:letter-place-in-word',
    legacyRate: kLetterPlaceInWordInstructionPlaybackRate,
  );
}

Future<void> cancelLetterPlaceInWordAudio() {
  return getSharedClipPlayer().cancel();
}
