// Смысловые ключи числового банка. Совпадают с web `number-bank.ts`.

String operationAudioKey(String sign) =>
    sign == '+' ? 'operation:plus' : 'operation:minus';
const numberBankAndKey = 'number:and';
String _numberAudioLocale = 'ru-RU';
String get numberAudioLocale => _numberAudioLocale;

List<String> amountAudioKeys(int amount, [String locale = 'ru-RU']) {
  if (amount < 0 || amount > 999) {
    return const [];
  }

  if (!locale.startsWith('ru')) {
    String numberKey(int value) =>
        value >= 100 ? 'number:hundreds:$value' : 'number:$value';
    if (amount < 20 || amount < 100 && amount % 10 == 0 || amount % 100 == 0) {
      return [numberKey(amount)];
    }
    final arabic = locale.startsWith('ar');
    if (amount >= 100) {
      return [
        numberKey(amount ~/ 100 * 100),
        if (arabic) numberBankAndKey,
        ...amountAudioKeys(amount % 100, locale),
      ];
    }
    final tens = numberKey(amount ~/ 10 * 10), units = numberKey(amount % 10);
    return arabic ? [units, numberBankAndKey, tens] : [tens, units];
  }
  if (amount <= 99) {
    return ['number:$amount'];
  }

  final hundreds = (amount ~/ 100) * 100;
  final rest = amount % 100;
  final keys = <String>['number:hundreds:$hundreds'];

  if (rest > 0) {
    keys.add('number:$rest');
  }

  return keys;
}

List<String> stepAudioKeys({
  required int amount,
  required String sign,
  String locale = 'ru-RU',
}) {
  return [operationAudioKey(sign), ...amountAudioKeys(amount, locale)];
}

bool isNumberBankAudioKey(String semanticKey) {
  if (semanticKey == numberBankAndKey) return true;
  if (semanticKey == 'operation:plus' || semanticKey == 'operation:minus') {
    return true;
  }

  if (semanticKey.startsWith('number:hundreds:')) {
    final hundreds = int.tryParse(
      semanticKey.substring('number:hundreds:'.length),
    );
    return hundreds != null &&
        hundreds >= 100 &&
        hundreds <= 900 &&
        hundreds % 100 == 0;
  }

  if (semanticKey.startsWith('number:')) {
    final amount = int.tryParse(semanticKey.substring('number:'.length));
    return amount != null && amount >= 0 && amount <= 99;
  }

  return false;
}

class NumberAudioFile {
  const NumberAudioFile({required this.durationMs, required this.path});

  final int durationMs;
  final String path;
}

final Map<String, NumberAudioFile> _numberAudioFiles = {};

void setNumberAudioFiles(
  Map<String, NumberAudioFile> files, {
  String locale = 'ru-RU',
}) {
  _numberAudioLocale = locale;
  _numberAudioFiles
    ..clear()
    ..addAll(files);
}

NumberAudioFile? numberAudioFileForKey(String semanticKey) =>
    _numberAudioFiles[semanticKey];

double catalogFlashPlaybackRate(double stepPauseSec, List<int> durationMs) {
  final pauseMs = stepPauseSec * 1000;
  final totalMs = durationMs.fold<int>(
    0,
    (sum, item) => sum + (item > 0 ? item : 0),
  );

  if (!pauseMs.isFinite || pauseMs <= 0 || totalMs <= 0) {
    return 1;
  }

  if (totalMs <= pauseMs) {
    return 1;
  }

  final rate = totalMs / pauseMs;
  return rate > 4 ? 4 : rate;
}
