/// Web: `platform/src/trainers/shared/instruction/load-trainer-instruction-duration.ts`

import 'package:just_audio/just_audio.dart';

Future<int> loadTrainerInstructionDurationMs({
  required String assetPath,
  required double playbackRate,
  required int fallbackMs,
}) async {
  final player = AudioPlayer();
  try {
    await player.setAsset('assets/$assetPath');
    final duration = player.duration;
    if (duration != null && duration > Duration.zero) {
      return (duration.inMilliseconds / playbackRate).round();
    }
  } catch (_) {
    // Fall back when metadata is unavailable in tests or plugins.
  }

  try {
    await player.dispose();
  } catch (_) {}

  return fallbackMs;
}
