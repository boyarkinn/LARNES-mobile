/// Web: `platform/src/trainers/mental-arithmetic/audio/resolve-step-audio.ts`
///
/// Пути — Flutter [AssetSource] без префикса `assets/`
/// (файлы в `assets/audio/ru/mental-arithmetic/...`).

import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

const kMentalAudioAssetBase = 'audio/ru/mental-arithmetic';

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
  final file = sign == '+' ? 'plus.mp3' : 'minus.mp3';
  return numberAudioFileForKey(operationAudioKey(sign))?.path ??
      '$kMentalAudioAssetBase/operations/$file';
}

/// 0…99 → numbers; круглые / составные 100…999 → hundreds [+ numbers].
/// Опубликованный файл того же ключа заменяет старый.
List<String> getAmountAudioAssets(int amount) {
  return [
    for (final key in amountAudioKeys(amount))
      numberAudioFileForKey(key)?.path ?? _legacyAmountAsset(key),
  ];
}

String _legacyAmountAsset(String semanticKey) {
  if (semanticKey.startsWith('number:hundreds:')) {
    return '$kMentalAudioAssetBase/hundreds/${semanticKey.substring('number:hundreds:'.length)}.mp3';
  }

  return '$kMentalAudioAssetBase/numbers/${semanticKey.substring('number:'.length)}.mp3';
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
    assets: [operationAsset, ...amountAssets],
  );
}
