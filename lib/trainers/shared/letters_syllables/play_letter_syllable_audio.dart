/// Web: `platform/src/trainers/shared/letters-syllables/play-letter-syllable-audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/shared/letters_syllables/resolve_letter_syllable_audio.dart';

Future<bool> playLetterSyllableAudio(String token) async {
  final assetPath = getLetterSyllableAudioAsset(token);
  if (assetPath == null) {
    return false;
  }

  await getSharedClipPlayer().play(
    [assetPath],
    playbackRate: lettersSyllablesPlaybackRate,
  );
  return true;
}

Future<void> cancelLetterSyllableAudio() {
  return getSharedClipPlayer().cancel();
}
