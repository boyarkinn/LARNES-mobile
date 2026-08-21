/// Все зарегистрированные trainerKey (паритет с web registry).
enum TrainerKey {
  abacusShow('abacus-show'),
  appleCountShow('apple-count-show'),
  digitFindTap('digit-find-tap'),
  digitTrace('digit-trace'),
  dotsDigitAbacus('dots-digit-abacus'),
  exampleVisualization('example-visualization'),
  flashcardDigitMatch('flashcard-digit-match'),
  fruitCountTap('fruit-count-tap'),
  letterBuild('letter-build'),
  letterCaseColor('letter-case-color'),
  letterCaseMatch('letter-case-match'),
  letterColor('letter-color'),
  letterComplete('letter-complete'),
  letterConnectDots('letter-connect-dots'),
  letterDrawShow('letter-draw-show'),
  letterFindBySound('letter-find-by-sound'),
  letterFindTap('letter-find-tap'),
  letterFirstByImage('letter-first-by-image'),
  letterGridMatch('letter-grid-match'),
  letterHalfDraw('letter-half-draw'),
  letterMarqueeTap('letter-marquee-tap'),
  letterNameAloud('letter-name-aloud'),
  stroopColors('stroop-colors'),
  schulteTable('schulte-table'),
  wedgeTables('wedge-tables'),
  letterOddOneOut('letter-odd-one-out'),
  letterOrientationPick('letter-orientation-pick'),
  letterPlaceInWord('letter-place-in-word'),
  letterTrace('letter-trace'),
  letterWordLink('letter-word-link'),
  numberComposition('number-composition'),
  numberRowShow('number-row-show'),
  shopPay('shop-pay'),
  staticExampleShow('static-example-show'),
  topicChainFlash('topic-chain-flash'),
  topicChainTable('topic-chain-table'),
  flyTrack('fly-track');

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
