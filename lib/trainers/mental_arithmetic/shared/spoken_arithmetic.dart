import 'package:larnes_mobile/trainers/audio/number_bank.dart';

const arithmeticAndKey = 'explanation:arithmetic:and';
String spokenArithmeticKey(String key) => 'explanation:arithmetic:$key';

List<String> spokenArithmeticAmountKeys(int amount, [String locale = 'ru-RU']) {
  if (amount < 0 || amount > 999) return const [];
  String numberKey(int value) => spokenArithmeticKey(
    value >= 100 ? 'number:hundreds:$value' : 'number:$value',
  );
  if (amount < 20 || amount % 100 == 0 || amount < 100 && amount % 10 == 0) {
    return [numberKey(amount)];
  }
  final arabic = locale.startsWith('ar');
  if (amount >= 100) {
    return [
      numberKey(amount ~/ 100 * 100),
      if (arabic) arithmeticAndKey,
      ...spokenArithmeticAmountKeys(amount % 100, locale),
    ];
  }
  final tens = numberKey(amount ~/ 10 * 10), units = numberKey(amount % 10);
  return arabic ? [units, arithmeticAndKey, tens] : [tens, units];
}

List<String> spokenArithmeticStepKeys({
  required int amount,
  required String sign,
  String locale = 'ru-RU',
}) => [
  spokenArithmeticKey(operationAudioKey(sign)),
  ...spokenArithmeticAmountKeys(amount, locale),
];
