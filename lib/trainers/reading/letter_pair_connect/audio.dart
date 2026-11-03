import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const letterPairInstructionKey = 'instruction:letter-pair-connect';
const letterPairInstructionText = 'Соедини одинаковые буквы друг с другом';
const letterPairInstructionFallbackMs = 4000;
const letterPairInstructionPauseMs = 1000;

Future<void> playLetterPairInstruction() => playSpokenCue(
  semanticKey: letterPairInstructionKey,
  fallbackMs: letterPairInstructionFallbackMs,
);

Future<void> cancelLetterPairAudio() => getSharedClipPlayer().cancel();
