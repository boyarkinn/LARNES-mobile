/// Web: `platform/src/trainers/mental-arithmetic/audio/resolve-step-audio.ts`
///
/// Опубликованный файл каталога. Старый ассет приложения не подставляется.

import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

class StepAudioResolution {
  const StepAudioResolution({
    required this.operationAsset,
    required this.amountAssets,
    required this.assets,
  });

  final String operationAsset;

  /// Клипы числа: 0…1 или 2 (hundreds + numbers).
  final List<String> amountAssets;

  /// Очередь: знак, затем число.
  final List<String> assets;
}

String getOperationAudioAsset(String sign) {
  return numberAudioFileForKey(operationAudioKey(sign))?.path ?? '';
}

/// 0…99 → один файл; составные 101…999 — сотня и остаток.
/// Если хотя бы одного файла нет, число не произносится наполовину.
List<String> getAmountAudioAssets(int amount) {
  final paths = <String>[];

  for (final key in amountAudioKeys(amount)) {
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
    assets: [operationAsset, ...amountAssets].where((path) => path.isNotEmpty).toList(),
  );
}
