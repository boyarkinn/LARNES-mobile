/// Web: `platform/src/trainers/shared/instruction/load-trainer-instruction-duration.ts`

import 'package:just_audio/just_audio.dart';
import 'package:larnes_mobile/trainers/audio/legacy_audio_path.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';

Future<int> loadTrainerInstructionDurationMs({
  required String assetPath,
  required double playbackRate,
  required int fallbackMs,
  String? semanticKey,
}) async {
  if (semanticKey != null) {
    final file = speechAudioFile(semanticKey);

    if (file != null && file.durationMs > 0) {
      return file.durationMs;
    }

    if (speechCatalogHas(semanticKey)) {
      return fallbackMs;
    }
  }

  if (assetPath.isEmpty || isLegacyTrainerAudioPath(assetPath)) {
    return fallbackMs;
  }

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
