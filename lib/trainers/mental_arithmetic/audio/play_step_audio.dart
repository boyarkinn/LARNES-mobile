// Web: `platform/src/trainers/mental-arithmetic/audio/play-step-audio.ts`

import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/legacy_mental_duration.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

Future<void> playStepAudio(
  ChainStep step, {
  double playbackRate = 1,
  double? stepPauseSec,
  void Function()? onStarted,
}) {
  final resolved = resolveStepAudio(step);
  final durations = <int>[];
  var catalog = false;

  for (final key in stepAudioKeys(amount: step.amount, sign: step.sign)) {
    final file = numberAudioFileForKey(key);
    final legacy = legacyMentalDurationMs[key];

    if (file != null) {
      catalog = true;
      durations.add(file.durationMs);
    } else if (legacy != null) {
      durations.add(legacy);
    }
  }

  final rate = catalog
      ? catalogFlashPlaybackRate(stepPauseSec ?? 1, durations)
      : playbackRate;
  return getSharedClipPlayer().play(
    resolved.assets,
    playbackRate: rate,
    onStarted: onStarted,
  );
}

Future<void> cancelStepAudio() {
  return getSharedClipPlayer().cancel();
}
