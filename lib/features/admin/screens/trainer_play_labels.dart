import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

String trainerPlayFieldLabel(AppLocalizations l10n, String labelKey) {
  switch (labelKey) {
    case 'letterCaseLabel':
      return l10n.adminTrainerPlayLetterCaseLabel;
    case 'wordCaseLabel':
      return l10n.adminTrainerPlayWordCaseLabel;
    case 'letterLabel':
      return l10n.adminTrainerPlayLetterLabel;
    case 'practiceLettersLabel':
      return l10n.adminTrainerPlayPracticeLettersLabel;
    case 'shopItemLabel':
      return l10n.adminTrainerPlayShopItemLabel;
    case 'priceLabel':
      return l10n.adminTrainerPlayPriceLabel;
    case 'coinCountLabel':
      return l10n.adminTrainerPlayCoinCountLabel;
    case 'wholeLabel':
      return l10n.adminTrainerPlayWholeLabel;
    case 'knownPartLabel':
      return l10n.adminTrainerPlayKnownPartLabel;
    case 'answerRangeStartLabel':
      return l10n.adminTrainerPlayAnswerRangeStartLabel;
    case 'targetFruitLabel':
      return l10n.adminTrainerPlayTargetFruitLabel;
    case 'fruitTargetCountLabel':
      return l10n.adminTrainerPlayFruitTargetCountLabel;
    case 'fruitTypeCountLabel':
      return l10n.adminTrainerPlayFruitTypeCountLabel;
    case 'totalFruitsLabel':
      return l10n.adminTrainerPlayTotalFruitsLabel;
    case 'digitLabel':
      return l10n.adminTrainerPlayDigitLabel;
    case 'targetCountLabel':
      return l10n.adminTrainerPlayTargetCountLabel;
    case 'distractorCountLabel':
      return l10n.adminTrainerPlayDistractorCountLabel;
    case 'missingSegmentLabel':
      return l10n.adminTrainerPlayMissingSegmentLabel;
    case 'letterCountLabel':
      return l10n.adminTrainerPlayLetterCountLabel;
    case 'oddLetterLabel':
      return l10n.adminTrainerPlayOddLetterLabel;
    case 'optionCountLabel':
      return l10n.adminTrainerPlayOptionCountLabel;
    case 'dotModeLabel':
      return l10n.adminTrainerPlayDotModeLabel;
    case 'roundsLabel':
      return l10n.adminTrainerPlayRoundsLabel;
    case 'displaySecondsLabel':
      return l10n.adminTrainerPlayDisplaySecondsLabel;
    case 'stroopDisplaySecondsLabel':
      return l10n.adminTrainerPlayStroopDisplaySecondsLabel;
    case 'wordCountLabel':
      return l10n.adminTrainerPlayWordCountLabel;
    case 'schulteGridSizeLabel':
      return l10n.adminTrainerPlaySchulteGridSizeLabel;
    case 'schulteCategoryLabel':
      return l10n.adminTrainerPlaySchulteCategoryLabel;
    case 'schulteOrderLabel':
      return l10n.adminTrainerPlaySchulteOrderLabel;
    case 'schulteOrientationLabel':
      return l10n.adminTrainerPlaySchulteOrientationLabel;
    case 'schulteCenterDotLabel':
      return l10n.adminTrainerPlaySchulteCenterDotLabel;
    case 'schulteShowFoundLabel':
      return l10n.adminTrainerPlaySchulteShowFoundLabel;
    case 'gridSizeLabel':
      return l10n.adminTrainerPlayGridSizeLabel;
    case 'flyGridSizeLabel':
      return l10n.adminTrainerPlayGridSizeLabel;
    case 'stepCountLabel':
      return l10n.adminTrainerPlayStepCountLabel;
    case 'filledCountLabel':
      return l10n.adminTrainerPlayFilledCountLabel;
    case 'wordSlugLabel':
      return l10n.adminTrainerPlayWordSlugLabel;
    case 'entityCountLabel':
      return l10n.adminTrainerPlayEntityCountLabel;
    case 'pairCountLabel':
      return l10n.adminTrainerPlayPairCountLabel;
    case 'catchCountLabel':
      return l10n.adminTrainerPlayCatchCountLabel;
    case 'speedLabel':
      return l10n.adminTrainerPlaySpeedLabel;
    case 'wordItemCountLabel':
      return l10n.adminTrainerPlayWordItemCountLabel;
    case 'totalRodsLabel':
      return l10n.adminTrainerPlayTotalRodsLabel;
    case 'stepPauseSecLabel':
      return l10n.adminTrainerPlayStepPauseSecLabel;
    case 'exampleStringLabel':
      return l10n.adminTrainerPlayExampleStringLabel;
    case 'chainTopicIdLabel':
      return l10n.adminTrainerPlayChainTopicIdLabel;
    case 'solveModeLabel':
      return l10n.adminTrainerPlaySolveModeLabel;
    case 'actionCountLabel':
      return l10n.adminTrainerPlayActionCountLabel;
    case 'exampleCountLabel':
      return l10n.adminTrainerPlayExampleCountLabel;
    case 'signModeLabel':
      return l10n.adminTrainerPlaySignModeLabel;
    case 'amountScopeLabel':
      return l10n.adminTrainerPlayAmountScopeLabel;
    case 'valueLabel':
      return l10n.adminTrainerPlayValueLabel;
    case 'flashValuesLabel':
      return l10n.adminTrainerPlayFlashValuesLabel;
    case 'matchValue1Label':
      return l10n.adminTrainerPlayMatchValue1Label;
    case 'matchValue2Label':
      return l10n.adminTrainerPlayMatchValue2Label;
    case 'matchValue3Label':
      return l10n.adminTrainerPlayMatchValue3Label;
    case 'matchValue4Label':
      return l10n.adminTrainerPlayMatchValue4Label;
    case 'targetModeLabel':
      return l10n.adminTrainerPlayTargetModeLabel;
    case 'vanishSourceLabel':
      return _passageLabel(l10n, ru: 'Откуда текст', en: 'Text source', ar: 'مصدر النص');
    case 'vanishPassageLabel':
      return _passageLabel(l10n, ru: 'Текст', en: 'Text', ar: 'النص');
    case 'vanishCustomTextLabel':
      return _passageLabel(l10n, ru: 'Свой текст', en: 'My own text', ar: 'نصي');
    case 'vanishPauseLabel':
      return _passageLabel(l10n, ru: 'Пауза на букву, мс', en: 'Pause per letter, ms', ar: 'وقفة لكل حرف، مللي ثانية');
    case 'shutterEdgeLabel':
      return _passageLabel(l10n, ru: 'Край шторки', en: 'Shutter edge', ar: 'طرف الستارة');
    case 'shutterCoverLabel':
      return _passageLabel(l10n, ru: 'Сколько закрыто', en: 'How much is covered', ar: 'مقدار التغطية');
    case 'paceTrackLabel':
      return _passageLabel(l10n, ru: 'Дорожка', en: 'Track', ar: 'المسار');
    case 'noiseLabel':
      return _passageLabel(l10n, ru: 'Помеха', en: 'Noise', ar: 'التشويش');
    case 'blocksWordsLabel':
      return _passageLabel(l10n, ru: 'Слов в строке', en: 'Words per line', ar: 'كلمات في السطر');
    case 'flashKindLabel':
      return _passageLabel(l10n, ru: 'Что показываем', en: 'What to show', ar: 'ماذا نعرض');
    case 'flashDurationLabel':
      return _passageLabel(l10n, ru: 'Длительность, мс', en: 'Duration, ms', ar: 'المدة، مللي ثانية');
    case 'flashShowsLabel':
      return _passageLabel(l10n, ru: 'Число показов', en: 'Number of flashes', ar: 'عدد الومضات');
    case 'fixationFragmentLabel':
      return _passageLabel(l10n, ru: 'Вид фрагмента', en: 'Fragment', ar: 'نوع الجزء');
    case 'fixationPauseLabel':
      return _passageLabel(l10n, ru: 'Пауза, мс', en: 'Pause, ms', ar: 'الوقفة، مللي ثانية');
    case 'echoSpanLabel':
      return _passageLabel(l10n, ru: 'Предложений во фрагменте', en: 'Sentences in the fragment', ar: 'عدد الجمل في المقطع');
    case 'echoPauseLabel':
      return _passageLabel(l10n, ru: 'Пауза на повтор, мс', en: 'Repeat pause, ms', ar: 'وقفة التكرار، مللي ثانية');
    case 'echoHighlightLabel':
      return _passageLabel(l10n, ru: 'Подсветка', en: 'Highlight', ar: 'التظليل');
    case 'echoRepeatLabel':
      return _passageLabel(l10n, ru: 'Повтор', en: 'Repeat', ar: 'التكرار');
    case 'phraseModeLabel':
      return _passageLabel(l10n, ru: 'Режим', en: 'Mode', ar: 'الوضع');
    case 'findModeLabel':
      return _passageLabel(l10n, ru: 'Режим', en: 'Mode', ar: 'الوضع');
    case 'clozeModeLabel':
      return _passageLabel(l10n, ru: 'Режим', en: 'Mode', ar: 'الوضع');
    case 'storyCardsLabel':
      return _passageLabel(l10n, ru: 'Сколько предложений', en: 'How many sentences', ar: 'عدد الجمل');
    case 'anagramWordLabel':
      return _passageLabel(l10n, ru: 'Слово', en: 'Word', ar: 'الكلمة');
    case 'anagramHintLabel':
      return _passageLabel(l10n, ru: 'Подсказка', en: 'Hint', ar: 'تلميح');
    case 'anagramPicture':
      return _passageLabel(l10n, ru: 'Картинка', en: 'Picture', ar: 'صورة');
    case 'anagramDefinition':
      return _passageLabel(l10n, ru: 'Определение', en: 'Definition', ar: 'تعريف');
    case 'anagramSentence':
      return _passageLabel(l10n, ru: 'Предложение', en: 'Sentence', ar: 'جملة');
    case 'mazeModeLabel':
      return _passageLabel(l10n, ru: 'Правило', en: 'Rule', ar: 'القاعدة');
    case 'mazeGroup':
      return _passageLabel(l10n, ru: 'Животные', en: 'Animals', ar: 'حيوانات');
    case 'mazeSentence':
      return _passageLabel(l10n, ru: 'Предложение', en: 'Sentence', ar: 'جملة');
    case 'gridStepLabel':
      return _passageLabel(l10n, ru: 'Шаг сетки', en: 'Grid step', ar: 'خطوة الشبكة');
    case 'gridStepFine':
      return _passageLabel(l10n, ru: 'Мелкий', en: 'Fine', ar: 'ناعم');
    case 'gridStepMedium':
      return _passageLabel(l10n, ru: 'Средний', en: 'Medium', ar: 'متوسط');
    case 'gridStepWide':
      return _passageLabel(l10n, ru: 'Крупный', en: 'Wide', ar: 'واسع');
    case 'linePaceLabel':
      return _passageLabel(l10n, ru: 'Время на строку, мс', en: 'Time per line, ms', ar: 'وقت السطر، مللي ثانية');
    case 'lineKeepLabel':
      return _passageLabel(l10n, ru: 'Прошлые строки', en: 'Earlier lines', ar: 'الأسطر السابقة');
    case 'lineKeepKeep':
      return _passageLabel(l10n, ru: 'Оставлять', en: 'Keep', ar: 'تبقى');
    case 'lineKeepDrop':
      return _passageLabel(l10n, ru: 'Убирать', en: 'Remove', ar: 'تختفي');
    default:
      return labelKey;
  }
}

String _passageLabel(
  AppLocalizations l10n, {
  required String ru,
  required String en,
  required String ar,
}) {
  final code = l10n.localeName;
  if (code.startsWith('en')) return en;
  if (code.startsWith('ar')) return ar;
  return ru;
}

String trainerPlayOptionLabel(AppLocalizations l10n, TrainerPlayFieldOption option) {
  if (option.label != null && option.label!.isNotEmpty) {
    return option.label!;
  }

  switch (option.labelKey) {
    case 'letterCaseUpper':
      return l10n.adminTrainerPlayLetterCaseUpper;
    case 'letterCaseLower':
      return l10n.adminTrainerPlayLetterCaseLower;
    case 'missingSegmentRandom':
      return l10n.adminTrainerPlayMissingSegmentRandom;
    case 'missingSegmentIndex1':
      return l10n.adminTrainerPlayMissingSegmentIndex1;
    case 'missingSegmentIndex2':
      return l10n.adminTrainerPlayMissingSegmentIndex2;
    case 'missingSegmentIndex3':
      return l10n.adminTrainerPlayMissingSegmentIndex3;
    case 'missingSegmentIndex4':
      return l10n.adminTrainerPlayMissingSegmentIndex4;
    case 'dotModeNumbered':
      return l10n.adminTrainerPlayDotModeNumbered;
    case 'dotModeFree':
      return l10n.adminTrainerPlayDotModeFree;
    case 'speedSlow':
      return l10n.adminTrainerPlaySpeedSlow;
    case 'speedMedium':
      return l10n.adminTrainerPlaySpeedMedium;
    case 'speedFast':
      return l10n.adminTrainerPlaySpeedFast;
    case 'solveModeAbacus':
      return l10n.adminTrainerPlaySolveModeAbacus;
    case 'solveModeMental':
      return l10n.adminTrainerPlaySolveModeMental;
    case 'targetModeDigits':
      return l10n.adminTrainerPlayTargetModeDigits;
    case 'targetModeDots':
      return l10n.adminTrainerPlayTargetModeDots;
    case 'schulteCategoryDigits':
      return l10n.adminTrainerPlaySchulteCategoryDigits;
    case 'schulteCategoryLetters':
      return l10n.adminTrainerPlaySchulteCategoryLetters;
    case 'schulteOrderForward':
      return l10n.adminTrainerPlaySchulteOrderForward;
    case 'schulteOrderBackward':
      return l10n.adminTrainerPlaySchulteOrderBackward;
    case 'schulteOrientationNormal':
      return l10n.adminTrainerPlaySchulteOrientationNormal;
    case 'schulteOrientationUpsideDown':
      return l10n.adminTrainerPlaySchulteOrientationUpsideDown;
    case 'schulteToggleNo':
      return l10n.adminTrainerPlaySchulteToggleNo;
    case 'schulteToggleYes':
      return l10n.adminTrainerPlaySchulteToggleYes;
    case 'vanishSourceBank':
      return _passageLabel(l10n, ru: 'Из банка', en: 'From the bank', ar: 'من المجموعة');
    case 'vanishSourceCustom':
      return _passageLabel(l10n, ru: 'Свой текст', en: 'My own text', ar: 'نصي');
    case 'shutterTop':
      return _passageLabel(l10n, ru: 'Сверху', en: 'From the top', ar: 'من الأعلى');
    case 'shutterBottom':
      return _passageLabel(l10n, ru: 'Снизу', en: 'From the bottom', ar: 'من الأسفل');
    case 'shutterQuarter':
      return _passageLabel(l10n, ru: 'Четверть', en: 'A quarter', ar: 'الربع');
    case 'shutterHalf':
      return _passageLabel(l10n, ru: 'Половина', en: 'Half', ar: 'النصف');
    case 'paceMetronome':
      return _passageLabel(l10n, ru: 'Метроном', en: 'Metronome', ar: 'المترونوم');
    case 'paceZhinkin':
      return _passageLabel(l10n, ru: 'Ритм Жинкина', en: 'Zhinkin rhythm', ar: 'إيقاع جينكين');
    case 'paceRhythmic':
      return _passageLabel(l10n, ru: 'Ритмическое чтение', en: 'Rhythmic reading', ar: 'القراءة الإيقاعية');
    case 'paceCountdown':
      return _passageLabel(l10n, ru: 'Обратный счет', en: 'Countdown', ar: 'العد العكسي');
    case 'noiseStrokes':
      return _passageLabel(l10n, ru: 'Штрихи', en: 'Strokes', ar: 'خطوط');
    case 'noiseExtraLetters':
      return _passageLabel(l10n, ru: 'Лишние буквы', en: 'Extra letters', ar: 'حروف زائدة');
    case 'noiseExtraWords':
      return _passageLabel(l10n, ru: 'Лишние слова', en: 'Extra words', ar: 'كلمات زائدة');
    case 'noiseZigzag':
      return _passageLabel(l10n, ru: 'Зигзаг', en: 'Zigzag', ar: 'متعرج');
    case 'noiseCircle':
      return _passageLabel(l10n, ru: 'По кругу', en: 'In a circle', ar: 'على دائرة');
    case 'noiseWave':
      return _passageLabel(l10n, ru: 'Волна', en: 'Wave', ar: 'موجة');
    case 'noiseFlip':
      return _passageLabel(l10n, ru: 'То прямо, то вверх ногами', en: 'Upright, then upside down', ar: 'مستقيم ثم مقلوب');
    case 'flashLetters':
      return _passageLabel(l10n, ru: 'Несколько букв', en: 'Several letters', ar: 'عدة حروف');
    case 'flashLine':
      return _passageLabel(l10n, ru: 'Короткая строка', en: 'Short line', ar: 'سطر قصير');
    case 'fixationWord':
      return _passageLabel(l10n, ru: 'Слово', en: 'Word', ar: 'كلمة');
    case 'fixationPair':
      return _passageLabel(l10n, ru: 'Два слова', en: 'Two words', ar: 'كلمتان');
    case 'fixationSentence':
      return _passageLabel(l10n, ru: 'Предложение', en: 'Sentence', ar: 'جملة');
    case 'echoHighlightOn':
      return _passageLabel(l10n, ru: 'Включена', en: 'On', ar: 'مفعّلة');
    case 'echoHighlightOff':
      return _passageLabel(l10n, ru: 'Выключена', en: 'Off', ar: 'متوقفة');
    case 'echoRepeatOn':
      return _passageLabel(l10n, ru: 'Можно ещё раз', en: 'Again is allowed', ar: 'يمكن الإعادة');
    case 'echoRepeatOff':
      return _passageLabel(l10n, ru: 'Без кнопки', en: 'No button', ar: 'بدون زر');
    case 'phraseFade':
      return _passageLabel(l10n, ru: 'Границы гаснут', en: 'Boundaries fade', ar: 'تختفي الحدود');
    case 'phrasePlace':
      return _passageLabel(l10n, ru: 'Расставь границы', en: 'Place the boundaries', ar: 'ضع الحدود');
    case 'findWord':
      return _passageLabel(l10n, ru: 'Найди слово', en: 'Find the word', ar: 'ابحث عن الكلمة');
    case 'findAnswer':
      return _passageLabel(l10n, ru: 'Найди ответ', en: 'Find the answer', ar: 'ابحث عن الإجابة');
    case 'clozeSimple':
      return _passageLabel(l10n, ru: 'Просто', en: 'Simple', ar: 'بسيط');
    case 'clozeStory':
      return _passageLabel(l10n, ru: 'История', en: 'Story', ar: 'القصة');
    default:
      return option.value;
  }
}

bool trainerPlayFieldVisible(TrainerPlayConfig config, TrainerPlayField field, Map<String, String> values) {
  return field.isVisible(values);
}
