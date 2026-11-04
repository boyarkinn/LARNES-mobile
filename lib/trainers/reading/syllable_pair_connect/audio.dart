import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const syllablePairInstructionKey = 'instruction:syllable-pair-connect';
const syllablePairInstructionText = 'Соедини одинаковые слоги друг с другом';
const syllablePairInstructionFallbackMs = 4000;
const syllablePairInstructionPauseMs = 1000;

Future<void> playSyllablePairInstruction() => playSpokenCue(
  semanticKey: syllablePairInstructionKey,
  fallbackMs: syllablePairInstructionFallbackMs,
);

Future<void> cancelSyllablePairAudio() => getSharedClipPlayer().cancel();
