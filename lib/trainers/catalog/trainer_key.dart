/// Все зарегистрированные trainerKey (паритет с web registry).
enum TrainerKey {
  abacusShow('abacus-show'),
  appleCountShow('apple-count-show'),
  digitFindTap('digit-find-tap'),
  digitTrace('digit-trace'),
  dotsDigitAbacus('dots-digit-abacus'),
  flashcardDigitMatch('flashcard-digit-match'),
  fruitCountTap('fruit-count-tap'),
  numberComposition('number-composition'),
  numberRowShow('number-row-show'),
  shopPay('shop-pay');

  const TrainerKey(this.apiValue);

  final String apiValue;

  static TrainerKey? tryParse(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final key in TrainerKey.values) {
      if (key.apiValue == value) {
        return key;
      }
    }
    return null;
  }

  static bool isRegistered(String value) => tryParse(value) != null;
}
