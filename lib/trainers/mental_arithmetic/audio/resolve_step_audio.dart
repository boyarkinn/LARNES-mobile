/// Web: `platform/src/trainers/mental-arithmetic/audio/resolve-step-audio.ts`
///
/// Пути — Flutter [AssetSource] без префикса `assets/`
/// (файлы в `assets/audio/ru/mental-arithmetic/...`).

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

const kMentalAudioAssetBase = 'audio/ru/mental-arithmetic';

class StepAudioResolution {
  const StepAudioResolution({
    required this.operationAsset,
    required this.amountAsset,
    required this.assets,
  });

  final String operationAsset;
  final String? amountAsset;

  /// Очередь: знак, затем число (если есть).
  final List<String> assets;
}

String getOperationAudioAsset(String sign) {
  final file = sign == '+' ? 'plus.mp3' : 'minus.mp3';
  return '$kMentalAudioAssetBase/operations/$file';
}

/// 0…99 → numbers; круглые 100…900 → hundreds; иначе null.
String? getAmountAudioAsset(int amount) {
  if (amount < 0) {
    return null;
  }

  if (amount <= 99) {
    return '$kMentalAudioAssetBase/numbers/$amount.mp3';
  }

  if (amount <= 900 && amount % 100 == 0) {
    return '$kMentalAudioAssetBase/hundreds/$amount.mp3';
  }

  return null;
}

StepAudioResolution resolveStepAudio(ChainStep step) {
  final operationAsset = getOperationAudioAsset(step.sign);
  final amountAsset = getAmountAudioAsset(step.amount);
  final assets = amountAsset == null
      ? <String>[operationAsset]
      : <String>[operationAsset, amountAsset];

  return StepAudioResolution(
    operationAsset: operationAsset,
    amountAsset: amountAsset,
    assets: assets,
  );
}
