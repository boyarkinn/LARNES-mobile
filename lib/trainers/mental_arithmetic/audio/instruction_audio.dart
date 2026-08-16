/// Web: `platform/src/trainers/mental-arithmetic/audio/instruction-audio.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';

const kSolveModes = ['abacus', 'mental'];
const kSolveModeDefault = 'abacus';

/// Темп стартовой инструкции (шаги flash остаются на своей формуле).
const kInstructionPlaybackRate = 1.5;

/// Если озвучка шагов выключена (короткая пауза) — только текст.
const kInstructionSilentMs = 1800;

bool isSolveMode(Object? value) => value == 'abacus' || value == 'mental';

String normalizeSolveMode(Object? value) =>
    value == 'mental' ? 'mental' : 'abacus';

String solveModeInstructionLabel(String mode) =>
    mode == 'mental' ? 'Решай в уме!' : 'Решай на абакусе!';

String getInstructionAudioAsset(String mode) {
  final file = mode == 'mental' ? 'mental.mp3' : 'abacus.mp3';
  return '$kMentalAudioAssetBase/instructions/$file';
}
