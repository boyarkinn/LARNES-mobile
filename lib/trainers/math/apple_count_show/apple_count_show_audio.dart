/// Web: `platform/src/trainers/math/apple-count-show/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';

const kAppleCountShowInstructionPlaybackRate = 1.5;
const kAppleCountShowInstructionDurationFallbackMs = 2048;
const kAppleCountShowInstructionText = 'Положи яблоки в корзину';

String getAppleCountShowInstructionAudioAsset() =>
    spokenCueAsset('instruction:apple-count-show') ?? '';

Future<void> playAppleCountShowInstruction() {
  return playSpokenCue(
    semanticKey: 'instruction:apple-count-show',
    legacyRate: kAppleCountShowInstructionPlaybackRate,
  );
}

Future<void> playAppleTargetCountAudio(int targetCount) {
  final asset = getAmountAudioAsset(targetCount);
  if (asset == null) {
    return Future<void>.value();
  }

  return getSharedClipPlayer().play([asset]);
}

Future<void> cancelAppleCountShowAudio() {
  return getSharedClipPlayer().cancel();
}
