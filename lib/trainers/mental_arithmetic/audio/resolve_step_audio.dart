/// Web: `platform/src/trainers/mental-arithmetic/audio/resolve-step-audio.ts`
///
/// Пути — Flutter [AssetSource] без префикса `assets/`
/// (файлы в `assets/audio/ru/mental-arithmetic/...`).

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
  return '$kMentalAudioAssetBase/operations/$file';
}

/// 0…99 → numbers; круглые / составные 100…999 → hundreds [+ numbers].
List<String> getAmountAudioAssets(int amount) {
  if (amount < 0 || amount > 999) {
    return const [];
  }

  if (amount <= 99) {
    return ['$kMentalAudioAssetBase/numbers/$amount.mp3'];
  }

  final hundreds = (amount ~/ 100) * 100;
  final rest = amount % 100;
  final paths = <String>['$kMentalAudioAssetBase/hundreds/$hundreds.mp3'];

  if (rest > 0) {
    paths.add('$kMentalAudioAssetBase/numbers/$rest.mp3');
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
    assets: [operationAsset, ...amountAssets],
  );
}
