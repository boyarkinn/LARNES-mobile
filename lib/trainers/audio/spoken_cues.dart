// Дополнительные фразы старого каталога. Совпадает с web spoken-cues.ts.

import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const _cueKeys = {
  'instruction:reading-diagnostics:intro',
  'instruction:reading-diagnostics:letters',
  'instruction:reading-diagnostics:closed-syllables',
  'instruction:reading-diagnostics:open-syllables',
  'instruction:reading-diagnostics:words',
  'instruction:reading-diagnostics:text',
  'instruction:example-visualization:solve',
  'instruction:dots-digit-abacus:task',
  'instruction:solve-mode:abacus',
  'instruction:solve-mode:mental',
  'explanation:dots-digit-abacus:equals',
  'explanation:dots-digit-abacus:abacus',
  'explanation:fly-track:up',
  'explanation:fly-track:down',
  'explanation:fly-track:left',
  'explanation:fly-track:right',
  'explanation:fly-track:by-1',
  'explanation:fly-track:by-2',
  'explanation:fly-track:by-3',
  'explanation:fly-track:by-4',
  'explanation:fly-track:moved',
  'feedback:fly-track:tap',
};

bool isSpokenCueAudioKey(String semanticKey) => _cueKeys.contains(semanticKey);

String? spokenCueAsset(String semanticKey) =>
    speechAudioFile(semanticKey)?.path;

Future<void> playSpokenCue({
  required String semanticKey,
  double legacyRate = 1,
  int fallbackMs = 3000,
}) async {
  final file = speechAudioFile(semanticKey);

  if (file == null) {
    if (semanticKey.startsWith('instruction:'))
      await getSharedClipPlayer().waitForFallback(
        Duration(milliseconds: fallbackMs),
      );
    return;
  }

  final elapsed = Stopwatch()..start();
  final player = getSharedClipPlayer();
  final runId = player.generation + 1; // play cancels the previous run first.
  await player.play([file.path], playbackRate: 1);
  // A failed player must not make the visible instruction disappear immediately.
  if (player.generation == runId &&
      semanticKey.startsWith('instruction:') &&
      elapsed.elapsedMilliseconds < file.durationMs) {
    await player.waitForFallback(
      Duration(milliseconds: file.durationMs - elapsed.elapsedMilliseconds),
    );
  }
}
