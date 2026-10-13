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

String? spokenCueAsset(String semanticKey, String legacyAsset) {
  final file = speechAudioFile(semanticKey);

  if (file != null) {
    return file.path;
  }

  if (speechCatalogHas(semanticKey)) {
    return null;
  }

  return legacyAsset;
}

Future<void> playSpokenCue({
  required String semanticKey,
  required String legacyAsset,
  required double legacyRate,
}) {
  final file = speechAudioFile(semanticKey);

  if (file != null) {
    return getSharedClipPlayer().play([file.path], playbackRate: 1);
  }

  if (speechCatalogHas(semanticKey)) {
    return Future<void>.value();
  }

  return getSharedClipPlayer().play([legacyAsset], playbackRate: legacyRate);
}
