/// Web: `platform/src/trainers/mental-arithmetic/audio/play-step-audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

Future<void> playStepAudio(
  ChainStep step, {
  double playbackRate = 1,
}) {
  final resolved = resolveStepAudio(step);
  return getSharedClipPlayer().play(
    resolved.assets,
    playbackRate: playbackRate,
  );
}

Future<void> cancelStepAudio() {
  return getSharedClipPlayer().cancel();
}
