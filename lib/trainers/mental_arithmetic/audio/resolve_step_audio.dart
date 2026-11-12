// Web: `platform/src/trainers/mental-arithmetic/audio/resolve-step-audio.ts`
// Published catalog clips in the pinned number-bank language.

import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

class StepAudioResolution {
  const StepAudioResolution({
    required this.operationAsset,
    required this.amountAssets,
    required this.assets,
  });

  final String operationAsset;

  /// Language-specific fragments of the number, in pronunciation order.
  final List<String> amountAssets;

  /// Очередь: знак, затем число.
  final List<String> assets;
}

String getOperationAudioAsset(String sign) {
  return numberAudioFileForKey(operationAudioKey(sign))?.path ?? '';
}

/// Uses the shared bank and the language of the pinned number clips.
/// Если хотя бы одного файла нет, число не произносится наполовину.
List<String> getAmountAudioAssets(int amount) {
  final paths = <String>[];

  for (final key in amountAudioKeys(amount, numberAudioLocale)) {
    final path = numberAudioFileForKey(key)?.path;
    if (path == null || path.isEmpty) {
      return [];
    }
    paths.add(path);
  }

  return paths;
}

/// Один клип, если операнд целиком в одном файле; иначе null.
String? getAmountAudioAsset(int amount) {
  final paths = getAmountAudioAssets(amount);
  return paths.length == 1 ? paths.first : null;
}

StepAudioResolution resolveStepAudio(ChainStep step) {
  final operationAsset = getOperationAudioAsset(step.sign);
  final amountAssets = getAmountAudioAssets(step.amount);

  return StepAudioResolution(
    operationAsset: operationAsset,
    amountAssets: amountAssets,
    assets: [
      operationAsset,
      ...amountAssets,
    ].where((path) => path.isNotEmpty).toList(),
  );
}
