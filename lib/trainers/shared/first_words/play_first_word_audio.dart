/// Web: `platform/src/trainers/shared/first-words/play-first-word-audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/shared/first_words/resolve_first_word.dart';

Future<bool> playFirstWordAudio(String slug) async {
  final assetPath = getFirstWordAudioAsset(slug);
  if (assetPath == null) {
    return false;
  }

  await getSharedClipPlayer().play(
    [assetPath],
    playbackRate: firstWordAudioPlaybackRate,
  );
  return true;
}

Future<void> cancelFirstWordAudio() {
  return getSharedClipPlayer().cancel();
}
