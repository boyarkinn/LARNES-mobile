/// Web: `platform/src/trainers/mental-arithmetic/topic-chain-table/parse-step.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

final _stepPattern = RegExp(r'^\s*([+-])?\s*(\d{1,3})\s*$');

/// Свободная правка учителем: знак опционален (без знака → +).
ChainStep? parseEditableStep(String text) {
  final match = _stepPattern.firstMatch(text);
  if (match == null) {
    return null;
  }

  final amount = int.tryParse(match.group(2)!);
  if (amount == null || amount < 1 || amount > 999) {
    return null;
  }

  final sign = match.group(1) == '-' ? '-' : '+';
  return ChainStep(amount: amount, sign: sign);
}
